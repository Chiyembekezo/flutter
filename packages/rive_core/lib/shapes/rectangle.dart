import 'package:rive_core/shapes/path_vertex.dart';
import 'package:rive_core/shapes/straight_vertex.dart';
import 'package:rive_core/src/generated/shapes/rectangle_base.dart';

/// Export the Base class for external use (e.g. rive.dart)
export 'package:rive_core/src/generated/shapes/rectangle_base.dart';

class Rectangle extends RectangleBase {
  @override
  List<PathVertex> get vertices => [
        StraightVertex()
          ..x = -width / 2
          ..y = -height / 2
          ..radius = cornerRadius,
        StraightVertex()
          ..x = width / 2
          ..y = -height / 2
          ..radius = cornerRadius,
        StraightVertex()
          ..x = width / 2
          ..y = height / 2
          ..radius = cornerRadius,
        StraightVertex()
          ..x = -width / 2
          ..y = height / 2
          ..radius = cornerRadius,
      ];

  @override
  void cornerRadiusChanged(double from, double to) => markPathDirty();
}
