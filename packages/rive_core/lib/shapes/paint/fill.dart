import 'package:flutter/material.dart';
import 'package:rive_core/component_dirt.dart';
import 'package:rive_core/shapes/shape_paint_container.dart';
import 'package:rive_core/src/generated/shapes/paint/fill_base.dart';
export 'package:rive_core/src/generated/shapes/paint/fill_base.dart';

/// A fill Shape painter.
class Fill extends FillBase {
  @override
  Paint makePaint() => Paint()..style = PaintingStyle.fill;

  PathFillType get fillType => PathFillType.values[fillRule];
  set fillType(PathFillType type) => fillRule = type.index;

  @override
  void fillRuleChanged(int from, int to) {
    parent?.addDirt(ComponentDirt.paint);
  }

  @override
  void update(int dirt) {
    // Intentionally empty, fill doesn't update.
    // Because Fill never adds dependencies, it'll also never get called.
  }

  @override
  void onAdded() {
    super.onAdded();
    if (parent is ShapePaintContainer) {
      (parent as ShapePaintContainer).addFill(this);
    }
  }

  @override
  void draw(Canvas canvas, Path path) {
    if (!isVisible) {
      return;
    }
    path.fillType = fillType;
    canvas.drawPath(path, paint);
  }
}
