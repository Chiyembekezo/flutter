import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/popup/popup_direction.dart';

import 'list_popup.dart';

/// Callback providing the opened popup.
typedef PopupOpened<T extends PopupListItem> = void Function(ListPopup<T>);

/// A widget that opens a popup when it is tapped on.
class PopupButton<T extends PopupListItem> extends StatelessWidget {
  final WidgetBuilder builder;
  final List<T> items;
  final ListPopupItemBuilder<T> itemBuilder;
  final PopupOpened<T> opened;
  final double width;
  final Offset arrowTweak;
  final PopupDirection direction;

  const PopupButton({
    @required this.builder,
    @required this.items,
    Key key,
    this.itemBuilder,
    this.opened,
    this.direction = PopupDirection.bottomToRight,
    this.arrowTweak = Offset.zero,
    this.width = 177,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        final popup = ListPopup<T>.show(
          context,
          direction: direction,
          items: items,
          itemBuilder: itemBuilder,
          arrowTweak: arrowTweak,
          width: width,
        );
        opened?.call(popup);
      },
      child: builder(context),
    );
  }
}
