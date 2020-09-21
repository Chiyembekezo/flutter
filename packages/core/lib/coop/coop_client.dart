import 'dart:async';
import 'dart:typed_data';

import 'package:utilities/binary_buffer/binary_writer.dart';
import 'package:core/coop/change.dart';
import 'package:core/coop/player.dart';
import 'package:core/coop/player_cursor.dart';
import 'package:core/coop/protocol_version.dart';
import 'package:core/error_logger/error_logger.dart';
import 'package:core/web_socket/web_socket.dart';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'connect_result.dart';
import 'coop_reader.dart';
import 'coop_writer.dart';
import 'local_settings.dart';

typedef ChangeSetCallback = void Function(ChangeSet);
typedef WipeCallback = void Function();
typedef GetOfflineChangesCallback = Future<List<ChangeSet>> Function();
typedef HelloCallback = void Function(int);
typedef PlayersCallback = void Function(List<Player>);
typedef UpdateCursorCallback = void Function(int, PlayerCursor);
typedef ConnectionChangedCallback = void Function(CoopConnectionState);

enum CoopConnectionState { disconnected, connecting, handshaking, connected }

class CoopClient extends CoopReader {
  final String url;
  WebSocketChannel _channel;
  CoopWriter _writer;
  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;
  CoopConnectionState get connectionState => _connectionState;
  CoopConnectionState _connectionState = CoopConnectionState.disconnected;

  void _changeState(CoopConnectionState state) {
    if (_connectionState != state) {
      _connectionState = state;
      stateChanged?.call(state);
    }
  }

  int _reconnectAttempt = 0;
  Timer _reconnectTimer;
  Timer _pingTimer;
  final LocalSettings localSettings;
  final String fileId;
  int _clientId;
  int get clientId => _clientId;
  bool _allowReconnect = true;

  /// Authentication token, as used in the cookie
  final String _token;

  ChangeSetCallback changesAccepted;
  ChangeSetCallback changesRejected;
  ChangeSetCallback makeChanges;
  WipeCallback wipe;
  GetOfflineChangesCallback getOfflineChanges;
  HelloCallback gotClientId;
  PlayersCallback updatePlayers;
  UpdateCursorCallback updateCursor;
  ConnectionChangedCallback stateChanged;

  CoopClient(
    String host,
    String path, {
    this.fileId,
    this.localSettings,
    int clientId,
    String token,
  })  : url = '$host/v$protocolVersion/$path/$clientId',
        _token = token {
    _writer = CoopWriter(write);
  }

  void _reconnect() {
    _reconnectTimer?.cancel();

    _reconnectTimer =
        Timer(Duration(milliseconds: _reconnectAttempt * 8000), connect);
    if (_reconnectAttempt < 1) {
      _reconnectAttempt = 1;
    }
    _reconnectAttempt *= 2;
  }

  void dispose() {
    disconnect();
    _reconnectTimer?.cancel();

    _reconnectTimer = null;
  }

  bool get isConnected => _connectionState == CoopConnectionState.connected;

  void _ping() {
    if (!isConnected) {
      return;
    }
    _writer.writePing();
    _pingTimer?.cancel();
    _pingTimer = Timer(const Duration(seconds: 30), _ping);
  }

  Future<bool> disconnect() async {
    _allowReconnect = false;
    _pingTimer?.cancel();
    if (_channel != null) {
      await _channel.sink.close();
    }
    await _subscription?.cancel();
    await _disconnected();
    return true;
  }

  Future<bool> forceReconnect() async {
    _allowReconnect = true;
    _pingTimer?.cancel();
    if (_channel == null) {
      var result = await connect();
      return result.state == ConnectState.connected;
    }
    await _channel?.sink?.close();
    return true;
  }

  Completer<ConnectResult> _connectionCompleter;
  StreamSubscription _subscription;

  Future<void> _onStreamData(dynamic data) async {
    if (data is Uint8List) {
      // We pause and resume the stream once our read has fully completed. This
      // allows us to avoid race conditions with processing events that are
      // expected to happen in order.
      _subscription.pause();
      await read(data);

      _subscription.resume();
    }
  }

  Future<ConnectResult> connect() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _channel = RiveWebSocketChannel.connect(Uri.parse(url), _token);
    _connectionCompleter = Completer<ConnectResult>();

    _changeState(CoopConnectionState.connecting);

    runZoned(() {
      _subscription =
          _channel.stream.listen(_onStreamData, onError: (dynamic error) {
        _disconnected();
      }, onDone: () async {
        // Get the reason before disconnecting...
        var reason = _channel?.closeReason;
        await _disconnected();

        _connectionCompleter
            ?.complete(ConnectResult(ConnectState.networkError, info: reason));
        _connectionCompleter = null;
        if (_allowReconnect) {
          _reconnect();
        }
      });
    }, onError: (Object error, StackTrace stackTrace) {
      try {
        ErrorLogger.instance.reportException(error, stackTrace);
      } on Exception catch (e) {
        print('Failed to report: $e');
        print('Error was: $error, $stackTrace');
      }
    });
    return _connectionCompleter.future;
  }

  Future<void> _disconnected() async {
    _changeState(CoopConnectionState.disconnected);
    _pingTimer?.cancel();
    if (_channel != null && _channel.sink != null) {
      await _channel.sink.close();
    }

    _channel = null;
  }

  void write(Uint8List buffer) {
    assert(_connectionState == CoopConnectionState.handshaking ||
        _connectionState == CoopConnectionState.connected);
    _channel?.sink?.add(buffer);
  }

  @override
  void recvChange(ChangeSet changeSet) {
    // Make sure we do not apply changes that conflict with unacknowledged ones.
    makeChanges?.call(changeSet);
  }

  @override
  Future<void> recvGoodbye() async {
    // Handle the server telling us to disconnect.
    _allowReconnect = false;
    await _disconnected();
    _connectionCompleter?.complete(ConnectResult(ConnectState.notAuthorized));
    _connectionCompleter = null;
  }

  /// Accept changes, remove the unacknowledge change that matches this
  /// changeId.
  @override
  Future<void> recvAccept(int changeId) async {
    print("GOT ACCEPT $changeId");
    // Kind of odd to assert a network requirement (this is something the server
    // would mess up) but it helps track things down if they go wrong.
    assert(_unacknowledged != null,
        "Shouldn't receive an accept without sending changes.");

    var change = _unacknowledged.id == changeId ? _unacknowledged : null;
    if (change != null) {
      _unacknowledged = null;
      changesAccepted?.call(change);
    }
    _sendFreshChanges();
  }

  @override
  Future<void> recvReject(int changeId) async {
    // The server rejected one of our changes. We need to re-apply the old
    // state.
    var change = _unacknowledged.id == changeId ? _unacknowledged : null;
    if (change != null) {
      _unacknowledged = null;
      changesRejected?.call(change);
    }
    _sendFreshChanges();
  }

  @override
  Future<void> recvHello(int clientId) async {
    _clientId = clientId;
    gotClientId?.call(clientId);
    _changeState(CoopConnectionState.handshaking);
    _reconnectAttempt = 0;
    _isAuthenticated = true;

    // Once all offline changes are sent...

    assert(_connectionState == CoopConnectionState.handshaking);

    var changes = await getOfflineChanges?.call();
    _writer.writeSync(changes);
  }

  @override
  Future<void> recvReady() async {
    _changeState(CoopConnectionState.connected);
    _connectionCompleter?.complete(ConnectResult(ConnectState.connected));
    _connectionCompleter = null;
    _ping();
  }

  final List<ChangeSet> _fresh = [];
  ChangeSet _unacknowledged;
  void queueChanges(ChangeSet changes) {
    print("QUEUE CHANGES");
    // For now we send and save changes locally directly. Eventually we should
    // flatten them until they've been sent to a server as an atomic set.

    _fresh.add(changes);
    _sendFreshChanges();
  }

  // Need to call this on connect too.
  void _sendFreshChanges() {
    if (_unacknowledged != null ||
        _fresh.isEmpty ||
        _channel == null ||
        _channel.sink == null) {
      return;
    }
    print("SEND CHANGES ${_fresh.first.id}");
    var writer = BinaryWriter();
    _fresh.first.serialize(writer);
    _channel.sink.add(writer.uint8Buffer);
    _unacknowledged = _fresh.removeAt(0);
    // _fresh.clear();
  }

  @override
  Future<void> recvSync(List<ChangeSet> _) {
    throw UnsupportedError(
        "Client should never receive sync (gets sent only to server)");
  }

  @override
  Future<void> recvWipe() async {
    wipe?.call();
  }

  @override
  Future<void> recvPlayers(List<Player> players) async {
    if (!isConnected) {
      return;
    }
    updatePlayers?.call(players);
  }

  @override
  Future<void> recvCursor(double x, double y) {
    throw UnsupportedError(
        "Client should never receive cursor (gets sent only to server)");
  }

  @override
  Future<void> recvCursors(Map<int, PlayerCursor> cursors) async {
    for (final MapEntry<int, PlayerCursor> entry in cursors.entries) {
      updateCursor.call(entry.key, entry.value);
    }
  }

  void sendCursor(double x, double y) => _writer.writeCursor(x, y);

  @override
  Future<void> recvRevision(int id) {
    // TODO: darken screen!!!
    print("Client got revision: $id");
  }

  void restoreRevision(int id) => _writer.writeRevision(id);
}
