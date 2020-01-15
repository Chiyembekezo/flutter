import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rive_core/selectable_item.dart';

import 'file.dart';

class FolderItem extends SelectableItem {
  final String name;
  final ValueKey<String> key;
  final List<FileItem> files;

  FolderItem({
    @required this.key,
    @required this.name,
    this.files = const [],
  });
}
