import 'dart:collection';
import 'dart:math';
import 'dart:ui';

import 'package:rive_core/component.dart';
import 'package:rive_core/math/aabb.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/node.dart';
import 'package:rive_core/shapes/path_vertex.dart';
import 'package:rive_core/shapes/cubic_mirrored_vertex.dart';
import 'package:rive_core/shapes/cubic_asymmetric_vertex.dart';
import 'package:rive_core/transform_component.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';
import 'package:rive_editor/rive/stage/items/stage_artboard.dart';
import 'package:rive_editor/rive/stage/items/stage_control_vertex.dart';
import 'package:rive_editor/rive/stage/items/stage_node.dart';
import 'package:rive_editor/rive/stage/items/stage_shape.dart';
import 'package:rive_editor/rive/stage/items/stage_vertex.dart';
import 'package:rive_editor/rive/stage/snapper.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/rive/stage/tools/pen_tool.dart';
import 'package:rive_editor/rive/stage/tools/stage_tool_tip.dart';
import 'package:rive_editor/rive/stage/tools/transformers/stage_transformer.dart';
import 'package:rive_editor/rive/stage/tools/transforming_tool.dart';

/// Transformer that translates [StageItem]'s with underlying [Node] components.
class PathVertexTranslateTransformer extends StageTransformer {
  PathVertexTranslateTransformer({this.lockRotationShortcut});

  Iterable<StageVertex<PathVertex>> _stageVertices;
  final HashMap<StageControlVertex, double> _startingAngles =
      HashMap<StageControlVertex, double>();

  // Locks rotation to 45 degree increments
  final StatefulShortcutAction<bool> lockRotationShortcut;
  // Are we locked to 45 increments?
  bool _rotationLocked = false;

  @override
  void advance(DragTransformDetails details) {
    // First attempt to handle rotation locking; only makes sense is one vertex
    // is selected and it is an in or out control point. This is hideous, but it
    // works ...
    if (_stageVertices.length == 1 &&
        _stageVertices.first is StageControlVertex) {
      final controlVertex = _stageVertices.first as StageControlVertex;
      final vertex = controlVertex.vertex;
      final worldPosition =
          details?.world?.current ?? controlVertex.stage.worldMouse;
      // If rotation is locked, contrain to the locking axes
      if (_rotationLocked) {
        final lockAxis = LockAxis(vertex.worldTranslation,
            _calculateLockAxis(worldPosition, vertex.worldTranslation));

        controlVertex.worldTranslation =
            lockAxis.translateToAxis(worldPosition);
      } else {
        // Just peg to the world mouse; need to do this otherwise the point will
        // not coincide with the mouse location after a lock has been started
        // and then released
        controlVertex.worldTranslation = worldPosition;
      }
      return;
    }

    if (details == null) {
      return;
    }
    final delta = details.world.delta;
    for (final stageVertex in _stageVertices) {
      stageVertex.worldTranslation =
          Vec2D.add(Vec2D(), stageVertex.worldTranslation, delta);
    }
  }

  @override
  void complete() {
    for (final stageVertex in _stageVertices) {
      if (stageVertex is StageControlVertex) {
        stageVertex.component.accumulateAngle = false;
      }
    }
    _stageVertices = [];
    lockRotationShortcut?.removeListener(_advanceWithRotationLock);
  }

  @override
  bool init(Set<StageItem> items, DragTransformDetails details) {
    print("Init PathVertexTranslateTransformer");
    var valid = _stageVertices = <StageVertex<PathVertex>>[];
    var vertices = items.whereType<StageVertex<PathVertex>>().toSet();
    for (final stageVertex in vertices) {
      if (stageVertex is StageControlVertex) {
        var vertex = stageVertex.component;
        if (
            // Does the operation contain the vertex this control point belongs
            // to? If so, exclude it as translating the vertex moves the control
            // points.
            vertices.contains(vertex.stageItem) ||
                // If the sibling is in the selection set, neither of them move.
                ((vertex.coreType == CubicMirroredVertexBase.typeKey ||
                        vertex.coreType == CubicAsymmetricVertexBase.typeKey) &&
                    vertices.contains(stageVertex.sibling))) {
          continue;
        }
      }

      if (stageVertex is StageControlVertex) {
        stageVertex.component.accumulateAngle = true;
        _startingAngles[stageVertex] = stageVertex.angle;
      }
      valid.add(stageVertex);
    }

    lockRotationShortcut?.addListener(_advanceWithRotationLock);

    // -----> testing out snapper stuff
    if (_stageVertices != null && _stageVertices.isNotEmpty) {
      _stageVertices.first.component.stageItem.stage.snapper
          .add(_stageVertices.map((sv) => _VertexSnappingItem(sv.component)),
              (item, exclusion) {
        if (exclusion.contains(item)) {
          return false;
        }
        // Filter out components that are not shapes or nodes, or not in the
        // active artboard
        final activeArtboard = details.artboard;
        if (item is StageShape || item is StageNode || item is StageArtboard) {
          final itemArtboard = (item.component as Component).artboard;
          return activeArtboard == itemArtboard;
        }
        return false;
      });
    }

    // -----> testing out snapper stuff

    return valid.isNotEmpty;
  }

  static final Paint strokeOuter = Paint()
    ..style = PaintingStyle.stroke
    // Stroke is 3 so 1.5 sticks out when we draw fill over it.
    ..strokeWidth = 3
    ..color = const Color(0x26000000);
  static final Paint strokeInner = Paint()
    ..style = PaintingStyle.stroke
    // Stroke is 3 so 1.5 sticks out when we draw fill over it.
    ..strokeWidth = 1
    ..color = const Color(0xFFFFF1BE);
  static final Paint fill = Paint()..color = const Color(0x80FFF1BE);

  final _tip = StageToolTip();

  @override
  void draw(Canvas canvas) {
    for (final stageVertex in _stageVertices) {
      if (stageVertex is StageControlVertex) {
        var stage = stageVertex.stage;
        var vertexStageItem = stageVertex.component.stageItem as StageVertex;
        canvas.save();

        // canvas.transform(stage.inverseViewTransform.mat4);
        var screenTranslation = Vec2D.transformMat2D(
            Vec2D(), vertexStageItem.worldTranslation, stage.viewTransform);
        canvas.translate(screenTranslation[0].roundToDouble() + 0.5,
            screenTranslation[1].roundToDouble() + 0.5);
        double radius = 20;
        var rect = Rect.fromLTRB(-radius, -radius, radius, radius);

        var startingAngle = _startingAngles[stageVertex];
        var endingAngle = stageVertex.angle;

        var sweep = endingAngle - startingAngle;

        if (sweep < 0) {
          var s = startingAngle;
          startingAngle = endingAngle;
          endingAngle = s;
          sweep = endingAngle - startingAngle;
        }

        var loops = (sweep / (pi * 2)).abs().floor();
        for (var i = 0; i < loops; i++) {
          canvas.drawOval(rect, fill);
        }

        _tip.text = 'Length ${stageVertex.length.round()}\n'
            'Angle ${(stageVertex.angle / pi * 180).round()}°';

        canvas.drawArc(rect, startingAngle,
            (endingAngle - startingAngle) % (pi * 2), true, fill);
        canvas.drawOval(rect, strokeOuter);
        canvas.drawOval(rect, strokeInner);
        canvas.restore();

        _tip.paint(
            canvas, Offset(stage.localMouse.dx + 10, stage.localMouse.dy + 10));
      }
    }
  }

  void _advanceWithRotationLock() {
    _rotationLocked = lockRotationShortcut.value;
    advance(null);
  }
}

/// Calculates the quadrant in which the world mouse is with reference to the
/// previous vertex
Vec2D _calculateLockAxis(Vec2D position, Vec2D origin) {
  var diff = Vec2D.subtract(Vec2D(), position, origin);

  var angle = atan2(diff[1], diff[0]);
  // 45 degree increments
  var lockInc = pi / 4;
  var lockAngle = (angle / lockInc).round() * lockInc;
  return Vec2D.fromValues(cos(lockAngle), sin(lockAngle));
}

class _VertexSnappingItem extends SnappingItem {
  final PathVertex vertex;
  final Mat2D toParent;
  final Vec2D worldTranslation;

  factory _VertexSnappingItem(PathVertex v) {
    final artboard = v.artboard;

    final world = artboard.transform(v.parent is TransformComponent
        ? (v.parent as TransformComponent).worldTransform
        : Mat2D());
    var inverse = Mat2D();
    if (!Mat2D.invert(inverse, world)) {
      return null;
    }
    return _VertexSnappingItem._(
      v,
      inverse,
      Mat2D.getTranslation(
        artboard.transform(Mat2D()),
        Vec2D(),
      ),
    );
  }

  _VertexSnappingItem._(this.vertex, this.toParent, this.worldTranslation);
  @override
  void addSources(SnappingAxes snap, bool isSingleSelection) =>
      snap.addVec(AABB.center(Vec2D(), stageItem.aabb));

  @override
  StageItem get stageItem => vertex.stageItem;

  @override
  void translateWorld(Vec2D diff) {
    var world = Vec2D.add(Vec2D(), worldTranslation, diff);
    var local = Vec2D.transformMat2D(Vec2D(), world, toParent);
    vertex.x = local[0];
    vertex.y = local[1];
  }
}
