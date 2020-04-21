/// Core automatically generated
/// lib/src/generated/shapes/paint/stroke_base.dart.
/// Do not modify manually.

import 'package:meta/meta.dart';
import 'package:rive_core/shapes/paint/shape_paint.dart';
import 'package:rive_core/src/generated/component_base.dart';
import 'package:rive_core/src/generated/container_component_base.dart';
import 'package:rive_core/src/generated/shapes/paint/shape_paint_base.dart';

abstract class StrokeBase extends ShapePaint {
  static const int typeKey = 24;
  @override
  int get coreType => StrokeBase.typeKey;
  @override
  Set<int> get coreTypes => {
        StrokeBase.typeKey,
        ShapePaintBase.typeKey,
        ContainerComponentBase.typeKey,
        ComponentBase.typeKey
      };

  /// --------------------------------------------------------------------------
  /// Thickness field with key 47.
  double _thickness = 1;
  static const int thicknessPropertyKey = 47;
  double get thickness => _thickness;

  /// Change the [_thickness] field value.
  /// [thicknessChanged] will be invoked only if the field's value has changed.
  set thickness(double value) {
    if (_thickness == value) {
      return;
    }
    double from = _thickness;
    _thickness = value;
    thicknessChanged(from, value);
  }

  @mustCallSuper
  void thicknessChanged(double from, double to) {
    onPropertyChanged(thicknessPropertyKey, from, to);
  }

  /// --------------------------------------------------------------------------
  /// Cap field with key 48.
  int _cap = 0;
  static const int capPropertyKey = 48;
  int get cap => _cap;

  /// Change the [_cap] field value.
  /// [capChanged] will be invoked only if the field's value has changed.
  set cap(int value) {
    if (_cap == value) {
      return;
    }
    int from = _cap;
    _cap = value;
    capChanged(from, value);
  }

  @mustCallSuper
  void capChanged(int from, int to) {
    onPropertyChanged(capPropertyKey, from, to);
  }

  /// --------------------------------------------------------------------------
  /// Join field with key 49.
  int _join = 0;
  static const int joinPropertyKey = 49;
  int get join => _join;

  /// Change the [_join] field value.
  /// [joinChanged] will be invoked only if the field's value has changed.
  set join(int value) {
    if (_join == value) {
      return;
    }
    int from = _join;
    _join = value;
    joinChanged(from, value);
  }

  @mustCallSuper
  void joinChanged(int from, int to) {
    onPropertyChanged(joinPropertyKey, from, to);
  }

  /// --------------------------------------------------------------------------
  /// TransformAffectsStroke field with key 50.
  bool _transformAffectsStroke = true;
  static const int transformAffectsStrokePropertyKey = 50;
  bool get transformAffectsStroke => _transformAffectsStroke;

  /// Change the [_transformAffectsStroke] field value.
  /// [transformAffectsStrokeChanged] will be invoked only if the field's value
  /// has changed.
  set transformAffectsStroke(bool value) {
    if (_transformAffectsStroke == value) {
      return;
    }
    bool from = _transformAffectsStroke;
    _transformAffectsStroke = value;
    transformAffectsStrokeChanged(from, value);
  }

  @mustCallSuper
  void transformAffectsStrokeChanged(bool from, bool to) {
    onPropertyChanged(transformAffectsStrokePropertyKey, from, to);
  }

  @override
  void changeNonNull() {
    super.changeNonNull();
    if (thickness != null) {
      onPropertyChanged(thicknessPropertyKey, thickness, thickness);
    }
    if (cap != null) {
      onPropertyChanged(capPropertyKey, cap, cap);
    }
    if (join != null) {
      onPropertyChanged(joinPropertyKey, join, join);
    }
    if (transformAffectsStroke != null) {
      onPropertyChanged(transformAffectsStrokePropertyKey,
          transformAffectsStroke, transformAffectsStroke);
    }
  }

  @override
  K getProperty<K>(int propertyKey) {
    switch (propertyKey) {
      case thicknessPropertyKey:
        return thickness as K;
      case capPropertyKey:
        return cap as K;
      case joinPropertyKey:
        return join as K;
      case transformAffectsStrokePropertyKey:
        return transformAffectsStroke as K;
      default:
        return super.getProperty<K>(propertyKey);
    }
  }

  @override
  bool hasProperty(int propertyKey) {
    switch (propertyKey) {
      case thicknessPropertyKey:
      case capPropertyKey:
      case joinPropertyKey:
      case transformAffectsStrokePropertyKey:
        return true;
      default:
        return super.getProperty(propertyKey);
    }
  }
}
