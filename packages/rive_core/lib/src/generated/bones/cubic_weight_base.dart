/// Core automatically generated lib/src/generated/bones/cubic_weight_base.dart.
/// Do not modify manually.

import 'dart:collection';
import 'package:core/core.dart';
import 'package:rive_core/bones/weight.dart';
import 'package:rive_core/src/generated/bones/weight_base.dart';
import 'package:rive_core/src/generated/component_base.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';

abstract class CubicWeightBase extends Weight {
  static const int typeKey = 46;
  @override
  int get coreType => CubicWeightBase.typeKey;
  @override
  Set<int> get coreTypes =>
      {CubicWeightBase.typeKey, WeightBase.typeKey, ComponentBase.typeKey};

  /// --------------------------------------------------------------------------
  /// InValues field with key 110.
  int _inValues = 255;
  static const int inValuesPropertyKey = 110;
  int get inValues => _inValues;

  /// Change the [_inValues] field value.
  /// [inValuesChanged] will be invoked only if the field's value has changed.
  set inValues(int value) {
    if (_inValues == value) {
      return;
    }
    int from = _inValues;
    _inValues = value;
    onPropertyChanged(inValuesPropertyKey, from, value);
    inValuesChanged(from, value);
  }

  void inValuesChanged(int from, int to);

  /// --------------------------------------------------------------------------
  /// InIndices field with key 111.
  int _inIndices = 1;
  static const int inIndicesPropertyKey = 111;
  int get inIndices => _inIndices;

  /// Change the [_inIndices] field value.
  /// [inIndicesChanged] will be invoked only if the field's value has changed.
  set inIndices(int value) {
    if (_inIndices == value) {
      return;
    }
    int from = _inIndices;
    _inIndices = value;
    onPropertyChanged(inIndicesPropertyKey, from, value);
    inIndicesChanged(from, value);
  }

  void inIndicesChanged(int from, int to);

  /// --------------------------------------------------------------------------
  /// OutValues field with key 112.
  int _outValues = 255;
  static const int outValuesPropertyKey = 112;
  int get outValues => _outValues;

  /// Change the [_outValues] field value.
  /// [outValuesChanged] will be invoked only if the field's value has changed.
  set outValues(int value) {
    if (_outValues == value) {
      return;
    }
    int from = _outValues;
    _outValues = value;
    onPropertyChanged(outValuesPropertyKey, from, value);
    outValuesChanged(from, value);
  }

  void outValuesChanged(int from, int to);

  /// --------------------------------------------------------------------------
  /// OutIndices field with key 113.
  int _outIndices = 1;
  static const int outIndicesPropertyKey = 113;
  int get outIndices => _outIndices;

  /// Change the [_outIndices] field value.
  /// [outIndicesChanged] will be invoked only if the field's value has changed.
  set outIndices(int value) {
    if (_outIndices == value) {
      return;
    }
    int from = _outIndices;
    _outIndices = value;
    onPropertyChanged(outIndicesPropertyKey, from, value);
    outIndicesChanged(from, value);
  }

  void outIndicesChanged(int from, int to);

  @override
  void changeNonNull() {
    super.changeNonNull();
    if (_inValues != null) {
      onPropertyChanged(inValuesPropertyKey, _inValues, _inValues);
    }
    if (_inIndices != null) {
      onPropertyChanged(inIndicesPropertyKey, _inIndices, _inIndices);
    }
    if (_outValues != null) {
      onPropertyChanged(outValuesPropertyKey, _outValues, _outValues);
    }
    if (_outIndices != null) {
      onPropertyChanged(outIndicesPropertyKey, _outIndices, _outIndices);
    }
  }

  @override
  void writeRuntimeProperties(BinaryWriter writer, HashMap<Id, int> idLookup) {
    super.writeRuntimeProperties(writer, idLookup);
    if (_inValues != null && exports(inValuesPropertyKey)) {
      context.uintType
          .writeRuntimeProperty(inValuesPropertyKey, writer, _inValues);
    }
    if (_inIndices != null && exports(inIndicesPropertyKey)) {
      context.uintType
          .writeRuntimeProperty(inIndicesPropertyKey, writer, _inIndices);
    }
    if (_outValues != null && exports(outValuesPropertyKey)) {
      context.uintType
          .writeRuntimeProperty(outValuesPropertyKey, writer, _outValues);
    }
    if (_outIndices != null && exports(outIndicesPropertyKey)) {
      context.uintType
          .writeRuntimeProperty(outIndicesPropertyKey, writer, _outIndices);
    }
  }

  @override
  bool exports(int propertyKey) {
    switch (propertyKey) {
      case inValuesPropertyKey:
        return _inValues != 255;
      case inIndicesPropertyKey:
        return _inIndices != 1;
      case outValuesPropertyKey:
        return _outValues != 255;
      case outIndicesPropertyKey:
        return _outIndices != 1;
    }
    return super.exports(propertyKey);
  }

  @override
  K getProperty<K>(int propertyKey) {
    switch (propertyKey) {
      case inValuesPropertyKey:
        return inValues as K;
      case inIndicesPropertyKey:
        return inIndices as K;
      case outValuesPropertyKey:
        return outValues as K;
      case outIndicesPropertyKey:
        return outIndices as K;
      default:
        return super.getProperty<K>(propertyKey);
    }
  }

  @override
  bool hasProperty(int propertyKey) {
    switch (propertyKey) {
      case inValuesPropertyKey:
      case inIndicesPropertyKey:
      case outValuesPropertyKey:
      case outIndicesPropertyKey:
        return true;
      default:
        return super.hasProperty(propertyKey);
    }
  }
}
