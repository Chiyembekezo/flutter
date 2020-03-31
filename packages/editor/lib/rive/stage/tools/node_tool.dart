import 'dart:ui';

import 'package:rive_core/artboard.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/node.dart';
import 'package:rive_editor/rive/stage/tools/clickable_tool.dart';
import 'package:rive_editor/rive/stage/tools/stage_tool.dart';

class NodeTool extends StageTool with ClickableTool {
  static final NodeTool instance = NodeTool._();

  NodeTool._();

  @override
  void onClick(Artboard artboard, Vec2D worldMouse) {
    final file = stage.file;
    var core = file.core;

    // final selection = rive.selection.items;
    final ContainerComponent parent = artboard;

    final node = Node()
      ..name = "Node"
      ..x = worldMouse[0]
      ..y = worldMouse[1];

    core.batchAdd(() {
      core.add(node);
      parent.appendChild(node);
    });
  }

  @override
  String get icon => 'tool-node';

  @override
  void draw(Canvas canvas) {}
}
