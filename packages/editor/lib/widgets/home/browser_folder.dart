import 'package:flutter/widgets.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';

class BrowserFolder extends StatefulWidget {
  const BrowserFolder(this.folderName, {Key key}) : super(key: key);
  final String folderName;

  @override
  State<StatefulWidget> createState() => _FolderState();
}

class _FolderState extends State<BrowserFolder> {
  bool _isHovered = false;
  bool _isSelected = false; // TODO:

  void setHover(bool val) {
    if (val != _isHovered) {
      setState(() {
        _isHovered = val;
      });
    }
  }

  // If we have a border, remove 4 pixels of padding.
  EdgeInsetsGeometry get padding => _isHovered
      ? const EdgeInsets.only(left: 11, top: 13, bottom: 14, right: 11)
      : const EdgeInsets.only(left: 15, top: 17, bottom: 18, right: 15);

  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);
    final colors = theme.colors;
    final styles = theme.textStyles;
    return MouseRegion(
      onEnter: (_) => setHover(true),
      onExit: (_) => setHover(false),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: colors.fileBackgroundLightGrey,
          borderRadius: BorderRadius.circular(10),
          border: _isHovered
              ? Border.all(
                  color: colors.fileSelectedBlue,
                  width: 4,
                )
              : null,
        ),
        child: Row(
          children: [
            TintedIcon(icon: 'folder', color: colors.black30),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.folderName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: styles.greyText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
