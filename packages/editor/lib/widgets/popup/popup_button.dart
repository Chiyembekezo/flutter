import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/popup/popup_direction.dart';
import 'package:rive_editor/widgets/popup/tip.dart';

import 'list_popup.dart';

/// Callback providing the opened popup.
typedef PopupOpened<T extends PopupListItem> = void Function(ListPopup<T>);

/// Callback to build the list of items when the popup is opened.
typedef BuildPopupItems<T extends PopupListItem> = List<T> Function(
    BuildContext);

/// A widget that opens a popup when it is tapped on.
class PopupButton<T extends PopupListItem> extends StatefulWidget {
  final WidgetBuilder builder;

  /// Builds the list of items to be shown, this is only triggered when the
  /// popup is opened.
  final BuildPopupItems<T> itemsBuilder;

  /// Called back for each visible item in the list built by [itemsBuilder] when
  /// it needs to be built.
  final ListPopupItemBuilder<T> itemBuilder;
  final PopupOpened<T> opened;
  final double width;
  final Offset arrowTweak;
  final PopupDirection direction;
  final double directionPadding;
  final Tip tip;

  const PopupButton({
    @required this.builder,
    @required this.itemsBuilder,
    Key key,
    this.itemBuilder,
    this.opened,
    this.direction = PopupDirection.bottomToRight,
    this.directionPadding = 16,
    this.arrowTweak = Offset.zero,
    this.width = 177,
    this.tip,
  }) : super(key: key);

  @override
  _PopupButtonState<T> createState() => _PopupButtonState<T>();
}

class _PopupButtonState<T extends PopupListItem> extends State<PopupButton<T>> {
  Widget _addTip(Widget child) {
    // Don't show the tip if we don't have one or the popup is already open.
    if (widget.tip == null || _popup != null) {
      return child;
    }
    return TipRegion(tip: widget.tip, child: child);
  }

  ListPopup<T> _popup;
  TipContext _tipContext;

  @override
  void dispose() {
    super.dispose();

    _tipContext?.encourage();
    _tipContext = null;

    _popup?.close();
  }

  @override
  Widget build(BuildContext context) {
    return _addTip(
      GestureDetector(
        onTapDown: (details) {
          setState(
            () {
              var items = widget.itemsBuilder(context);
              _popup = ListPopup<T>.show(
                context,
                direction: widget.direction,
                directionPadding: widget.directionPadding,
                items: items,
                itemBuilder: widget.itemBuilder,
                arrowTweak: widget.arrowTweak,
                width: widget.width,
                onClose: () {
                  setState(() => _popup = null);
                  _tipContext?.encourage();
                  _tipContext = null;
                },
              );
              widget.opened?.call(_popup);

              // Don't show any tips while we're showing a popup.
              _tipContext = TipRoot.of(context);
              _tipContext?.suppress();
            },
          );
        },
        child: widget.builder(context),
      ),
    );
  }
}
