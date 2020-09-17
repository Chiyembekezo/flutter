import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A CustomScrollView that draws and hitDetects content in reverse order (top
/// to bottom). This allows items that come after to also draw after, so footers
/// can draw over the content that comes before them.
class RiveScrollView extends CustomScrollView {
  final DrawOrder drawOrder;

  const RiveScrollView({
    Key key,
    Axis scrollDirection = Axis.vertical,
    bool reverse = false,
    ScrollController controller,
    bool primary,
    ScrollPhysics physics,
    Key center,
    double anchor = 0.0,
    double cacheExtent,
    List<Widget> slivers,
    int semanticChildCount,
    DragStartBehavior dragStartBehavior = DragStartBehavior.start,
    Clip clipBehavior = Clip.hardEdge,
    this.drawOrder = DrawOrder.lifo,
  }) : super(
          key: key,
          scrollDirection: scrollDirection,
          reverse: reverse,
          controller: controller,
          primary: primary,
          physics: physics,
          shrinkWrap: false,
          center: center,
          anchor: anchor,
          cacheExtent: cacheExtent,
          semanticChildCount: semanticChildCount,
          dragStartBehavior: dragStartBehavior,
          slivers: slivers,
          clipBehavior: clipBehavior,
        );

  @override
  Widget buildViewport(
    BuildContext context,
    ViewportOffset offset,
    AxisDirection axisDirection,
    List<Widget> slivers,
  ) {
    return _RiveViewPort(
      axisDirection: axisDirection,
      offset: offset,
      slivers: slivers,
      cacheExtent: cacheExtent,
      center: center,
      anchor: anchor,
      clipBehavior: clipBehavior,
      drawOrder: drawOrder,
    );
  }
}

class _RiveViewPort extends Viewport {
  final DrawOrder drawOrder;

  _RiveViewPort({
    @required ViewportOffset offset,
    Key key,
    AxisDirection axisDirection = AxisDirection.down,
    AxisDirection crossAxisDirection,
    double anchor = 0.0,
    Key center,
    double cacheExtent,
    CacheExtentStyle cacheExtentStyle = CacheExtentStyle.pixel,
    List<Widget> slivers = const <Widget>[],
    Clip clipBehavior = Clip.hardEdge,
    this.drawOrder = DrawOrder.lifo,
  }) : super(
          key: key,
          axisDirection: axisDirection,
          crossAxisDirection: crossAxisDirection,
          anchor: anchor,
          offset: offset,
          center: center,
          cacheExtent: cacheExtent,
          cacheExtentStyle: cacheExtentStyle,
          slivers: slivers,
          clipBehavior: clipBehavior,
        );

  @override
  RenderViewport createRenderObject(BuildContext context) {
    return _RiveRenderViewport(
      axisDirection: axisDirection,
      crossAxisDirection: crossAxisDirection ??
          Viewport.getDefaultCrossAxisDirection(context, axisDirection),
      anchor: anchor,
      offset: offset,
      cacheExtent: cacheExtent,
      cacheExtentStyle: cacheExtentStyle,
      clipBehavior: clipBehavior,
      drawOrder: drawOrder,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, _RiveRenderViewport renderObject) {
    renderObject
      ..axisDirection = axisDirection
      ..crossAxisDirection = crossAxisDirection ??
          Viewport.getDefaultCrossAxisDirection(context, axisDirection)
      ..anchor = anchor
      ..offset = offset
      ..cacheExtent = cacheExtent
      ..cacheExtentStyle = cacheExtentStyle
      ..clipBehavior = clipBehavior
      ..drawOrder = drawOrder;
  }
}

enum DrawOrder { fifo, lifo }

class _RiveRenderViewport extends RenderViewport {
  DrawOrder _drawOrder;
  DrawOrder get drawOrder => _drawOrder;
  set drawOrder(DrawOrder value) {
    if (_drawOrder == value) {
      return;
    }
    _drawOrder = value;
    markNeedsPaint();
  }

  _RiveRenderViewport({
    @required AxisDirection crossAxisDirection,
    @required ViewportOffset offset,
    AxisDirection axisDirection = AxisDirection.down,
    double anchor = 0.0,
    List<RenderSliver> children,
    RenderSliver center,
    double cacheExtent,
    CacheExtentStyle cacheExtentStyle = CacheExtentStyle.pixel,
    Clip clipBehavior = Clip.hardEdge,
    DrawOrder drawOrder = DrawOrder.lifo,
  })  : _drawOrder = drawOrder,
        super(
          axisDirection: axisDirection,
          crossAxisDirection: crossAxisDirection,
          offset: offset,
          anchor: anchor,
          children: children,
          center: center,
          cacheExtent: cacheExtent,
          cacheExtentStyle: cacheExtentStyle,
          clipBehavior: clipBehavior,
        );

  @override
  bool get hasVisualOverflow =>
      clipBehavior == Clip.none || super.hasVisualOverflow;

  @override
  Iterable<RenderSliver> get childrenInHitTestOrder =>
      drawOrder == DrawOrder.lifo ? fifo : lifo;

  @override
  Iterable<RenderSliver> get childrenInPaintOrder =>
      drawOrder == DrawOrder.lifo ? lifo : fifo;

  Iterable<RenderSliver> get fifo sync* {
    if (firstChild == null) return;
    RenderSliver child = firstChild;
    while (child != center) {
      yield child;
      child = childAfter(child);
    }
    child = lastChild;
    while (true) {
      yield child;
      if (child == center) return;
      child = childBefore(child);
    }
  }

  Iterable<RenderSliver> get lifo sync* {
    if (firstChild == null) return;
    RenderSliver child = center;
    while (child != null) {
      yield child;
      child = childAfter(child);
    }
    child = childBefore(center);
    while (child != null) {
      yield child;
      child = childBefore(child);
    }
  }
}
