import 'dart:ui';
import 'package:rive/src/rive_core/bounds_delegate.dart';
import 'package:rive/src/rive_core/component.dart';
import 'package:rive/src/rive_core/component_dirt.dart';
import 'package:rive/src/rive_core/math/aabb.dart';
import 'package:rive/src/rive_core/math/mat2d.dart';
import 'package:rive/src/rive_core/shapes/paint/fill.dart';
import 'package:rive/src/rive_core/shapes/paint/linear_gradient.dart' as core;
import 'package:rive/src/rive_core/shapes/paint/shape_paint_mutator.dart';
import 'package:rive/src/rive_core/shapes/paint/stroke.dart';
import 'package:rive/src/rive_core/shapes/path.dart';
import 'package:rive/src/rive_core/shapes/path_composer.dart';
import 'package:rive/src/rive_core/shapes/shape_paint_container.dart';
import 'package:rive/src/generated/shapes/shape_base.dart';
export 'package:rive/src/generated/shapes/shape_base.dart';

class Shape extends ShapeBase with ShapePaintContainer {
  final Set<Path> paths = {};
  bool _wantWorldPath = false;
  bool _wantLocalPath = false;
  bool get wantWorldPath => _wantWorldPath;
  bool get wantLocalPath => _wantLocalPath;
  bool _fillInWorld = false;
  bool get fillInWorld => _fillInWorld;
  PathComposer _pathComposer;
  PathComposer get pathComposer => _pathComposer;
  set pathComposer(PathComposer value) {
    if (_pathComposer == value) {
      return;
    }
    _pathComposer = value;
    transformAffectsStrokeChanged();
  }

  AABB _worldBounds;
  AABB _localBounds;
  BoundsDelegate _delegate;
  @override
  AABB get worldBounds => _worldBounds ??= computeWorldBounds();
  @override
  AABB get localBounds => _localBounds ??= computeLocalBounds();
  void markBoundsDirty() {
    _worldBounds = _localBounds = null;
    _delegate?.boundsChanged();
    for (final path in paths) {
      path.markBoundsDirty();
    }
  }

  @override
  void childAdded(Component child) {
    super.childAdded(child);
    switch (child.coreType) {
      case FillBase.typeKey:
        addFill(child as Fill);
        break;
      case StrokeBase.typeKey:
        addStroke(child as Stroke);
        break;
    }
  }

  @override
  void childRemoved(Component child) {
    super.childRemoved(child);
    switch (child.coreType) {
      case FillBase.typeKey:
        removeFill(child as Fill);
        break;
      case StrokeBase.typeKey:
        removeStroke(child as Stroke);
        break;
    }
  }

  bool addPath(Path path) {
    transformAffectsStrokeChanged();
    return paths.add(path);
  }

  void pathChanged(Path path) {
    _pathComposer?.addDirt(ComponentDirt.path);
  }

  void transformAffectsStrokeChanged() {
    addDirt(ComponentDirt.path);
    _pathComposer?.addDirt(ComponentDirt.path);
  }

  @override
  bool addStroke(Stroke stroke) {
    transformAffectsStrokeChanged();
    return super.addStroke(stroke);
  }

  @override
  bool removeStroke(Stroke stroke) {
    transformAffectsStrokeChanged();
    return super.removeStroke(stroke);
  }

  @override
  void update(int dirt) {
    super.update(dirt);
    if (dirt & ComponentDirt.paint != 0) {
      for (final fill in fills) {
        fill.blendMode = blendMode;
      }
      for (final stroke in strokes) {
        stroke.blendMode = blendMode;
      }
    }
    if (dirt & ComponentDirt.worldTransform != 0) {
      for (final fill in fills) {
        fill.renderOpacity = renderOpacity;
      }
      for (final stroke in strokes) {
        stroke.renderOpacity = renderOpacity;
      }
    }
    if (dirt & ComponentDirt.path != 0) {
      _wantWorldPath = false;
      _wantLocalPath = false;
      for (final stroke in strokes) {
        if (stroke.transformAffectsStroke) {
          _wantLocalPath = true;
        } else {
          _wantWorldPath = true;
        }
      }
      _fillInWorld = _wantWorldPath || !_wantLocalPath;
      var mustFillLocal = fills.firstWhere(
              (fill) => fill.paintMutator is core.LinearGradient,
              orElse: () => null) !=
          null;
      if (mustFillLocal) {
        _fillInWorld = false;
        _wantLocalPath = true;
      }
      for (final fill in fills) {
        var mutator = fill.paintMutator;
        if (mutator is core.LinearGradient) {
          mutator.paintsInWorldSpace = _fillInWorld;
        }
      }
      for (final stroke in strokes) {
        var mutator = stroke.paintMutator;
        if (mutator is core.LinearGradient) {
          mutator.paintsInWorldSpace = !stroke.transformAffectsStroke;
        }
      }
    }
  }

  bool removePath(Path path) {
    transformAffectsStrokeChanged();
    return paths.remove(path);
  }

  AABB computeWorldBounds() {
    if (paths.isEmpty) {
      return AABB.fromMinMax(worldTranslation, worldTranslation);
    }
    var path = paths.first;
    var renderPoints = path.renderVertices;
    if (renderPoints.isEmpty) {
      return AABB.fromMinMax(worldTranslation, worldTranslation);
    }
    AABB worldBounds =
        path.preciseComputeBounds(renderPoints, path.pathTransform);
    for (final path in paths.skip(1)) {
      var renderPoints = path.renderVertices;
      AABB.combine(worldBounds, worldBounds,
          path.preciseComputeBounds(renderPoints, path.pathTransform));
    }
    return worldBounds;
  }

  AABB computeLocalBounds() {
    if (paths.isEmpty) {
      return AABB();
    }
    var path = paths.first;
    var renderPoints = path.renderVertices;
    if (renderPoints.isEmpty) {
      return AABB();
    }
    var toShapeTransform = Mat2D();
    if (!Mat2D.invert(toShapeTransform, worldTransform)) {
      Mat2D.identity(toShapeTransform);
    }
    AABB localBounds = path.preciseComputeBounds(renderPoints,
        Mat2D.multiply(Mat2D(), toShapeTransform, path.pathTransform));
    for (final path in paths.skip(1)) {
      var renderPoints = path.renderVertices;
      AABB.combine(
          localBounds,
          localBounds,
          path.preciseComputeBounds(renderPoints,
              Mat2D.multiply(Mat2D(), toShapeTransform, path.pathTransform)));
    }
    return localBounds;
  }

  @override
  void userDataChanged(dynamic from, dynamic to) {
    if (to is BoundsDelegate) {
      _delegate = to;
    } else {
      _delegate = null;
    }
  }

  @override
  void blendModeValueChanged(int from, int to) => _markBlendModeDirty();
  @override
  void draw(Canvas canvas) {
    assert(_pathComposer != null);
    var path = _pathComposer.fillPath;
    assert(path != null, 'path should\'ve been generated by the time we draw');
    if (!_fillInWorld) {
      canvas.save();
      canvas.transform(worldTransform.mat4);
    }
    for (final fill in fills) {
      fill.draw(canvas, path);
    }
    if (!_fillInWorld) {
      canvas.restore();
    }
    for (final stroke in strokes) {
      var transformAffectsStroke = stroke.transformAffectsStroke;
      var path = transformAffectsStroke
          ? _pathComposer.localPath
          : _pathComposer.worldPath;
      if (transformAffectsStroke) {
        canvas.save();
        canvas.transform(worldTransform.mat4);
        stroke.draw(canvas, path);
        canvas.restore();
      } else {
        stroke.draw(canvas, path);
      }
    }
  }

  void _markBlendModeDirty() => addDirt(ComponentDirt.paint);
  @override
  void onPaintMutatorChanged(ShapePaintMutator mutator) {
    transformAffectsStrokeChanged();
    _markBlendModeDirty();
  }

  @override
  void onStrokesChanged() {
    transformAffectsStrokeChanged();
    _markBlendModeDirty();
  }

  @override
  void onFillsChanged() {
    transformAffectsStrokeChanged();
    _markBlendModeDirty();
  }
}
