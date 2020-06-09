import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:rive_editor/frameDebounce.dart';

/// TODO: determine if we can commit murder
class CorePropertyBuilder<T> extends StatefulWidget {
  final Core object;

  final int propertyKey;
  final ValueWidgetBuilder<T> builder;

  final Widget child;

  const CorePropertyBuilder({
    @required this.object,
    @required this.propertyKey,
    @required this.builder,
    this.child,
    Key key,
  })  : assert(object != null),
        assert(propertyKey != null),
        assert(builder != null),
        super(key: key);

  @override
  State<StatefulWidget> createState() => _CorePropertyBuilderState<T>();
}

class _CorePropertyBuilderState<T> extends State<CorePropertyBuilder<T>> {
  T previous;
  T value;

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, value, widget.child);
  }

  @override
  void didUpdateWidget(CorePropertyBuilder<T> oldWidget) {
    if (oldWidget.object != widget.object ||
        oldWidget.propertyKey != widget.propertyKey) {
      oldWidget.object.removeListener(oldWidget.propertyKey, _valueChanged);

      _bindListener();
    }
    super.didUpdateWidget(oldWidget);
  }

  void _bindListener() {
    var object = widget.object;
    var propertyKey = widget.propertyKey;

    var currentPropertyValue =
        object.context.getObjectProperty(object, propertyKey);
    assert(currentPropertyValue == null || currentPropertyValue is T,
        'expected $currentPropertyValue to be of type $T');
    value = currentPropertyValue as T;
    object.addListener(propertyKey, _valueChanged);
  }

  @override
  void dispose() {
    widget.object.removeListener(widget.propertyKey, _valueChanged);
    cancelFrameDebounce(_rebuild);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _bindListener();
  }

  void _rebuild() {
    (context as StatefulElement).markNeedsBuild();
  }

  void _valueChanged(dynamic from, dynamic to) {
    assert(to is T);

    // We debounce here to ensure that the update doesn't occur during a build
    // (this can happen if animations/changes get applied in response to some
    // other change that occurs during the build cycle).

    value = to as T;
    frameDebounce(_rebuild);
  }
}
