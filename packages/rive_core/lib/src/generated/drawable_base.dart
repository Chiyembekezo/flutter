/// Core automatically generated lib/src/generated/drawable_base.dart.
/// Do not modify manually.

import 'package:fractional/fractional.dart';
import 'package:meta/meta.dart';
import 'package:rive_core/node.dart';
import 'package:rive_core/src/generated/component_base.dart';
import 'package:rive_core/src/generated/container_component_base.dart';
import 'package:rive_core/src/generated/node_base.dart';

abstract class DrawableBase extends Node {
  static const int typeKey = 13;
  @override
  int get coreType => DrawableBase.typeKey;
  @override
  Set<int> get coreTypes => {
        DrawableBase.typeKey,
        NodeBase.typeKey,
        ContainerComponentBase.typeKey,
        ComponentBase.typeKey
      };

  /// --------------------------------------------------------------------------
  /// DrawOrder field with key 22.
  FractionalIndex _drawOrder;
  static const int drawOrderPropertyKey = 22;
  FractionalIndex get drawOrder => _drawOrder;

  /// Change the [_drawOrder] field value.
  /// [drawOrderChanged] will be invoked only if the field's value has changed.
  set drawOrder(FractionalIndex value) {
    if (_drawOrder == value) {
      return;
    }
    FractionalIndex from = _drawOrder;
    _drawOrder = value;
    drawOrderChanged(from, value);
  }

  @mustCallSuper
  void drawOrderChanged(FractionalIndex from, FractionalIndex to) {
    onPropertyChanged(drawOrderPropertyKey, from, to);
  }

  /// --------------------------------------------------------------------------
  /// BlendMode field with key 23.
  int _blendMode;
  static const int blendModePropertyKey = 23;
  int get blendMode => _blendMode;

  /// Change the [_blendMode] field value.
  /// [blendModeChanged] will be invoked only if the field's value has changed.
  set blendMode(int value) {
    if (_blendMode == value) {
      return;
    }
    int from = _blendMode;
    _blendMode = value;
    blendModeChanged(from, value);
  }

  @mustCallSuper
  void blendModeChanged(int from, int to) {
    onPropertyChanged(blendModePropertyKey, from, to);
  }

  @override
  void changeNonNull() {
    super.changeNonNull();
    if (drawOrder != null) {
      onPropertyChanged(drawOrderPropertyKey, drawOrder, drawOrder);
    }
    if (blendMode != null) {
      onPropertyChanged(blendModePropertyKey, blendMode, blendMode);
    }
  }

  @override
  K getProperty<K>(int propertyKey) {
    switch (propertyKey) {
      case drawOrderPropertyKey:
        return drawOrder as K;
      case blendModePropertyKey:
        return blendMode as K;
      default:
        return super.getProperty<K>(propertyKey);
    }
  }

  @override
  bool hasProperty(int propertyKey) {
    switch (propertyKey) {
      case drawOrderPropertyKey:
      case blendModePropertyKey:
        return true;
      default:
        return super.getProperty(propertyKey);
    }
  }
}
