import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/common/converters/input_value_converter.dart';

/// Convert HSVColor to an editable hex value.
class HexValueConverter extends InputValueConverter<HSVColor> {
  @override
  HSVColor fromEditingValue(String value) {
    var hex = value.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    } else if (hex.length == 3) {
      hex = 'FF${hex[0]}${hex[0]}${hex[1]}${hex[1]}${hex[2]}${hex[2]}';
    }
    return HSVColor.fromColor(Color(int.parse('0x$hex')));
  }

  @override
  String toEditingValue(HSVColor value) => value
      .toColor()
      .value
      .toRadixString(16)
      .toString()
      .substring(2)
      .toUpperCase();

  @override
  bool get allowDrag => false;

  static final HexValueConverter instance = HexValueConverter();
}
