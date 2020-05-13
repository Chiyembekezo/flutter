import 'package:flutter/material.dart';

const kDefaultWIndowSize = Size(1366, 768);

enum EditMode { normal, altMode1, altMode2 }

enum DraggingMode { symmetric }

const Map<EditMode, DraggingMode> editModeMap = {
  EditMode.altMode1: DraggingMode.symmetric
};


/// This is the maximum time that can elapse between two clicks to consider them
/// a double click.
const doubleClickSpeed = Duration(milliseconds: 200);