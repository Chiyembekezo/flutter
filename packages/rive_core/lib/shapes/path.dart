import 'dart:math';
import 'dart:ui' as ui;

import 'package:meta/meta.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/component_dirt.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/shapes/cubic_vertex.dart';
import 'package:rive_core/shapes/path_vertex.dart';
import 'package:rive_core/shapes/shape.dart';
import 'package:rive_core/shapes/straight_vertex.dart';
import 'package:rive_core/src/generated/shapes/path_base.dart';

export 'package:rive_core/src/generated/shapes/path_base.dart';

/// An abstract low level path that gets implemented by parametric and point
/// based paths.
abstract class Path extends PathBase {
  final Mat2D _inverseWorldTransform = Mat2D();
  final ui.Path _uiPath = ui.Path();
  ui.Path get uiPath {
    if (!_isValid) {
      _buildPath();
    }
    return _uiPath;
  }

  bool _isValid = false;

  bool get isClosed;

  Shape _shape;

  Shape get shape => _shape;

  Mat2D get pathTransform;
  Mat2D get inverseWorldTransform => _inverseWorldTransform;

  @override
  Component get timelineParent => _shape;

  @override
  bool resolveArtboard() {
    _changeShape(null);
    return super.resolveArtboard();
  }

  @override
  void visitAncestor(Component ancestor) {
    if (_shape == null && ancestor is Shape) {
      _changeShape(ancestor);
    }
  }

  void _changeShape(Shape value) {
    if (_shape == value) {
      return;
    }
    _shape?.removePath(this);
    value?.addPath(this);
    _shape = value;
  }

  @override
  void updateWorldTransform() {
    super.updateWorldTransform();
    _shape?.pathChanged(this);

    // Paths store their inverse world so that it's available for skinning and
    // other operations that occur at runtime.
    if (!Mat2D.invert(_inverseWorldTransform, worldTransform)) {
      // If for some reason the inversion fails (like we have a 0 scale) just
      // store the identity.
      Mat2D.identity(_inverseWorldTransform);
    }
  }

  @override
  void update(int dirt) {
    super.update(dirt);

    if (dirt & ComponentDirt.path != 0) {
      _buildPath();
    }
  }

  /// Subclasses should call this whenever a parameter that affects the topology
  /// of the path changes in order to allow the system to rebuild the parametric
  /// path.
  /// should @internal when supported
  void markPathDirty() {
    addDirt(ComponentDirt.path);
    _shape?.pathChanged(this);
  }

  void _invalidatePath() {
    _isValid = false;
  }

  @override
  bool addDirt(int value, {bool recurse = false}) {
    _invalidatePath();
    return super.addDirt(value, recurse: recurse);
  }

  List<PathVertex> get vertices;

  bool _buildPath() {
    _isValid = true;
    _uiPath.reset();
    List<PathVertex> pts = vertices;
    if (pts == null || pts.isEmpty) {
      return false;
    }

    List<PathVertex> renderPoints = [];
    int pl = pts.length;

    const double arcConstant = 0.55;
    const double iarcConstant = 1.0 - arcConstant;
    PathVertex previous = isClosed ? pts[pl - 1] : null;
    for (int i = 0; i < pl; i++) {
      PathVertex point = pts[i];
      switch (point.coreType) {
        case StraightVertexBase.typeKey:
          {
            StraightVertex straightPoint = point as StraightVertex;
            double radius = straightPoint.radius;
            if (radius != null && radius > 0) {
              if (!isClosed && (i == 0 || i == pl - 1)) {
                renderPoints.add(point);
                previous = point;
              } else {
                PathVertex next = pts[(i + 1) % pl];
                Vec2D prevPoint = previous is CubicVertex
                    ? previous.outPoint
                    : previous.translation;
                Vec2D nextPoint =
                    next is CubicVertex ? next.inPoint : next.translation;
                Vec2D pos = point.translation;

                Vec2D toPrev = Vec2D.subtract(Vec2D(), prevPoint, pos);
                double toPrevLength = Vec2D.length(toPrev);
                toPrev[0] /= toPrevLength;
                toPrev[1] /= toPrevLength;

                Vec2D toNext = Vec2D.subtract(Vec2D(), nextPoint, pos);
                double toNextLength = Vec2D.length(toNext);
                toNext[0] /= toNextLength;
                toNext[1] /= toNextLength;

                double renderRadius =
                    min(toPrevLength, min(toNextLength, radius));

                Vec2D translation =
                    Vec2D.scaleAndAdd(Vec2D(), pos, toPrev, renderRadius);
                renderPoints.add(CubicVertex()
                  ..translation = translation
                  ..inPoint = translation
                  ..outPoint = Vec2D.scaleAndAdd(
                      Vec2D(), pos, toPrev, iarcConstant * renderRadius));
                translation =
                    Vec2D.scaleAndAdd(Vec2D(), pos, toNext, renderRadius);
                previous = CubicVertex()
                  ..translation = translation
                  ..inPoint = Vec2D.scaleAndAdd(
                      Vec2D(), pos, toNext, iarcConstant * renderRadius)
                  ..outPoint = translation;
                renderPoints.add(previous);
              }
            } else {
              renderPoints.add(point);
              previous = point;
            }
            break;
          }
        default:
          renderPoints.add(point);
          previous = point;
          break;
      }
    }
    PathVertex firstPoint = renderPoints[0];
    _uiPath.moveTo(firstPoint.translation[0], firstPoint.translation[1]);
    for (int i = 0,
            l = isClosed ? renderPoints.length : renderPoints.length - 1,
            pl = renderPoints.length;
        i < l;
        i++) {
      PathVertex point = renderPoints[i];
      PathVertex nextPoint = renderPoints[(i + 1) % pl];
      Vec2D cin = nextPoint is CubicVertex ? nextPoint.inPoint : null;
      Vec2D cout = point is CubicVertex ? point.outPoint : null;
      if (cin == null && cout == null) {
        _uiPath.lineTo(nextPoint.translation[0], nextPoint.translation[1]);
      } else {
        cout ??= point.translation;
        cin ??= nextPoint.translation;

        _uiPath.cubicTo(cout[0], cout[1], cin[0], cin[1],
            nextPoint.translation[0], nextPoint.translation[1]);
      }
    }

    if (isClosed) {
      _uiPath.close();
    }

    return true;
  }

  @override
  bool validate() => _shape != null;
}
