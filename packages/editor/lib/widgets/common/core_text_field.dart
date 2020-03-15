import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:rive_editor/widgets/common/converters/input_value_converter.dart';
import 'package:rive_editor/widgets/core_properties_builder.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/inspector/properties/inspector_text_field.dart';

/// A text field that manipulates core properties.
///
/// The [propertyKey] is hander over to [CorePropertiesBuilder] to extract the
/// associated field data to be displayed within this text field.
class CoreTextField<T> extends StatefulWidget {
  final Iterable<Core> objects;
  final int propertyKey;
  final InputValueConverter<T> converter;

  const CoreTextField({
    @required this.objects,
    @required this.propertyKey,
    this.converter,
    Key key,
  }) : super(key: key);

  @override
  _CoreTextFieldState<T> createState() => _CoreTextFieldState<T>();
}

class _CoreTextFieldState<T> extends State<CoreTextField<T>> {
  @override
  Widget build(BuildContext context) {
    return CorePropertiesBuilder(
      objects: widget.objects,
      propertyKey: widget.propertyKey,
      builder: (context, T value, _) => InspectorTextField(
        // edgeInsets: const EdgeInsets.only(bottom: 3),
        // isNumeric: true,
        // initialValue: widget.converter.toDisplayValue(value),
        value: value,
        converter: widget.converter,
        change: (T value) {
          for (final object in widget.objects) {
            object.context.setObjectProperty(object, widget.propertyKey, value);
          }
        },
        completeChange: () {
          if (widget.objects.isEmpty) {
            return;
          }
          widget.objects.first.context.captureJournalEntry();

          // Force focus back to the main context so that we can immediately
          // undo this change if we want to by hitting ctrl/comamnd z.
          RiveContext.of(context).focus();
        },
      ),
    );
  }
}
