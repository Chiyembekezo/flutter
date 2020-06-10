library tree_widget;

import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rive_widgets/listenable_builder.dart';

import 'package:tree_widget/flat_tree_item.dart';
import 'package:tree_widget/tree_controller.dart';
import 'package:tree_widget/tree_line.dart';
import 'package:tree_widget/tree_style.dart';

typedef ChildrenFunction = List<Object> Function(Object treeItem);

typedef IsFunction = bool Function(Object treeItem);
typedef SpacingFunction = int Function(Object treeItem);
typedef TreeViewExtraPartBuilder<T> = Widget Function(
    BuildContext context, FlatTreeItem<T> item, int spaceIndex);
typedef TreeViewPartBuilder<T> = Widget Function(
    BuildContext context, FlatTreeItem<T> item, TreeStyle style);
typedef TreeViewIndexBuilder<T> = Widget Function(
    BuildContext context, int index);
typedef TreeViewDragBuilder<T> = Widget Function(
    BuildContext context, List<FlatTreeItem<T>> items, TreeStyle style);

class TreeView<T> extends StatelessWidget {
  /// The controller used to provide data and extract hierarchical information
  /// from the data items. Also used to track expanded/collapsed items.
  final TreeController<T> controller;

  /// Builder used to create the expander widget.
  final TreeViewPartBuilder<T> expanderBuilder;

  /// Builder used to create the icon widget.
  final TreeViewPartBuilder<T> iconBuilder;

  /// Builder used to create the item being draggged around the screen.
  final TreeViewDragBuilder<T> dragItemBuilder;

  /// Most items take up one unit of space. If the item takes up more than 1
  /// unit, this builder will be called for every extra unit. This allows adding
  /// extra elements to the tree row prior to the icon. Lines will be spaced
  /// accordingly. Note that extra spaces are also required to be [iconSize]
  /// dimensions.
  final TreeViewExtraPartBuilder<T> extraBuilder;

  /// Builder used to build the main content of the TreeView's item. This
  /// usually has text in it.
  final TreeViewPartBuilder<T> itemBuilder;

  /// Builder for the background of the item, return null if you don't want a
  /// background.
  final TreeViewPartBuilder<T> backgroundBuilder;

  /// Styling (colors, margins, padding) for the tree.
  final TreeStyle style;

  const TreeView({
    @required this.controller,
    @required this.expanderBuilder,
    @required this.iconBuilder,
    @required this.itemBuilder,
    this.dragItemBuilder,
    this.extraBuilder,
    this.backgroundBuilder,
    this.style = defaultTreeStyle,
  });

  @override
  Widget build(BuildContext context) {
    assert(style != null);
    var iconWidth = style.iconSize.width;
    var iconHeight = style.iconSize.height;
    var lineColor = style.lineColor;
    var propertyDashPattern = style.propertyDashPattern;
    var itemHeight = style.itemHeight;
    var padIndent = style.padIndent;
    var iconMargin = style.iconMargin;
    var inactiveOpacity = style.inactiveOpacity;

    return TreeControllerProvider<T>(
      controller: controller,
      child: SliverPadding(
        padding: EdgeInsets.only(
          left: style.padding.left,
          right: style.padding.right,
          top: style.padding.top,
          bottom: style.padding.bottom,
        ),
        sliver: ListenableBuilder(
          listenable: controller,
          builder: (context, TreeController<T> controller, _) =>
              SliverFixedExtentList(
            itemExtent: style.itemHeight,
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                var item = controller.flat[index];
                var lines = <Widget>[];
                var depth = item.depth;
                var showHorizontalLine =
                    controller.hasHorizontalLine(item.data);

                if (style.showFirstLine) {
                  depth = Int8List.fromList(
                    depth.toList(growable: true)..insert(0, 0),
                  );
                } else if (depth.isNotEmpty) {
                  depth[0] = -1;
                }
                int depthCount = depth.length;
                bool hasChildren = item.hasChildren;
                int numberOfLines = hasChildren ? depthCount - 1 : depthCount;
                bool shortLastLine = !hasChildren &&
                    (item.isLastChild ||
                        // Special case for when we're hiding the last
                        // horizontal line, we need to treat the penultimate
                        // child as the one with the short (halfed) final line.
                        (item.next.isLastChild &&
                            !controller.hasHorizontalLine(item.next.data)));
                numberOfLines--;
                double toLineCenter = iconWidth / 2;
                double offset =
                    style.expanderMargin + toLineCenter; // 20 + toLineCenter;
                double indent = iconWidth + style.padIndent;
                bool showLines = !style.hideLines;
                int dragDepth = item.dragDepth ?? 255;

                for (var i = 0; i < numberOfLines; i++) {
                  double opacity = 1.0;
                  var d = depth[i];
                  offset += indent * (d.abs() - 1);
                  if (d > 0) {
                    // var style = {left:px(offset)};
                    if (i >= dragDepth || item.isDisabled) {
                      //style.opacity = DragOpacity;
                      opacity = inactiveOpacity;
                    }
                    if (showLines) {
                      lines.add(
                        Positioned(
                          // top: -0.5,
                          // bottom: -0.5,
                          top: 0.0,
                          bottom: 0.0,
                          left: offset,
                          child: SizedBox(
                            width: 1,
                            child: TreeLine(
                              color: lineColor
                                  .withOpacity(lineColor.opacity * opacity),
                            ),
                          ),
                        ),
                      );
                    }
                  }
                  offset += indent;
                }

                var opacity = 1.0;

                var lastLineSpace =
                    numberOfLines < depth.length && numberOfLines > 0
                        ? depth[numberOfLines]
                        : 0;
                if (lastLineSpace > 0 && !(index == 0 && item.isLastChild)) {
                  bool isPropertyLine = !item.hasChildren && item.isProperty;
                  // let lastLineStyle = !item.hasChildren && item.isProperty ? styles.PropertyLine : styles.Line;
                  if (lastLineSpace > 1) {
                    offset += (lastLineSpace - 1) * indent;
                  }
                  double top = 0;
                  double bottom = shortLastLine ? itemHeight / 2 : 0;
                  // let style = {bottom:shortLastLine ? "50%" : null, left:px(offset)};

                  if (index == 0) {
                    // Correction for this case: https://cl.ly/3d300n1C2E0E where the line extends up instead we want it to look like this on the first item: https://cl.ly/2U1U3Z1h0D2D
                    top = itemHeight / 2;
                    bottom = 0;
                    // style.bottom = "0";
                  }
                  if (numberOfLines >= dragDepth || item.isDisabled) {
                    opacity = inactiveOpacity;
                    // style.opacity = DragOpacity;
                  }
                  // verticalLines.push(<div className={lastLineStyle} key={numberOfLines} style={style}></div>);
                  if (showLines && (showHorizontalLine || !item.isLastChild)) {
                    lines.add(
                      Positioned(
                        left: offset,
                        // top: top - 0.5,
                        // bottom: bottom - 0.5,
                        top: top,
                        bottom: bottom,
                        child: SizedBox(
                          width: 1,
                          child: TreeLine(
                            dashPattern: !item.hasChildren && item.isProperty
                                ? propertyDashPattern
                                : null,
                            color: lineColor
                                .withOpacity(lineColor.opacity * opacity),
                          ),
                        ),
                      ),
                    );
                  }
                }

                var spaces = -1;
                for (final s in depth) {
                  spaces += s.abs();
                }
                double spaceLeft = style.expanderMargin + spaces * indent;

                var dashing = item.isProperty ? propertyDashPattern : null;

                bool showOurLine = depth[depth.length - 1] != -1;

                var nextDragDepth = 255;
                var prevDragDepth = 255;
                bool isNextProperty = item.next?.isProperty ?? false;
                var nextDepth = item.next?.depth;
                if (dragDepth != null) {
                  if (item.prev != null) {
                    prevDragDepth = item.prev.dragDepth;
                  }
                  if (item.next != null) {
                    nextDragDepth = item.next.dragDepth;
                  }
                }

                bool dragging = numberOfLines + 2 >= dragDepth;

                double dragOpacity =
                    dragging || item.isDisabled ? inactiveOpacity : 1.0;
                double aboveDragOpacity =
                    dragging && prevDragDepth != null ? inactiveOpacity : 1.0;
                double belowDragOpacity =
                    numberOfLines + 1 >= dragDepth && nextDragDepth != null
                        ? inactiveOpacity
                        : 1.0;

                if (hasChildren) {
                  if (showLines && showOurLine && index != 0) {
                    // Example: Red connector above expander: https://cl.ly/0Z452u3b3S1z
                    // <div className={styles.ConnectorLine} style={{height:px((rowHeight-iconSize)/2), top:px(-(rowHeight-iconSize)/2-1), bottom:"initial", opacity:aboveDragOpacity}}></div>}
                    lines.insert(
                      0,
                      Positioned(
                        left: spaceLeft + iconWidth / 2,
                        top: 0.0,
                        child: SizedBox(
                          width: 1,
                          height: (itemHeight - iconHeight) / 2,
                          child: TreeLine(
                            color: lineColor.withOpacity(
                                lineColor.opacity * aboveDragOpacity),
                          ),
                        ),
                      ),
                    );
                  }
                  if (showOurLine && !item.isLastChild) {
                    // Example: Red connector under expander: https://cl.ly/473J3m462g0e
                    lines.insert(
                      0,
                      Positioned(
                        left: spaceLeft + iconWidth / 2,
                        top: itemHeight / 2 + iconHeight / 2,
                        child: SizedBox(
                          width: 1,
                          // extra 0.5 here to avoid precision errors leaving a
                          // gap
                          height: (itemHeight - iconHeight) / 2,
                          child: TreeLine(
                            color: lineColor.withOpacity(
                                lineColor.opacity * belowDragOpacity),
                          ),
                        ),
                      ),
                    );
                  }
                } else if (showLines &&
                    !(depth.length == 1 && depth[0] == -1) &&
                    showHorizontalLine) {
                  //(this.props.hideFirstHorizontalLine && depth.length === 1 && depth[0] === -1) ? null : <div className={horizontalLineStyle} style={{background:showOurLine && showLines ? null : "initial", opacity:dragOpacity}}></div>
                  lines.insert(
                    0,
                    Positioned(
                      left: spaceLeft + iconWidth / 2,
                      top: itemHeight / 2,
                      child: SizedBox(
                        width: iconWidth / 2 + padIndent - iconMargin,
                        height: 1,
                        child: TreeLine(
                          dashPattern: dashing,
                          color: lineColor
                              .withOpacity(lineColor.opacity * dragOpacity),
                        ),
                      ),
                    ),
                  );
                }

                if (item.isExpanded && showLines) {
                  // Example: https://cl.ly/1D1j2p0d1k1N connector red line below torso and head
                  // <div className={isNextProperty && nextDepth.length - depth.length === 1 ? styles.IconPropertyConnectorLine : styles.IconConnectorLine} style={{marginLeft:px(Math.floor(space*Indent+ToLineCenter)), top:px(rowHeight/2+iconHeight/2), opacity:dragOpacity}}></div> : null
                  // marginLeft:px(Math.floor(space*Indent+ToLineCenter)), top:px(rowHeight/2+iconHeight/2)
                  lines.insert(
                    0,
                    Positioned(
                      left: spaceLeft + (item.spacing * indent) + iconWidth / 2,
                      top: itemHeight / 2 + iconHeight / 2,
                      child: SizedBox(
                        width: 1,
                        height: (itemHeight - iconHeight) / 2,
                        child: TreeLine(
                          color: lineColor
                              .withOpacity(lineColor.opacity * dragOpacity),
                        ),
                      ),
                    ),
                  );
                }

                var icon = iconBuilder(
                  context,
                  item,
                  style,
                );
                return KeepAlive(
                  /// We need a KeepAlive here to make sure the input helper
                  /// stays around when it's being dragged.
                  key: item.key,
                  keepAlive: controller.dragOperation?.startItem == item,
                  child: SizedBox(
                    height: itemHeight,
                    child: Stack(
                      overflow: Overflow.visible,
                      children: <Widget>[
                        Positioned.fill(
                          top: 0,
                          child: Stack(
                            children: lines,
                            overflow: Overflow.visible,
                          ),
                        ),
                        if (backgroundBuilder != null)
                          Positioned(
                            left: 0, //indent + spaceLeft - iconMargin / 2,
                            top: 0,
                            bottom: 0,
                            right: 0,
                            child: _InputHelper<T>(
                              style: style,
                              isDragging: dragging,
                              item: item,
                              child: backgroundBuilder(context, item, style),
                              dragItemBuilder:
                                  dragItemBuilder ?? _defaultDragItemBuilder,
                            ),
                          ),
                        Positioned(
                          left: spaceLeft,
                          right: 0,
                          top: 0,
                          bottom: 0,
                          child: Opacity(
                            opacity: dragOpacity,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                ...hasChildren
                                    ? [
                                        SizedBox(
                                          width: indent,
                                          height: iconHeight,
                                          child: Padding(
                                            padding: EdgeInsets.only(
                                                right: padIndent),
                                            child: GestureDetector(
                                              onTap: () {
                                                if (item.isExpanded) {
                                                  controller
                                                      .collapse(item.data);
                                                } else {
                                                  controller.expand(item.data);
                                                }
                                              },
                                              child: expanderBuilder(
                                                context,
                                                item,
                                                style,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ]
                                    : [
                                        SizedBox(
                                          width: style.showFirstLine ||
                                                  hasChildren ||
                                                  spaces != 0
                                              ? indent
                                              : 0,
                                        )
                                      ],
                                for (int i = 0; i < item.spacing - 1; i++)
                                  Padding(
                                    padding: EdgeInsets.only(right: padIndent),
                                    child: SizedBox(
                                      width: iconWidth,
                                      height: iconHeight,
                                      child:
                                          extraBuilder?.call(context, item, i),
                                    ),
                                  ),
                                if (icon != null)
                                  Padding(
                                    padding: EdgeInsets.only(right: padIndent),
                                    child: SizedBox(
                                      width: iconWidth,
                                      height: iconHeight,
                                      child: IgnorePointer(
                                        child: icon,
                                      ),
                                    ),
                                  ),
                                itemBuilder(
                                  context,
                                  item,
                                  style,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              childCount: controller?.flat?.length ?? 0,
              findChildIndexCallback: (Key key) {
                return controller.indexLookup[key];
              },
              addRepaintBoundaries: false,
              addAutomaticKeepAlives: false,
              addSemanticIndexes: false,
            ),
          ),
        ),
      ),
    );
  }

  Widget _defaultDragItemBuilder(
      BuildContext context, List<FlatTreeItem<T>> items, TreeStyle style) {
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: items
              .map(
                (item) => Text(item.data.toString()),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _InputHelper<T> extends StatelessWidget {
  final Widget child;
  final bool isDragging;
  final FlatTreeItem<T> item;
  final TreeStyle style;
  final TreeViewDragBuilder<T> dragItemBuilder;

  const _InputHelper({
    Key key,
    this.child,
    this.isDragging,
    this.item,
    this.style,
    this.dragItemBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = TreeControllerProvider.of<T>(context);
    return IgnorePointer(
      ignoring: isDragging,
      child: MouseRegion(
        opaque: false,
        onEnter: controller.isDragging
            ? null
            : (event) {
                return controller.onMouseEnter(event, item);
              },
        onExit: (event) => controller.onMouseExit(event, item),
        child: Listener(
          onPointerDown: (event) {
            if (event.buttons == 2) {
              // Handle right click.
              controller.onRightClick(context, event, item);
            }
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => controller.onTap(item),
            onVerticalDragStart: (details) {
              var toDrag = controller.onDragStart(details, item);
              if (toDrag != null && toDrag.isNotEmpty) {
                controller.startDrag(
                    details, context, item, toDrag, dragItemBuilder, style);
              }
            },
            onVerticalDragEnd: (details) {
              controller.stopDrag();
            },
            onVerticalDragUpdate: (details) {
              controller.updateDrag(context, details, item, style);
            },
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Pass the tree controller around the widget tree
/// Trees within tress. Inception but with lumber.
class TreeControllerProvider<T> extends InheritedWidget {
  const TreeControllerProvider({
    @required this.controller,
    @required Widget child,
    Key key,
  })  : assert(child != null),
        super(key: key, child: child);

  final TreeController<T> controller;

  static TreeController<K> of<K>(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<TreeControllerProvider<K>>()
      .controller;

  @override
  bool updateShouldNotify(TreeControllerProvider<T> old) =>
      controller != old.controller;
}
