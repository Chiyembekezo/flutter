import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:rive_core/component.dart';
import 'package:rive_core/selectable_item.dart';
import 'package:rive_editor/widgets/tree_view/stage_item_icon.dart';

import 'package:tree_widget/flat_tree_item.dart';
import 'package:tree_widget/tree_scroll_view.dart';
import 'package:tree_widget/tree_widget.dart';

import 'package:rive_editor/widgets/common/renamable.dart';
import 'package:rive_editor/widgets/core_property_builder.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/tree_view/tree_expander.dart';
import 'package:rive_editor/widgets/tree_view/drop_item_background.dart';

import 'package:rive_editor/rive/draw_order_tree_controller.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';

/// An example tree view, shows how to implement TreeView widget and style it.
class DrawOrderTreeView extends StatelessWidget {
  final DrawOrderTreeController controller;

  const DrawOrderTreeView({
    @required this.controller,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var theme = RiveTheme.of(context);
    var style = theme.treeStyles.hierarchy;
    return TreeScrollView(
      padding: style.padding,
      slivers: [
        TreeView<Component>(
          style: style,
          controller: controller,
          expanderBuilder: (context, item, style) => Container(
            child: Center(
              child: TreeExpander(
                key: item.key,
                iconColor: Colors.white,
                isExpanded: item.isExpanded,
              ),
            ),
            decoration: BoxDecoration(
              border: Border.all(
                color: style.lineColor,
                width: 1.0,
                style: BorderStyle.solid,
              ),
              borderRadius: const BorderRadius.all(
                Radius.circular(7.5),
              ),
            ),
          ),
          iconBuilder: (context, item, style) =>
              StageItemIcon(item: item.data.stageItem),
          extraBuilder: (context, item, index) => Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white,
                width: 1.0,
                style: BorderStyle.solid,
              ),
              borderRadius: const BorderRadius.all(
                Radius.circular(7.5),
              ),
            ),
          ),
          backgroundBuilder: (context, item, style) =>
              ValueListenableBuilder<DropState>(
            valueListenable: item.dropState,
            builder: (context, dropState, _) =>
                ValueListenableBuilder<SelectionState>(
              builder: (context, selectionState, _) {
                return DropItemBackground(
                  dropState,
                  selectionState,
                  hoverColor: theme.colors.editorTreeHover,
                );
              },
              valueListenable: item.data.stageItem?.selectionState,
            ),
          ),
          itemBuilder: (context, item, style) =>
              ValueListenableBuilder<SelectionState>(
            builder: (context, state, _) => Expanded(
              child: Padding(
                  padding: const EdgeInsets.only(right: 5),
                  child: CorePropertyBuilder<String>(
                    object: item.data,
                    propertyKey: ComponentBase.namePropertyKey,
                    builder: (context, name, _) => Renamable(
                      name: name,
                      color: state == SelectionState.selected
                          ? Colors.white
                          : Colors.grey.shade500,
                      onRename: (name) {
                        item.data.name = name;
                        controller.file.core.captureJournalEntry();
                      },
                    ),
                  )),
            ),
            valueListenable: item.data.stageItem.selectionState,
          ),
          dragItemBuilder: (context, items, style) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: items
                .map(
                  (item) => Text(
                    item.data.name,
                    style: theme.textStyles.treeDragItem,
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}
