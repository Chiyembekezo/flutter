import 'package:meta/meta.dart';
import 'package:rive_core/component_dirt.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/src/generated/shapes/parametric_path_base.dart';
export 'package:rive_core/src/generated/shapes/parametric_path_base.dart';

abstract class ParametricPath extends ParametricPathBase {
  @override
  bool get isClosed => true;

  @override
  Mat2D get pathTransform => worldTransform;

  /// Subclasses should call this whenever a parameter that affects the topology
  /// of the path changes in order to allow the system to rebuild the parametric
  /// path.
  @protected
  void markPathDirty() {
    addDirt(ComponentDirt.path);
    shape?.pathChanged(this);
  }

  @override
  void widthChanged(double from, double to) => markPathDirty();

  @override
  void heightChanged(double from, double to) => markPathDirty();

  @override
  void xChanged(double from, double to) {
    super.xChanged(from, to);
    shape?.pathChanged(this);
  }

  @override
  void yChanged(double from, double to) {
    super.yChanged(from, to);
    shape?.pathChanged(this);
  }

  @override
  void rotationChanged(double from, double to) {
    super.rotationChanged(from, to);
    shape?.pathChanged(this);
  }

  @override
  void scaleXChanged(double from, double to) {
    super.scaleXChanged(from, to);
    shape?.pathChanged(this);
  }

  @override
  void scaleYChanged(double from, double to) {
    super.scaleYChanged(from, to);
    shape?.pathChanged(this);
  }
}
