import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:rive_editor/widgets/common/flat_icon_button.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/popup/tip.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';

// 3 pixels painted, 3 gap. etc.
final CircularIntervalList<double> dashArray =
    CircularIntervalList([3.toDouble(), 3.toDouble()]);

class DashedPainter extends CustomPainter {
  final double radius;
  final Color dashColor;
  const DashedPainter({@required this.radius, @required this.dashColor});

  @override
  void paint(Canvas canvas, Size size) {
    // drawing a rect of size 30, ends up drawing 31 pixels..
    final appliedSize = Size(size.width, size.height - 1);

    Paint paint = Paint()
      ..strokeWidth = 1
      ..color = dashColor
      ..style = PaintingStyle.stroke;
    var path = Path();
    path.addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, appliedSize.width, appliedSize.height),
        Radius.circular(radius)));
    path = dashPath(path, dashArray: dashArray);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class DashedFlatButton extends StatelessWidget {
  const DashedFlatButton({
    @required this.label,
    @required this.icon,
    this.textColor,
    this.iconColor,
    this.onTap,
    this.tip,
  });

  final String label;
  final String icon;
  final Color textColor;
  final Color iconColor;
  final VoidCallback onTap;
  final Tip tip;

  @override
  Widget build(BuildContext context) {
    final iconColor =
        this.iconColor ?? RiveTheme.of(context).colors.fileIconColor;

    final button = FlatIconButton(
      icon: TintedIcon(
        icon: icon,
        color: iconColor,
      ),
      label: label,
      color: Colors.transparent,
      textColor: textColor,
      onTap: onTap,
      tip: tip,
    );
    return CustomPaint(
      painter: DashedPainter(radius: button.radius, dashColor: iconColor),
      child: button,
    );
  }
}
