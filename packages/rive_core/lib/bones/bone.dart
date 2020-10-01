import 'package:rive_core/container_component.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/src/generated/bones/bone_base.dart';
export 'package:rive_core/src/generated/bones/bone_base.dart';

typedef bool BoneCallback(Bone bone);

class Bone extends BoneBase {
  // -> editor-only
  @override
  String get defaultName {
    int boneIndex = 0;
    var parentBone = parent;
    while (parentBone is Bone) {
      boneIndex++;
      parentBone = parentBone.parent;
    }
    return 'Bone $boneIndex';
  }
  // <- editor-only

  @override
  void lengthChanged(double from, double to) {
    for (final child in children) {
      if (child.coreType == BoneBase.typeKey) {
        (child as Bone).markTransformDirty();
      }
    }
    // -> editor-only
    markBoundsChanged();
    // <- editor-only
  }

  // -> editor-only
  @override
  void markBoundsChanged() {
    super.markBoundsChanged();
    recomputeParentNodeBounds();
  }

  // Recompute node bounds when parents change, for Node UX. If we keep duping
  // this code (currently in Drawable and here) we may want to just stick this
  // in Component...
  @override
  void parentChanged(ContainerComponent from, ContainerComponent to) {
    super.parentChanged(from, to);

    // Let any old node parent know it needs to re-compute its bounds. Let new
    // node parents know they need to recompute their bounds.
    from?.recomputeParentNodeBounds();
    to?.recomputeParentNodeBounds();
  }
  // <- editor-only

  Bone get firstChildBone {
    for (final child in children) {
      if (child.coreType == BoneBase.typeKey) {
        return child as Bone;
      }
    }
    return null;
  }

  /// Iterate through the child bones. [BoneCallback] returns false if iteration
  /// can stop. Returns false if iteration stopped, true if it made it through
  /// the whole list.
  bool forEachBone(BoneCallback callback) {
    for (final child in children) {
      if (child.coreType == BoneBase.typeKey) {
        if (!callback(child as Bone)) {
          return false;
        }
      }
    }
    return true;
  }

  @override
  double get x => (parent as Bone).length;

  @override
  set x(double value) {
    throw UnsupportedError('not expected to set x on a bone.');
  }

  @override
  double get y => 0;

  @override
  set y(double value) {
    throw UnsupportedError('not expected to set y on a bone.');
  }

  // -> editor-only
  Vec2D get tipWorldTranslation {
    var tip = Vec2D();
    Vec2D.transformMat2D(tip, Vec2D.fromValues(length, 0), worldTransform);
    return tip;
  }

  Mat2D get tipWorldTransform => Mat2D.multiply(Mat2D(), worldTransform,
      Mat2D.fromTranslation(Vec2D.fromValues(length, 0)));

  // <- editor-only
}
