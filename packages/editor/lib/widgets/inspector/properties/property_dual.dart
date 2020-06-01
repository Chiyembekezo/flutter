import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:rive_editor/packed_icon.dart';
import 'package:rive_editor/widgets/common/converters/input_value_converter.dart';
import 'package:rive_editor/widgets/common/core_text_field.dart';
import 'package:rive_editor/widgets/common/sub_label.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/theme.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';

/// An inspector row with two input fields of the same core property type.
/// Optional linking such that when one changes the other does too.
class PropertyDual<T> extends StatelessWidget {
  final List<Core> objects;
  final int propertyKeyA;
  final int propertyKeyB;
  final String iconName;
  final String labelA;
  final String labelB;
  final String name;
  final bool linkable;
  final bool isLinked;
  final void Function(bool link) toggleLink;
  final InputValueConverter<T> converter;

  const PropertyDual({
    @required this.objects,
    @required this.propertyKeyA,
    @required this.propertyKeyB,
    this.name,
    this.iconName,
    this.linkable = false,
    this.isLinked = false,
    this.toggleLink,
    this.labelA = '',
    this.labelB = '',
    this.converter,
    Key key,
  }) : super(key: key);

  Widget _link(Widget child, RiveThemeData theme) {
    return linkable
        ? Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              child,
              const SizedBox(height: 5),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (_) => toggleLink?.call(!isLinked),
                child: TintedIcon(
                  icon: isLinked ? PackedIcon.link : PackedIcon.unlink,
                  color: theme.textStyles.inspectorPropertySubLabel.color,
                ),
              ),
            ],
          )
        : child;
  }

  /// Build the [CoreTextField] and setups up the property and linked property
  /// keys up so that they get mirrored when one changes (if linking is on).
  Widget _buildCoreTextField(int propertyKey, int linkedKey) => CoreTextField(
        objects: objects,
        propertyKey: propertyKey,
        converter: converter,
        change: isLinked
            ? (T value) {
                for (final object in objects) {
                  object.context.setObjectProperty(object, linkedKey, value);
                }
              }
            : null,
      );

  @override
  Widget build(BuildContext context) {
    var theme = RiveTheme.of(context);
    var textStyles = theme.textStyles;
    return Padding(
      padding: const EdgeInsets.only(
        left: 20,
        right: 20,
        top: 7,
        bottom: 10,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _link(
              Text(
                name,
                style: textStyles.inspectorPropertyLabel,
              ),
              theme,
            ),
          ),
          const SizedBox(width: 20),
          Flexible(
            flex: 1,
            child: SubLabel(
              label: labelA,
              style: theme.textStyles.inspectorPropertySubLabel,
              child: _buildCoreTextField(
                propertyKeyA,
                propertyKeyB,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Flexible(
            flex: 1,
            child: SubLabel(
              label: labelB,
              style: theme.textStyles.inspectorPropertySubLabel,
              child: _buildCoreTextField(
                propertyKeyB,
                propertyKeyA,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
