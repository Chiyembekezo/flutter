import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/common/flat_icon_button.dart';
import 'package:rive_editor/widgets/common/rive_radio.dart';
import 'package:rive_editor/widgets/gradient_border.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';

class SubscriptionChoice extends StatefulWidget {
  final String label;
  final String costLabel;
  final String description;
  final VoidCallback onTap;
  // Interpolation value for the highlight of this widget.
  // This values should be between 0 (not highlighted),
  // and 1 (fully highlighted).
  // Interpolate [0,1] to obtain the desired effect.
  final double highlight;
  // Whether this subscription option has been selected.
  final bool isSelected;
  // This widget has two modes:
  // - one with the radio button selection
  // - one with a 'Choose' button on the bottom (and no radio)
  // This flag enables the first mode.
  final bool showRadio;

  const SubscriptionChoice({
    this.label,
    this.costLabel,
    this.description,
    this.onTap,
    this.isSelected = false,
    this.highlight = 0,
    this.showRadio = true,
    Key key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _SubscriptionChoiceState();
}

class _SubscriptionChoiceState extends State<SubscriptionChoice>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _label(double animationValue) {
    final theme = RiveTheme.of(context);
    final colors = theme.colors;
    final textStyles = theme.textStyles;
    if (widget.showRadio) {
      return Row(children: [
        GestureDetector(
          onTap: widget.onTap,
          child: RiveRadio<bool>(
              groupValue: true,
              value: widget.isSelected,
              onChanged: null, // handled above
              backgroundColor: Color.lerp(colors.buttonLight,
                  colors.toggleInactiveBackground, animationValue)),
        ),
        const SizedBox(width: 10),
        Text(
          widget.label,
          style: textStyles.fileGreyTextLarge,
        ),
      ]);
    }
    return Text(
      widget.label,
      style: textStyles.fileGreyTextLarge,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);
    final colors = theme.colors;
    final textStyles = theme.textStyles;
    final gradients = theme.gradients;
    final animationValue = widget.highlight;

    return GestureDetector(
      onTap: widget.showRadio ? null : widget.onTap,
      child: Padding(
        padding: EdgeInsets.only(
          top: lerpDouble(2, 0, animationValue),
          bottom: lerpDouble(0, 2, animationValue),
        ),
        child: GradientBorder(
          strokeWidth: 3,
          radius: 10,
          shouldPaint: true,
          gradient: LinearGradient.lerp(gradients.transparentLinear,
              gradients.redPurpleBottomCenter, animationValue),
          child: Container(
            width: 181,
            margin: const EdgeInsets.all(3),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Color.lerp(colors.panelBackgroundLightGrey, Colors.white,
                    animationValue),
                boxShadow: [
                  BoxShadow(
                    color: Color.lerp(Colors.transparent,
                        colors.commonButtonColor, animationValue),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  )
                ]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _label(animationValue),
                SizedBox(height: widget.showRadio ? 17 : 13),
                RichText(
                    text: TextSpan(children: [
                  TextSpan(
                    text: '\$' + widget.costLabel,
                    style: textStyles.fileGreyTextLarge,
                  ),
                  TextSpan(
                    text: '/mo per user',
                    style: textStyles.fileGreyTextSmall,
                  )
                ])),
                const SizedBox(height: 12),
                Text(widget.description,
                    overflow: TextOverflow.visible,
                    softWrap: true,
                    style: textStyles.fileLightGreyText.copyWith(
                        height: 1.6,
                        color: Color.lerp(colors.commonButtonTextColorDark,
                            colors.commonLightGrey, animationValue))),
                if (!widget.showRadio) ...[
                  const SizedBox(height: 14),
                  Padding(
                    padding: EdgeInsets.only(
                      top: lerpDouble(2, 0, animationValue),
                      bottom: lerpDouble(0, 2, animationValue),
                    ),
                    child: FlatIconButton(
                      mainAxisAlignment: MainAxisAlignment.center,
                      label: 'Choose',
                      color: Color.lerp(colors.buttonLight,
                          colors.textButtonDark, animationValue),
                      textColor: Color.lerp(colors.commonButtonTextColorDark,
                          Colors.white, animationValue),
                      elevation: lerpDouble(
                          0, flatButtonIconElevation, animationValue),
                    ),
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}
