import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/popup/popup_direction.dart';
import 'base_popup.dart';

typedef ListPopupItemBuilder<T> = Widget Function(
    BuildContext context, T item, bool isHovered);

/// Helper to extract the global coordinate rect of a specific build context's
/// first render object.
class ContextToGlobalRect {
  ValueNotifier<Rect> rect = ValueNotifier<Rect>(Rect.zero);

  void updateRect(BuildContext context) {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final boxOffset = renderBox.localToGlobal(Offset.zero);
    rect.value = boxOffset & size;
  }
}

/// Opens a popup with an arrow pointing to the area of interest/whatever
/// launched the popup.
class ArrowPopup {
  final Popup popup;
  final ContextToGlobalRect contextRect;
  ArrowPopup({
    this.contextRect,
    this.popup,
  });

  bool close() => popup.close();

  factory ArrowPopup.show(
    BuildContext context, {

    /// The widget builder for the content in the popup body.
    @required WidgetBuilder builder,

    /// Width of the popup panel, excluding arrows and directional padding.
    double width = 177,

    /// Offset used to shift the screen coordinates of the popup (useful when
    /// trying to align with some other content that may have relative offsets
    /// from what launched the popup).
    Offset offset = Offset.zero,

    /// Specify global position to use instead of direction.
    Offset position,

    /// Spacing applied between the area of interest and the popup in the
    /// direction this popup is docked/opened.
    double directionPadding = 16,

    /// Whether the arrow pointing to the area of interest that launched this
    /// popup should be shown.
    bool showArrow = true,

    /// Directional based offset applied to the arrow only in order to help
    /// align it to icons or other items in the area of interest that launched
    /// this popup.
    Offset arrowTweak = Offset.zero,

    /// The popup direction used to determine where this popup docks and which
    /// direction it opens in relative to the context that opened it.
    PopupDirection direction = PopupDirection.bottomToRight,

    /// Alternative directions used when the desired one would result in an
    /// off-screen layout.
    List<PopupDirection> fallbackDirections = PopupDirection.all,

    /// Background color for the popup.
    Color background = const Color.fromRGBO(17, 17, 17, 1),

    /// Whether this popup wants its own close guard (a default close guard is
    /// provided which closes all open popups, use this if you want to keep
    /// other popups open when clicking off of this popup).
    bool includeCloseGuard = false,

    /// Callback invoked whenver the popup is closed.
    VoidCallback onClose,
  }) {
    var contextRect = ContextToGlobalRect()..updateRect(context);

    return ArrowPopup(
      contextRect: contextRect,
      popup: Popup.show(
        context,
        onClose: onClose,
        includeCloseGuard: includeCloseGuard,
        builder: (context) {
          return ValueListenableBuilder<Rect>(
            valueListenable: contextRect.rect,
            builder: (context, contextRect, child) {
              if (position != null) {
                // Use a layout system for a global cursor position.
                return CustomSingleChildLayout(
                  delegate: _PositionedPopupDelegate(position, width),
                  child: child,
                );
              } else {
                _ListPopupMultiLayoutDelegate _layoutDelegate =
                    _ListPopupMultiLayoutDelegate(
                  from: contextRect,
                  direction: direction,
                  fallbackDirections: fallbackDirections,
                  width: width,
                  offset: offset,
                  directionPadding: directionPadding,
                  arrowTweak: arrowTweak,
                );
                return CustomMultiChildLayout(
                  delegate: _layoutDelegate,
                  children: [
                    if (showArrow)
                      LayoutId(
                        id: _ListPopupLayoutElement.arrow,
                        child: CustomPaint(
                          painter: _ArrowPathPainter(
                            background,
                            _layoutDelegate,
                          ),
                        ),
                      ),
                    LayoutId(
                      id: _ListPopupLayoutElement.body,
                      child: child,
                    ),
                  ],
                );
              }
            },
            child: Material(
              type: MaterialType.transparency,
              child: Container(
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(5.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3473),
                      offset: const Offset(0.0, 30.0),
                      blurRadius: 30,
                    )
                  ],
                ),
                child: builder(context),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Helper IDs used in the layout delegate to determine which child is which.
enum _ListPopupLayoutElement { arrow, body }

// Make sure to use floor here instead of round or it'll work in unexpected ways
// when the direction is negative on one axis.
Offset _wholePixels(Offset offset) =>
    Offset(offset.dx.floorToDouble(), offset.dy.floorToDouble());

// Amount to pad from screen edges.
const double _edgePad = 10;

/// A custom layout module for list popup which handles aligning the arrow and
/// content to the desired region of interest and expansion direction.
class _ListPopupMultiLayoutDelegate extends MultiChildLayoutDelegate {
  final Rect from;
  final PopupDirection direction;
  final List<PopupDirection> fallbackDirections;
  final double directionPadding;
  final double width;
  final Offset offset;
  final Offset arrowTweak;
  final bool closeOnResize;
  PopupDirection bestDirection;

  /// Screen size when layout is performed
  Size layoutSize;

  _ListPopupMultiLayoutDelegate({
    this.from,
    this.direction,
    this.fallbackDirections = PopupDirection.all,
    this.directionPadding,
    this.width,
    this.offset,
    this.arrowTweak,
    this.closeOnResize = true,
  });

  @override
  bool shouldRelayout(_ListPopupMultiLayoutDelegate oldDelegate) {
    var should = oldDelegate.from != from ||
        oldDelegate.direction != direction ||
        oldDelegate.width != width ||
        oldDelegate.offset != offset ||
        oldDelegate.arrowTweak != arrowTweak;
    if (!should) {
      // total hack, if it shouldn't re-layout, make sure we copy the
      // oldDelegate's bestPosition so we can provide it to whatever else
      // cares about it.
      bestDirection = oldDelegate.bestDirection;
    }
    return should;
  }

  Offset _computeBodyPosition(PopupDirection direction, Size bodySize) =>
      from.topLeft +
      // Align to target of interest/dock position (from)
      direction.from.alongSize(from.size) -
      // Align the list relative to that position (to)
      direction.to.alongSize(bodySize) +
      // Offset by whatever list position tweak was passed in.
      offset +
      // Apply any directionaly padding
      (direction.offsetVector * directionPadding);

  bool _isOutOf(
          Offset bodyPosition, Size bodySize, Size size, Size arrowSize) =>
      bodyPosition.dx < arrowSize.width / 2 + _edgePad ||
      bodyPosition.dx + bodySize.width >
          size.width - arrowSize.width - _edgePad ||
      bodyPosition.dy < arrowSize.height / 2 + _edgePad ||
      bodyPosition.dy + bodySize.height >
          size.height - arrowSize.height - _edgePad;

  @override
  void performLayout(Size size) {
    /// Layout is performed whenever when the screen is resized
    /// Close the popup when this happens if desired
    if (layoutSize == null) {
      layoutSize = size;
    } else if (layoutSize != size && closeOnResize) {
      // If the size has changed,close the popup
      Popup.closeAll();
    }

    bool hasArrow = hasChild(_ListPopupLayoutElement.arrow);
    Size arrowSize = Size.zero;
    if (hasArrow) {
      arrowSize = layoutChild(
        _ListPopupLayoutElement.arrow,
        BoxConstraints.loose(size),
      );
    }

    Size bodySize = layoutChild(
      _ListPopupLayoutElement.body,
      width == null
          ? const BoxConstraints()
          : BoxConstraints.tightFor(width: width),
    );

    Offset bodyPosition = _computeBodyPosition(direction, bodySize);
    bestDirection = direction;
    Offset vector = direction.offsetVector;

    if (_isOutOf(bodyPosition, bodySize, size, arrowSize)) {
      if (fallbackDirections == null) {
        // special case where we shift the position to fit.

        // Shift vertical if we overflow the bottom.
        if (bodyPosition.dy + bodySize.height >
            size.height - arrowSize.height - _edgePad) {
          bodyPosition = Offset(
              bodyPosition.dx,
              bodyPosition.dy -
                  (bodyPosition.dy +
                      bodySize.height -
                      (size.height - arrowSize.height - _edgePad)));
        }

        // Move down if we underflow top of screen.
        if (bodyPosition.dy < arrowSize.height / 2 + _edgePad) {
          bodyPosition =
              Offset(bodyPosition.dx, arrowSize.height / 2 + _edgePad);
        }

        // Fix horizontal if we overflow to the right.
        if (bodyPosition.dx + bodySize.width >
            size.width - arrowSize.width - _edgePad) {
          bodyPosition =
              Offset(bodyPosition.dx - width - from.width, bodyPosition.dy);
        }
      } else {
        // Our ideal failed, try the fallbacks.
        for (final alternativeDirection in fallbackDirections) {
          bodyPosition = _computeBodyPosition(alternativeDirection, bodySize);
          vector = alternativeDirection.offsetVector;
          bestDirection = alternativeDirection;
          if (!_isOutOf(bodyPosition, bodySize, size, arrowSize)) {
            // this fallback is good
            break;
          }
        }
      }
    }

    if (hasArrow) {
      positionChild(
          _ListPopupLayoutElement.arrow,
          _wholePixels(from.topLeft +
              // Align to center of the area of interest
              Alignment.center.alongSize(from.size) +
              // Apply any implementation specific offset (we need to do this
              // both for the arrow and the body so the arrow lines up with the
              // body if it is shifted).
              offset +
              // Apply any directional padding.
              (vector * directionPadding) +
              // Center the arrow on the arrow of interest.
              Offset(
                  vector.dx * 0.5 * from.width, vector.dy * 0.5 * from.height) +
              // Apply any tweak to the centered arrow. For example, we need the
              // create popout to align to the icon in the entire popup button
              // but we use the whole popup button as the area of interest. So
              // here we can pass a simple offset to get the arrow to line up
              // with the icon.
              //
              // https://assets.rvcd.in/popup/arrow_tweak.png
              Offset(arrowTweak.dx * vector.dy.abs(),
                  arrowTweak.dy * vector.dx.abs())));

      // Move the body over by whatever space the arrow takes up.
      bodyPosition +=
          Offset(vector.dx * arrowSize.width, vector.dy * arrowSize.height);
    }

    positionChild(_ListPopupLayoutElement.body, _wholePixels(bodyPosition));
  }
}

final _pathArrowUp = Path()
  ..moveTo(-_arrowRadius, 0)
  ..lineTo(0, -_arrowRadius)
  ..lineTo(_arrowRadius, 0)
  ..close();

final _pathArrowDown = Path()
  ..moveTo(-_arrowRadius, 0)
  ..lineTo(0, _arrowRadius)
  ..lineTo(_arrowRadius, 0)
  ..close();

final _pathArrowLeft = Path()
  ..moveTo(0, -_arrowRadius)
  ..lineTo(-_arrowRadius, 0)
  ..lineTo(0, _arrowRadius)
  ..close();

final _pathArrowRight = Path()
  ..moveTo(0, -_arrowRadius)
  ..lineTo(_arrowRadius, 0)
  ..lineTo(0, _arrowRadius)
  ..close();

const double _arrowRadius = 6;

class _ArrowPathPainter extends CustomPainter {
  final Color color;

  /// This is hideous, but passing the layout delegate lets us get the computed
  /// layout direction and determine the arrow path at rendertime. Also the
  /// hideousness is self contained to this file, so no one outside of here has
  /// to ever really look at this and have their eyeballs melt off. For anyone
  /// who ventured this far:
  /// https://media.giphy.com/media/lIU7yoG72gyhq/giphy.gif
  final _ListPopupMultiLayoutDelegate layoutDelegate;

  _ArrowPathPainter(this.color, this.layoutDelegate);

  @override
  bool shouldRepaint(_ArrowPathPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.layoutDelegate != layoutDelegate ||
      layoutDelegate.bestDirection == null;

  static Path _arrowFromDirection(PopupDirection direction) {
    if (direction.offsetVector.dx == 1) {
      return _pathArrowLeft;
    } else if (direction.offsetVector.dx == -1) {
      return _pathArrowRight;
    } else if (direction.offsetVector.dy == 1) {
      return _pathArrowUp;
    }
    return _pathArrowDown;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Use the best available direction, note that now we'll propagate the
    // direction if the delegate updates without triggering a re-layout (which
    // was causing some of the issues here).
    var direction = layoutDelegate.bestDirection ?? layoutDelegate.direction;
    if (direction == null) {
      // Layout delegate hasn't updated yet.
      return;
    }
    var path = _arrowFromDirection(direction);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }
}

/// Positions the popup in the best fitting space for a global cursor
/// coordinate.
class _PositionedPopupDelegate extends SingleChildLayoutDelegate {
  final Offset position;
  final double width;
  const _PositionedPopupDelegate(this.position, this.width);

  @override
  bool shouldRelayout(_PositionedPopupDelegate oldDelegate) => false;

  @override
  Size getSize(BoxConstraints constraints) => constraints.smallest;
  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints.tightFor(width: width);

  @override
  Offset getPositionForChild(Size size, Size bodySize) {
    var bodyPosition = position;
    // Shift vertical if we overflow the bottom.
    if (bodyPosition.dy + bodySize.height > size.height - _edgePad) {
      bodyPosition = Offset(
          bodyPosition.dx,
          bodyPosition.dy -
              (bodyPosition.dy + bodySize.height - (size.height - _edgePad)));
    }

    // Move down if we underflow top of screen.
    if (bodyPosition.dy < _edgePad) {
      bodyPosition = Offset(bodyPosition.dx, _edgePad);
    }

    // Fix horizontal if we overflow to the right.
    if (bodyPosition.dx + bodySize.width > size.width - _edgePad) {
      bodyPosition = Offset(
          bodyPosition.dx -
              (bodyPosition.dx + bodySize.width - (size.width - _edgePad)),
          bodyPosition.dy);
    }
    return bodyPosition;
  }
}
