import 'package:rxdart/rxdart.dart';
import 'package:rxdart/subjects.dart';

/// The [Plumber] manages streams for data that flows in the application.
///
/// It provides a mapping between a data [Type], and a Stream for that type.
///
/// E.g.: If the application wants to know the [CurrentDirectory] (i.e. the
/// directory currently visible in the file browser), it can ask the [Plumber]
/// to access the pipe with that type. And since the file browser will be
/// listening for [CurrentDirectory] changes, we can swap the current directory
/// by sending a new [CurrentDirectory] down the pipe.
///
/// The application can also add an (optional) id for a given type to augment
///  the mapping and have multiple streams of the same type.
///
/// E.g.: In the case of multiple files, the Plumber can use a [String] as an id
/// to have a two-level mapping: first identify the type, then identify the pipe
/// with the id.
class Plumber {
  factory Plumber() => _instance;
  Plumber._();
  static final Plumber _instance = Plumber._();

  final Map<Type, Map<int, BehaviorSubject>> _pipes = {};

  /// Retrives the pipe for type T, and it plumbs it if not present.
  /// An optional [id] can be used to have multiple pipes of the same type.
  BehaviorSubject<T> _pipeInit<T>([int id]) {
    if (!_pipes.containsKey(T)) {
      _pipes[T] = {};
    }
    if (!_pipes[T].containsKey(id)) {
      _pipes[T][id] = BehaviorSubject<T>();
    }
    return _pipes[T][id] as BehaviorSubject<T>;
  }

  bool _exists<T>([int id]) {
    return _pipes.containsKey(T) && _pipes[T].containsKey(id);
  }

  ValueStream<T> getStream<T>([int id]) =>_pipeInit<T>(id).stream;

  T peek<T>([int id]) => _pipeInit<T>(id).value;


  void message<T>(T message, [int id]) => _pipeInit<T>(id).add(message);


  void flush<T>([int id]) {
    var pipe = _pipeInit<T>(id);
    if (pipe.value != null) {
      pipe.add(null);
    }
  }

  void shutdown<T>([int id]) {
    if (_exists<T>(id)) {
      _pipeInit<T>(id).close();
      // NOTE: potentially leaving empty map behind.
      _pipes[T].remove(id);
    }
  }

  void reset() {
    // TODO: notify a few thigns to disconnect from each other?
    _pipes.values.forEach((pipeMap) {
      pipeMap.values.forEach((pipe) {
        pipe.close();
      });
      pipeMap.clear();
    });
    _pipes.clear();
  }
}
