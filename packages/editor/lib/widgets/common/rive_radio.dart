import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';

class DescriptionRadio<T> extends StatelessWidget {
  const DescriptionRadio({
    @required this.value,
    @required this.groupValue,
    @required this.label,
    @required this.onChanged,
    this.selectedColor,
    this.backgroundColor,
    Key key,
  }) : super(key: key);

  final T value;
  final T groupValue;
  final String label;
  final ValueChanged<T> onChanged;
  final Color selectedColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);
    final colors = theme.colors;
    final styles = theme.textStyles;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (value != groupValue) onChanged(value);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              RiveRadio<T>(
                groupValue: groupValue,
                value: value,
                onChanged: onChanged,
                selectedColor: colors.commonDarkGrey,
              ),
              const SizedBox(width: 10),
              Text(label, style: styles.greyText),
            ],
          ),
        ],
      ),
    );
  }
}

class RiveRadio<T> extends StatefulWidget {
  final T value;
  final T groupValue;
  final ValueChanged<T> onChanged;
  final Color selectedColor;
  final Color backgroundColor;

  const RiveRadio({
    @required this.value,
    @required this.groupValue,
    @required this.onChanged,
    this.selectedColor,
    this.backgroundColor,
    Key key,
  }) : super(key: key);

  @override
  State<RiveRadio> createState() => _RiveRadioState<T>();
}

class _RiveRadioState<T> extends State<RiveRadio<T>> {
  Map<Type, Action<Intent>> _actionMap;
  bool _hasFocus = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    final callbackAction = CallbackAction<ActivateIntent>(onInvoke: _activate);
    _actionMap = {ActivateIntent: callbackAction};
  }

  void _activate(ActivateIntent intent) {
    if (widget.onChanged != null) {
      widget.onChanged(widget.value);
    }
    final renderObject = context.findRenderObject();
    renderObject.sendSemanticsEvent(const TapSemanticEvent());
  }

  void _onFocusChanged(bool hasFocus) {
    if (_hasFocus != hasFocus) {
      setState(() {
        _hasFocus = hasFocus;
      });
    }
  }

  void _onHoverChanged(bool isHovered) {
    if (_isHovered != isHovered) {
      setState(() {
        _isHovered = isHovered;
      });
    }
  }

  Color get _selectedColor => widget.selectedColor ?? const Color(0xFF333333);

  Color get _backgroundColor {
    final bgColor = widget.backgroundColor ?? const Color(0xFFF1F1F1);
    if (_hasFocus || _isHovered) {
      return Color.lerp(bgColor, _selectedColor, 0.15);
    }
    return bgColor;
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: FocusableActionDetector(
        actions: _actionMap,
        onShowFocusHighlight: _onFocusChanged,
        onShowHoverHighlight: _onHoverChanged,
        child: _RiveRadioRenderer(
          isSelected: widget.value == widget.groupValue,
          isFocused: _hasFocus,
          selectedColor: widget.selectedColor ?? const Color(0xFF333333),
          backgroundColor: _backgroundColor,
        ),
      ),
    );
  }
}

class _RiveRadioRenderer extends LeafRenderObjectWidget {
  final bool isSelected;
  final bool isFocused;
  final Color selectedColor;
  final Color backgroundColor;

  const _RiveRadioRenderer({
    @required this.isSelected,
    @required this.isFocused,
    @required this.selectedColor,
    @required this.backgroundColor,
    Key key,
  })  : assert(isSelected != null),
        assert(selectedColor != null),
        super(key: key);

  @override
  RenderObject createRenderObject(BuildContext context) => _RiveRadioRenderBox(
      isSelected: isSelected,
      selectedColor: selectedColor,
      backgroundColor: backgroundColor);
  @override
  void updateRenderObject(
      BuildContext context, _RiveRadioRenderBox renderObject) {
    renderObject
      ..isSelected = isSelected
      ..selectedColor = selectedColor
      ..backgroundColor = backgroundColor;
  }
}

class _RiveRadioRenderBox extends RenderBox {
  static const _radius = 10.0;
  static const _innerRadius = 4.0;
  static const _diameter = _radius * 2;
  _RiveRadioRenderBox(
      {@required bool isSelected,
      @required Color selectedColor,
      @required Color backgroundColor,
      ValueChanged<bool> onChanged})
      : _isSelected = isSelected,
        _onChanged = onChanged,
        _selectedColor = selectedColor,
        _backgroundColor = backgroundColor;

  bool _isSelected;
  Color _selectedColor;
  Color _backgroundColor;
  final ValueChanged<bool> _onChanged;

  bool get isSelected => _isSelected;
  set isSelected(bool value) {
    if (_isSelected == value) {
      return;
    }
    _isSelected = value;
    markNeedsPaint();
  }

  Color get selectedColor => _selectedColor;
  set selectedColor(Color value) {
    if (_selectedColor == value) {
      return;
    }
    _selectedColor = value;
    markNeedsPaint();
  }

  Color get backgroundColor => _backgroundColor;
  set backgroundColor(Color value) {
    if (_backgroundColor == value) {
      return;
    }
    _backgroundColor = value;
    markNeedsPaint();
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void performLayout() {
    size = const Size(_diameter, _diameter);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = _backgroundColor;

    final center = (offset & size).center;

    // Background circle.
    canvas.drawCircle(center, _radius, paint);

    if (_isSelected) {
      canvas.drawCircle(center, _innerRadius, paint..color = _selectedColor);
    }
  }

  void _onPressed() {
    if (_onChanged == null) return;
    if (isSelected) {
      _onChanged(true);
    } else {
      _onChanged(false);
    }
    sendSemanticsEvent(const TapSemanticEvent());
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    if (_onChanged != null) {
      config.onTap = _onPressed;
    }
  }
}
