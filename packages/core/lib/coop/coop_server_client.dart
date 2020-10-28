import 'dart:typed_data';

import 'package:logging/logging.dart';

import 'package:core/debounce.dart';

import 'package:core/coop/player.dart';
import 'package:core/coop/player_cursor.dart';
import 'package:core/coop/change.dart';
import 'package:core/coop/coop_isolate.dart';
import 'package:core/coop/coop_reader.dart';
import 'package:core/coop/coop_writer.dart';

final log = Logger('core_coop');

class CoopServerClient extends Player with CoopReader {
  CoopWriter _writer;
  final int id;
  // final HttpRequest request;
  final CoopIsolateProcess context;
  bool _isReady = false;
  bool get isReady => _isReady;

  CoopWriter get writer => _writer;

  void receiveData(dynamic data) {
    if (data is Uint8List) {
      read(data);
    }
  }

  CoopServerClient(this.context, this.id, int ownerId, int clientId)
      : super(clientId, ownerId) {
    _writer = CoopWriter(write);

    _writer.writeHello(clientId);
  }

  void write(Uint8List buffer) {
    context.write(this, buffer);
  }

  @override
  void recvChange(ChangeSet changes) {
    print('got changes(${changes.id}) from client($clientId)');
    if (context.attemptChange(this, changes)) {
      _writer.writeAccept(changes.id);
      debounce(context.persist, duration: const Duration(seconds: 2));
    } else {
      _writer.writeReject(changes.id);
    }
  }

  @override
  Future<void> recvGoodbye() {
    throw UnsupportedError("Server should never receive goodbye.");
  }

  @override
  Future<void> recvSync(List<ChangeSet> changes) async {
    print("got sync!");
    // Apply offline changes.
    if (changes.isNotEmpty) {
      for (final change in changes) {
        print("sync attempt change!");
        context.attemptChange(this, change);
      }
      debounce(context.persist, duration: const Duration(seconds: 2));
    }
    print("start the wipe!");

    _writer.writeWipe();
    print('wiped');
    final initialChanges = context.buildFileChangeSet();
    if (initialChanges != null) {
      print('sending initial changeSet to client');
      _writer.writeChanges(initialChanges);
      print('sent initial changeSet to client');
    }
    print('telling client they\'re ready');
    _writer.writeReady();
    print('we\'re ready');
    _isReady = true;
    context.onClientReady(this);
    print('done recvSync');
  }

  @override
  void cursorChanged() {
    context.cursorChanged(this);
  }

  @override
  Future<void> recvWipe() {
    throw UnsupportedError("Server should never receive wipe.");
  }

  @override
  Future<void> recvHello(int clientId) {
    throw UnsupportedError("Server should never receive hello.");
  }

  @override
  Future<void> recvAccept(int changeId) {
    throw UnsupportedError("Server should never receive accept.");
  }

  @override
  Future<void> recvReject(int changeId) {
    throw UnsupportedError("Server should never receive reject.");
  }

  @override
  Future<void> recvReady() {
    throw UnsupportedError("Server should never receive ready.");
  }

  @override
  Future<void> recvPlayers(List<Player> players) {
    throw UnsupportedError("Server should never receive players.");
  }

  @override
  Future<void> recvCursor(double x, double y) async {
    cursor = PlayerCursor(x, y);
  }

  @override
  Future<void> recvCursors(Map<int, PlayerCursor> cursors) {
    throw UnsupportedError("Server should never receive cursors.");
  }

  @override
  Future<void> recvRevision(int id) => context.restoreRevision(id);

  void notifyChangingRevision() {
    _writer.writeRevision(0);
  }

  void completeChangingRevision() {
    _writer.writeHello(clientId);
  }
}
