/// Core automatically generated
/// lib/src/generated/animation/keyframe_color_base.dart.
/// Do not modify manually.

import 'dart:collection';
import 'package:core/core.dart';
import 'package:core/field_types/core_field_type.dart';
import 'package:rive_core/animation/keyframe.dart';
import 'package:rive_core/src/generated/animation/keyframe_base.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';

abstract class KeyFrameColorBase extends KeyFrame {
  static const int typeKey = 37;
  @override
  int get coreType => KeyFrameColorBase.typeKey;
  @override
  Set<int> get coreTypes => {KeyFrameColorBase.typeKey, KeyFrameBase.typeKey};

  /// --------------------------------------------------------------------------
  /// Value field with key 88.
  int _value;
  static const int valuePropertyKey = 88;
  int get value => _value;

  /// Change the [_value] field value.
  /// [valueChanged] will be invoked only if the field's value has changed.
  set value(int value) {
    if (_value == value) {
      return;
    }
    int from = _value;
    _value = value;
    onPropertyChanged(valuePropertyKey, from, value);
    valueChanged(from, value);
  }

  void valueChanged(int from, int to);

  @override
  void changeNonNull() {
    super.changeNonNull();
    if (_value != null) {
      onPropertyChanged(valuePropertyKey, _value, _value);
    }
  }

  @override
  void writeRuntimeProperties(BinaryWriter writer,
      HashMap<int, CoreFieldType> propertyToField, HashMap<Id, int> idLookup) {
    super.writeRuntimeProperties(writer, propertyToField, idLookup);
    if (_value != null && exports(valuePropertyKey)) {
      context.colorType.writeRuntimeProperty(
          valuePropertyKey, writer, _value, propertyToField);
    }
  }

  @override
  K getProperty<K>(int propertyKey) {
    switch (propertyKey) {
      case valuePropertyKey:
        return value as K;
      default:
        return super.getProperty<K>(propertyKey);
    }
  }

  @override
  bool hasProperty(int propertyKey) {
    switch (propertyKey) {
      case valuePropertyKey:
        return true;
      default:
        return super.hasProperty(propertyKey);
    }
  }
}
