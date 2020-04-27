import 'package:flutter/widgets.dart';
import 'package:rive_core/selectable_item.dart';
import 'package:rive_editor/rive/managers/animation/editing_animation_manager.dart';
import 'package:rive_editor/widgets/animation/keyed_object_tree_controller.dart';
import 'package:rive_editor/widgets/common/converters/translation_value_converter.dart';
import 'package:rive_editor/widgets/common/core_text_field.dart';
import 'package:rive_editor/widgets/common/renamable.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/theme.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';
import 'package:rive_editor/widgets/tree_view/drop_item_background.dart';
import 'package:rive_editor/widgets/tree_view/stage_item_icon.dart';
import 'package:rive_editor/widgets/tree_view/tree_expander.dart';
import 'package:rive_editor/widgets/ui_strings.dart';
import 'package:tree_widget/flat_tree_item.dart';
import 'package:tree_widget/tree_scroll_view.dart';
import 'package:tree_widget/tree_style.dart';
import 'package:tree_widget/tree_widget.dart';

class KeyedObjectHierarchy extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var animationManager = EditingAnimationProvider.of(context);
    if (animationManager == null) {
      return const SizedBox();
    }
    return _KeyedObjectTree(
      animationManager: animationManager,
    );
  }
}

class _KeyedObjectTree extends StatefulWidget {
  final EditingAnimationManager animationManager;

  const _KeyedObjectTree({
    @required this.animationManager,
    Key key,
  }) : super(key: key);

  @override
  __KeyedObjectTreeState createState() => __KeyedObjectTreeState();
}

class __KeyedObjectTreeState extends State<_KeyedObjectTree> {
  KeyedObjectTreeController _treeController;
  @override
  void initState() {
    _treeController = KeyedObjectTreeController(widget.animationManager);
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _treeController.dispose();
  }

  @override
  void didUpdateWidget(_KeyedObjectTree oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animationManager != widget.animationManager) {
      _treeController = KeyedObjectTreeController(widget.animationManager);
    }
  }

  @override
  Widget build(BuildContext context) {
    var theme = RiveTheme.of(context);
    var style = TreeStyle(
      showFirstLine: false,
      hideLines: true,
      padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
      lineColor: RiveTheme.of(context).colors.darkTreeLines,
    );
    return TreeScrollView(
      padding: style.padding,
      slivers: [
        TreeView<KeyedViewModel>(
          style: style,
          controller: _treeController,
          expanderBuilder: (context, item, style) => Container(
            child: Center(
              child: TreeExpander(
                key: item.key,
                iconColor: theme.colors.buttonHover,
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
          iconBuilder: (context, item, style) => item.data
                  is KeyedObjectViewModel
              ? StageItemIcon(
                  item: (item.data as KeyedObjectViewModel).component.stageItem,
                )
              : null,
          backgroundBuilder: (context, item, style) => DropItemBackground(
            DropState.none,
            SelectionState.none,
            color: theme.colors.animationSelected,
            hoverColor: theme.colors.editorTreeHover,
          ),
          itemBuilder: (context, item, style) {
            var data = item.data;
            if (data is KeyedObjectViewModel) {
              return _buildKeyedObject(context, theme, data);
            } else if (data is KeyedGroupViewModel) {
              return _buildKeyedGroup(context, theme, data);
            } else if (data is KeyedPropertyViewModel) {
              return _buildKeyedProperty(context, theme, data);
            }
            return const SizedBox();
          },
        ),
      ],
    );
  }

  Widget _buildKeyedObject(
      BuildContext context, RiveThemeData theme, KeyedObjectViewModel model) {
    return Renamable(
      style: theme.textStyles.inspectorWhiteLabel,
      name: model.component.name,
      color: theme.colors.inspectorTextColor,
      onRename: (name) {},
    );
  }

  Widget _buildKeyedGroup(
      BuildContext context, RiveThemeData theme, KeyedGroupViewModel model) {
    return Renamable(
      style: theme.textStyles.inspectorWhiteLabel,
      name: model.label,
      color: theme.colors.inspectorTextColor,
      onRename: (name) {},
    );
  }

  Widget _buildKeyedProperty(
      BuildContext context, RiveThemeData theme, KeyedPropertyViewModel model) {
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              UIStrings.of(context).withKey(model.label),
              style: theme.textStyles.inspectorWhiteLabel,
            ),
          ),
          if (model.subLabel != null)
            Text(
              UIStrings.of(context).withKey(model.subLabel),
              style: theme.textStyles.animationSubLabel,
            ),
          Padding(
            padding: const EdgeInsets.only(top: 2, left: 9, right: 15),
            child: SizedBox(
              width: 69,
              child: CoreTextField<double>(
                underlineColor: theme.colors.timelineUnderline,
                objects: [model.component],
                propertyKey: model.keyedProperty.propertyKey,
                converter: TranslationValueConverter.instance,
              ),
            ),
          ),
          TintedIcon(
            icon: 'add',
            color: theme.colors.inspectorTextColor,
          )
        ],
      ),
    );
  }
}
