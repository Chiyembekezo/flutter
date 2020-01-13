import 'dart:math';

import 'package:flutter/rendering.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/math/aabb.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/node.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/selectable_item.dart';
import 'package:rive_editor/rive/stage/items/stage_artboard.dart';
import 'package:rive_editor/rive/stage/items/stage_node.dart';

import '../rive.dart';
import 'aabb_tree.dart';
import 'stage_item.dart';

typedef _ItemFactory = StageItem Function();

abstract class StageDelegate {
  void stageNeedsAdvance();
}

class Stage {
  static const double _minZoom = 0.1;
  static const double _maxZoom = 8.0;

  Mat2D _viewTransform = Mat2D();
  Mat2D _inverseViewTransform = Mat2D();
  Vec2D _lastMousePosition = Vec2D();
  // bool _isRightMouseDown = false;
  double _rightMouseMoveAccum = 0.0;
  Mat2D get inverseViewTransform => _inverseViewTransform;
  double _viewportWidth = 0.0, _viewportHeight = 0.0;
  Mat2D get viewTransform => _viewTransform;
  double get viewportWidth => _viewportWidth;
  double get viewportHeight => _viewportHeight;
  final List<StageItem> _visibleItems = [];
  Vec2D _viewTranslation = Vec2D();
  double _viewZoom = 1.0;
  Vec2D _viewTranslationTarget = Vec2D();
  double _viewZoomTarget = 1.0;

  StageDelegate _delegate;

  void clearDelegate(StageDelegate value) {
    if (_delegate == value) {
      _delegate = null;
    }
  }

  void delegate(StageDelegate value) {
    _delegate = value;
  }

  bool setViewport(double width, double height) {
    if (width == _viewportWidth && height == _viewportHeight) {
      return false;
    }
    _viewportWidth = width;
    _viewportHeight = height;
    markNeedsAdvance();
    return true;
  }

  void zoomTo(double x, double y, double scale) {
    scale = scale.clamp(_minZoom, _maxZoom);
    double zoomDelta = scale / this._viewZoomTarget;
    this._viewZoomTarget = scale;

    double ox = x - _viewTranslationTarget[0];
    double oy = y - _viewTranslationTarget[1];

    double ox2 = ox * zoomDelta;
    double oy2 = oy * zoomDelta;

    _viewTranslationTarget[0] += ox - ox2;
    _viewTranslationTarget[1] += oy - oy2;
    markNeedsAdvance();
  }

  void mouseWheel(double x, double y, double dx, double dy) {
    _lastMousePosition[0] = x;
    _lastMousePosition[1] = y;
    zoomTo(x, y, _viewZoomTarget - dy / 30.0);
  }

  StageItem _hover;
  void mouseMove(int button, double x, double y) {
    AABB viewAABB = obbToAABB(
        AABB.fromValues(x, y, x + 1.0, y + 1.0), _inverseViewTransform);
    // print("VI $viewAABB");
    var old = _hover;
    _hover?.select(SelectionState.none);
    _hover = null;
    visTree.query(viewAABB, (int proxyId, StageItem item) {
      _hover = item;
      return true;
    });
    _hover?.select(SelectionState.hovered);
    if (old != _hover) {
      markNeedsAdvance();
    }

    // print("HIT $hover");
    _lastMousePosition[0] = x;
    _lastMousePosition[1] = y;
  }

  void mouseDown(int button, double x, double y) {
    _lastMousePosition[0] = x;
    _lastMousePosition[1] = y;
  }

  void mouseDrag(int button, double x, double y) {
    switch (button) {
      case 2:
        double dx = (x - _lastMousePosition[0]);
        double dy = (y - _lastMousePosition[1]);

        _rightMouseMoveAccum += sqrt(dx * dx + dy * dy);
        _viewTranslationTarget[0] += dx;
        _viewTranslationTarget[1] += dy;

        _lastMousePosition[0] = x;
        _lastMousePosition[1] = y;
        markNeedsAdvance();
        break;
    }
  }

  void mouseUp(int button, double x, double y) {
    _lastMousePosition[0] = x;
    _lastMousePosition[1] = y;
    if (button == 2 && _rightMouseMoveAccum < 5) {
      // show a popup.
    }
  }

  final Set<VoidCallback> _debounce = {};

  final Rive rive;
  final RiveFile riveFile;
  // final Set<StageItem> items = {};
  final AABBTree<StageItem> visTree = AABBTree<StageItem>(padding:0);

  Stage(this.rive, this.riveFile) {
    for (final object in riveFile.objects.values) {
      initComponent(object);
    }
  }

  void markNeedsAdvance() {
    if (!_needsAdvance) {
      _needsAdvance = true;
      _delegate?.stageNeedsAdvance();
    }
  }

  /// Register a Core object with the stage.
  void initComponent(Component component) {
    var stageItemFactory = _factories[component.coreType];
    assert(stageItemFactory != null,
        "Factory shouldn't be null for component $component with type key ${component.coreType}");
    if (stageItemFactory != null) {
      var stageItem = stageItemFactory();
      if (stageItem != null && stageItem.initialize(component)) {
        component.stageItem = stageItem;
        addItem(stageItem);
      }
    }
  }

  void updateBounds(StageItem item) {
    visTree.placeProxy(item.visTreeProxy, item.aabb);
  }

  bool addItem(StageItem item) {
    assert(item != null);
    if (item.visTreeProxy != NullNode) {
      return false;
    }

    item.visTreeProxy = visTree.createProxy(item.aabb, item);
    item.addedToStage(this);
    return true;
  }

  bool removeItem(StageItem item) {
    assert(item != null);
    if (item.visTreeProxy == NullNode) {
      return false;
    }

    visTree.destroyProxy(item.visTreeProxy);
    item.visTreeProxy = NullNode;
    item.removedFromStage(this);
    return true;
  }

  void dispose() {}

  void _onFileChanged() {}

  bool get shouldAdvance => _needsAdvance || _debounce.length > 0;
  bool _needsAdvance = true;

  void advance(double elapsed) {
    for (final call in _debounce) {
      call();
    }
    _debounce.clear();

    double ds = _viewZoomTarget - _viewZoom;
    double dx = _viewTranslationTarget[0] - _viewTranslation[0];
    double dy = _viewTranslationTarget[1] - _viewTranslation[1];

    double factor = min(1.0, elapsed * 30.0);

    _needsAdvance = false;
    if (ds.abs() > 0.00001) {
      _needsAdvance = true;
      ds *= factor;
    }
    if (dx.abs() > 0.01) {
      _needsAdvance = true;
      dx *= factor;
    }
    if (dy.abs() > 0.01) {
      _needsAdvance = true;
      dy *= factor;
    }

    _viewZoom += ds;
    _viewTranslation[0] += dx;
    _viewTranslation[1] += dy;

    Mat2D view = viewTransform;
    view[0] = _viewZoom;
    view[3] = _viewZoom;
    view[4] = _viewTranslation[0];
    view[5] = _viewTranslation[1];
  }

  void paint(PaintingContext context, Offset offset, Size size) {
    Mat2D.invert(_inverseViewTransform, _viewTransform);
    var viewAABB = obbToAABB(
        AABB.fromValues(0.0, 0.0, _viewportWidth, _viewportHeight),
        _inverseViewTransform);

    visTree.query(viewAABB, (int proxyId, StageItem item) {
      _visibleItems.add(item);
      return true;
    });

    var canvas = context.canvas;
    canvas.save();
    canvas.clipRect(offset & size);
    canvas.translate(offset.dx, offset.dy);
    canvas.transform(viewTransform.mat4);

    _visibleItems.sort((StageItem a, StageItem b) => a.drawOrder - b.drawOrder);

    for (final StageItem item in _visibleItems) {
      item.paint(canvas);
    }

    canvas.restore();
  }

  final Map<int, _ItemFactory> _factories = {
    ArtboardBase.typeKey: () => StageArtboard(),
    NodeBase.typeKey: () => StageNode(),
  };

  bool debounce(VoidCallback call) {
    if (_debounce.add(call)) {
      markNeedsAdvance();
      return true;
    }
    return false;
  }

  bool cancelDebounce(VoidCallback call) => _debounce.remove(call);
}
