import 'package:rive_core/component_dirt.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/shapes/path.dart';
import 'package:rive_core/shapes/path_vertex.dart';
import 'package:rive_core/shapes/straight_vertex.dart';

class UserPath extends Path {
  bool _isClosed = true;
  final List<PathVertex> _vertices = [];

  @override
  bool get isClosed => _isClosed;
  set isClosed(bool val) {
    if (val != _isClosed) {
      _isClosed = val;
      addDirt(ComponentDirt.path);
    }
  }

  @override
  Mat2D get pathTransform => worldTransform;

  @override
  List<PathVertex> get vertices => _vertices;

  // TODO: support Cubic Vertices on Drag
  void addVertex(double x, double y) {
    var vertex = StraightVertex()
      ..x = x
      ..y = y;
    _vertices.add(vertex);
    addDirt(ComponentDirt.path);
  }

  void removeVertex(PathVertex v) {
    int removeIdx = _vertices.indexOf(v);
    if (removeIdx != -1) {
      _vertices.removeAt(removeIdx);
      addDirt(ComponentDirt.path);
    } else {
      throw ArgumentError.value(v, "Value not in the collection");
    }
  }
}
