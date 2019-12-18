/// Core automatically generated lib/src/generated/node_base.dart.
/// Do not modify manually.

import '../../container_component.dart';

abstract class NodeBase extends ContainerComponent {
  static const int typeKey = 2;

  /// --------------------------------------------------------------------------
  /// X field with key 11.
  double _x;
  static const int xPropertyKey = 11;
  double get x => _x;

  /// Change the [_x] field value.
  /// [xChanged] will be invoked only if the field's value has changed.
  set x(double value) {
    if (_x == value) {
      return;
    }
    double from = _x;
    _x = value;
    xChanged(from, value);
  }

  void xChanged(double from, double to) {
    context?.changeProperty(this, xPropertyKey, from, to);
  }

  /// --------------------------------------------------------------------------
  /// Y field with key 12.
  double _y;
  static const int yPropertyKey = 12;
  double get y => _y;

  /// Change the [_y] field value.
  /// [yChanged] will be invoked only if the field's value has changed.
  set y(double value) {
    if (_y == value) {
      return;
    }
    double from = _y;
    _y = value;
    yChanged(from, value);
  }

  void yChanged(double from, double to) {
    context?.changeProperty(this, yPropertyKey, from, to);
  }

  /// --------------------------------------------------------------------------
  /// Rotation field with key 13.
  double _rotation;
  static const int rotationPropertyKey = 13;
  double get rotation => _rotation;

  /// Change the [_rotation] field value.
  /// [rotationChanged] will be invoked only if the field's value has changed.
  set rotation(double value) {
    if (_rotation == value) {
      return;
    }
    double from = _rotation;
    _rotation = value;
    rotationChanged(from, value);
  }

  void rotationChanged(double from, double to) {
    context?.changeProperty(this, rotationPropertyKey, from, to);
  }

  /// --------------------------------------------------------------------------
  /// ScaleX field with key 14.
  double _scaleX;
  static const int scaleXPropertyKey = 14;
  double get scaleX => _scaleX;

  /// Change the [_scaleX] field value.
  /// [scaleXChanged] will be invoked only if the field's value has changed.
  set scaleX(double value) {
    if (_scaleX == value) {
      return;
    }
    double from = _scaleX;
    _scaleX = value;
    scaleXChanged(from, value);
  }

  void scaleXChanged(double from, double to) {
    context?.changeProperty(this, scaleXPropertyKey, from, to);
  }

  /// --------------------------------------------------------------------------
  /// ScaleY field with key 15.
  double _scaleY;
  static const int scaleYPropertyKey = 15;
  double get scaleY => _scaleY;

  /// Change the [_scaleY] field value.
  /// [scaleYChanged] will be invoked only if the field's value has changed.
  set scaleY(double value) {
    if (_scaleY == value) {
      return;
    }
    double from = _scaleY;
    _scaleY = value;
    scaleYChanged(from, value);
  }

  void scaleYChanged(double from, double to) {
    context?.changeProperty(this, scaleYPropertyKey, from, to);
  }

  /// --------------------------------------------------------------------------
  /// Opacity field with key 16.
  double _opacity;
  static const int opacityPropertyKey = 16;
  double get opacity => _opacity;

  /// Change the [_opacity] field value.
  /// [opacityChanged] will be invoked only if the field's value has changed.
  set opacity(double value) {
    if (_opacity == value) {
      return;
    }
    double from = _opacity;
    _opacity = value;
    opacityChanged(from, value);
  }

  void opacityChanged(double from, double to) {
    context?.changeProperty(this, opacityPropertyKey, from, to);
  }
}
