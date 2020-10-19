import 'package:core/error_logger/error_logger.dart';
import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:rive_api/manager.dart';
import 'package:rive_editor/packed_icon.dart';
import 'package:rive_editor/platform/platform.dart';
import 'package:rive_editor/preferences.dart';
import 'package:rive_editor/rive/managers/image_manager.dart';
import 'package:rive_editor/widgets/common/underline_text_button.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/theme.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';

class SettingsHeader extends StatefulWidget {
  final String name;
  final int teamMemberCount;
  final int teamMemberPaidCount;
  final String avatarPath;
  final bool avatarUploading;
  final VoidCallback changeAvatar;
  final bool isTeam;

  const SettingsHeader(
      {@required this.name,
      @required this.isTeam,
      this.teamMemberCount,
      this.teamMemberPaidCount,
      this.avatarPath,
      this.changeAvatar,
      this.avatarUploading});

  @override
  _SettingsHeaderState createState() => _SettingsHeaderState();
}

class _SettingsHeaderState extends State<SettingsHeader> {
  bool _isSigningOut = false;

  Widget _trailing() {
    final theme = RiveTheme.of(context);
    final textStyles = theme.textStyles;
    final colors = theme.colors;
    final teamMemberCount = widget.teamMemberCount;
    final teamMemberPaidCount = widget.teamMemberPaidCount;
    if (widget.isTeam) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          RichText(
            text: TextSpan(
              style: textStyles.fileGreyTextLarge
                  .copyWith(fontSize: 13, height: 1.3),
              children: <TextSpan>[
                if (teamMemberCount != 1)
                  TextSpan(text: '$teamMemberCount members'),
                if (teamMemberCount == 1) const TextSpan(text: '1 member'),
                if (teamMemberPaidCount != teamMemberCount)
                  TextSpan(text: ' ($teamMemberPaidCount billed)'),
              ],
            ),
          ),
        ],
      );
    } else {
      return UnderlineTextButton(
        text: 'Sign Out',
        textColor:
            _isSigningOut ? colors.commonLightGrey : colors.commonDarkGrey,
        onPressed: () {
          if (_isSigningOut) return;
          setState(() {
            _isSigningOut = true;
          });

          // Question:
          // This could live in the manager, but then the manager woudl need
          // to know about editor. maybe the manager should be moved to editor?
          UserManager().signout(Platform.instance.isWeb).then(
            (success) {
              if (!success) {
                setState(() {
                  // Let the user try again.
                  _isSigningOut = false;
                });
              } else {
                // TODO: is this the best place to do it?
                Settings.clear(Preferences.spectreToken);
                ErrorLogger.instance.dropCrumb(
                  category: 'auth',
                  message: 'signed out',
                  severity: CrumbSeverity.info,
                );
                Navigator.of(context, rootNavigator: true).pop();
              }
            },
          );
        },
      );
    }
  }

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
                avatarUploading: widget.avatarUploading),
            const SizedBox(width: 10),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.name,
                  style: textStyles.fileGreyTextLarge,
                ),
                if (widget.isTeam) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Studio Plan',
                    style: textStyles.hyperLinkSubtext,
                  )
                ]
              ],
            ),
            const Spacer(),
            _trailing()
          ],
        ));
  }
}

class EditableAvatar extends StatefulWidget {
  final double avatarRadius;
  const EditableAvatar({
    @required this.avatarPath,
    @required this.changeAvatar,
    @required this.avatarUploading,
    this.avatarRadius = 25,
    Key key,
  }) : super(key: key);

  final String avatarPath;
  final VoidCallback changeAvatar;
  final bool avatarUploading;

  @override
  _EditableAvatarState createState() =>
      _EditableAvatarState(radius: avatarRadius);
}

class _EditableAvatarState extends State<EditableAvatar> {
  final double radius;
  bool _hover = false;
  bool _avatarImageFailed = false;

  _EditableAvatarState({this.radius = 25});
  void setHover(bool hover) {
    setState(() {
      _hover = hover;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];
    final theme = RiveTheme.of(context);
    final riveColors = theme.colors;
    if (widget.avatarUploading) {
      children.add(Center(
          child: SizedBox(
              width: radius * 2,
              height: radius * 2,
              child: const CircularProgressIndicator())));
    } else if (widget.avatarPath == null || _avatarImageFailed) {
      children.addAll(
        [
          Positioned.fill(
            child: CustomPaint(
              painter: _DashedCirclePainter(
                radius: radius,
              ),
            ),
          ),
          Center(
            child: TintedIcon(
                color: riveColors.fileIconColor, icon: PackedIcon.image),
          )
        ],
      );
    } else {
      children.add(
        Center(
          child: SizedBox(
            width: radius * 2,
            height: radius * 2,
            child: CachedCircleAvatar(
              widget.avatarPath,
              onImageError: () {
                if (!mounted) {
                  return;
                }
                setState(
                  () {
                    _avatarImageFailed = true;
                  },
                );
              },
            ),
          ),
        ),
      );
    }
    if (_hover) {
      children.add(
        Positioned.fill(
          child: CustomPaint(
            painter: _CirclePainter(
              radius: radius,
            ),
          ),
        ),
      );
    }
    return SizedBox(
      width: radius * 2,
      height: radius * 2,
      child: GestureDetector(
        onTap: () {
          setHover(false);
          widget.changeAvatar();
        },
        child: MouseRegion(
          // only trigger hover change if we have a changeAvatar implementation
          onEnter: (_) => setHover((widget.changeAvatar != null) && true),
          onExit: (_) => setHover((widget.changeAvatar != null) && false),
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
