import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/theme.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';

class SettingsHeader extends StatefulWidget {
  final String name;
  final int teamSize;
  final String avatarPath;
  final VoidCallback changeAvatar;

  const SettingsHeader(
      {@required this.name, this.teamSize, this.avatarPath, this.changeAvatar});

  @override
  _SettingsHeaderState createState() => _SettingsHeaderState();
}

class _SettingsHeaderState extends State<SettingsHeader> {
  bool get isTeam => widget.teamSize > 0;

  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);
    final textStyles = theme.textStyles;

    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            EditableAvatar(
              avatarPath: widget.avatarPath,
              changeAvatar: widget.changeAvatar,
            ),
            const SizedBox(width: 10),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.name,
                  style: textStyles.fileGreyTextLarge,
                ),
                if (isTeam) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Team Plan',
                    style: textStyles.hyperLinkSubtext,
                  )
                ]
              ],
            ),
            const Spacer(),
            if (isTeam)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${widget.teamSize} members',
                    style: textStyles.fileGreyTextLarge
                        .copyWith(fontSize: 13, height: 1.3),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Add More',
                    style: textStyles.hyperLinkSubtext,
                  )
                ],
              ),
          ],
        ));
  }
}

class EditableAvatar extends StatefulWidget {
  const EditableAvatar({
    @required this.avatarPath,
    @required this.changeAvatar,
    Key key,
  }) : super(key: key);

  final String avatarPath;
  final VoidCallback changeAvatar;

  @override
  _EditableAvatarState createState() => _EditableAvatarState();
}

class _EditableAvatarState extends State<EditableAvatar> {
  bool _hover = false;
  void setHover(bool hover) {
    setState(() {
      _hover = hover;
    });
  }

  final double radius = 25;

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];
    final theme = RiveTheme.of(context);
    final riveColors = theme.colors;
    if (_hover) {
      children.add(Positioned.fill(
          child: CustomPaint(
              painter: _CirclePainter(
        radius: radius,
      ))));
    }
    if (widget.avatarPath == null) {
      children.addAll([
        Positioned.fill(
            child: CustomPaint(
                painter: _DashedCirclePainter(
          radius: radius,
        ))),
        Center(
            child: TintedIcon(color: riveColors.fileIconColor, icon: 'image'))
      ]);
    } else {
      children.add(Center(
        child: SizedBox(
          width: radius * 2,
          height: radius * 2,
          child: CircleAvatar(
            backgroundColor: Colors.transparent,
            backgroundImage: NetworkImage(widget.avatarPath),
          ),
        ),
      ));
    }
    return SizedBox(
      width: radius * 2,
      height: radius * 2,
      child: GestureDetector(
        onTap: widget.changeAvatar,
        child: MouseRegion(
          onEnter: (_) => setHover(true),
          onExit: (_) => setHover(false),
          child: Stack(children: children),
        ),
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  final double radius;

  const _DashedCirclePainter({@required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 1
      ..color = RiveThemeData().colors.commonButtonTextColor
      ..style = PaintingStyle.stroke;

    final circlePath = Path()..addOval(Offset.zero & size);

    canvas.drawPath(
        dashPath(circlePath, dashArray: CircularIntervalList([3, 3])), paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    if (oldDelegate is _DashedCirclePainter) {
      return oldDelegate.radius != radius;
    }
    return true;
  }
}

class _CirclePainter extends CustomPainter {
  final double radius;

  const _CirclePainter({@required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = RiveThemeData().colors.shadow25
      ..style = PaintingStyle.fill;

    canvas.drawOval(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    if (oldDelegate is _CirclePainter) {
      return oldDelegate.radius != radius;
    }
    return true;
  }
}
