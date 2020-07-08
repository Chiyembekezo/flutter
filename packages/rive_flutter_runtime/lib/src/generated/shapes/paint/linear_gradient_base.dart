/// Core automatically generated
/// lib/src/generated/shapes/paint/linear_gradient_base.dart.
/// Do not modify manually.

import 'package:rive/src/generated/component_base.dart';
import 'package:rive/src/generated/container_component_base.dart';
import 'package:rive/src/rive_core/container_component.dart';

abstract class LinearGradientBase extends ContainerComponent {
  static const int typeKey = 22;
  @override
  int get coreType => LinearGradientBase.typeKey;
  @override
  Set<int> get coreTypes => {
        LinearGradientBase.typeKey,
        ContainerComponentBase.typeKey,
        ComponentBase.typeKey
      };

  /// --------------------------------------------------------------------------
  /// StartX field with key 42.
  double _startX = 0;
  static const int startXPropertyKey = 42;
  double get startX => _startX;

  /// Change the [_startX] field value.
  /// [startXChanged] will be invoked only if the field's value has changed.
  set startX(double value) {
    if (_startX == value) {
      return;
    }
    double from = _startX;
    _startX = value;
    startXChanged(from, value);
  }

  void startXChanged(double from, double to);

  /// --------------------------------------------------------------------------
  /// StartY field with key 33.
  double _startY = 0;
  static const int startYPropertyKey = 33;
  double get startY => _startY;

  /// Change the [_startY] field value.
  /// [startYChanged] will be invoked only if the field's value has changed.
  set startY(double value) {
    if (_startY == value) {
      return;
    }
    double from = _startY;
    _startY = value;
    startYChanged(from, value);
  }

  void startYChanged(double from, double to);

  /// --------------------------------------------------------------------------
  /// EndX field with key 34.
  double _endX = 0;
  static const int endXPropertyKey = 34;
  double get endX => _endX;

  /// Change the [_endX] field value.
  /// [endXChanged] will be invoked only if the field's value has changed.
  set endX(double value) {
    if (_endX == value) {
      return;
    }
    double from = _endX;
    _endX = value;
    endXChanged(from, value);
  }

  void endXChanged(double from, double to);

  /// --------------------------------------------------------------------------
  /// EndY field with key 35.
  double _endY = 0;
  static const int endYPropertyKey = 35;
  double get endY => _endY;

  /// Change the [_endY] field value.
  /// [endYChanged] will be invoked only if the field's value has changed.
  set endY(double value) {
    if (_endY == value) {
      return;
    }
    double from = _endY;
    _endY = value;
    endYChanged(from, value);
  }

  void endYChanged(double from, double to);

  /// --------------------------------------------------------------------------
  /// Opacity field with key 46.
  double _opacity = 1;
  static const int opacityPropertyKey = 46;
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

  void opacityChanged(double from, double to);
}
