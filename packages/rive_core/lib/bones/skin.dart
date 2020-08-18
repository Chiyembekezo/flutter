import 'package:rive_core/bones/skeletal_component.dart';
import 'package:rive_core/bones/tendon.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_core/src/generated/bones/skin_base.dart';
export 'package:rive_core/src/generated/bones/skin_base.dart';

/// Represents a skin deformation of either a Path or an Image Mesh connected to
/// a set of bones.
class Skin extends SkinBase {
  final List<Tendon> _tendons = [];
  Iterable<Tendon> get tendons => _tendons;

  @override
  void update(int dirt) {
    // TODO: update
  }

  @override
  void buildDependencies() {
    super.buildDependencies();

    // A skin depends on all its bones and its parent (path/image).
    for (final tendon in _tendons) {
      tendon.bone.addDependent(this);
    }
    parent.addDependent(this);
  }

  @override
  void childAdded(Component child) {
    super.childAdded(child);
    switch (child.coreType) {
      case TendonBase.typeKey:
        _tendons.add(child as Tendon);
        // -> editor-only
        // clippingShapesChanged.notify();
        // <- editor-only
        break;
    }
  }

  @override
  void childRemoved(Component child) {
    super.childRemoved(child);
    switch (child.coreType) {
      case TendonBase.typeKey:
        _tendons.remove(child as Tendon);
        if (_tendons.isEmpty) {
          remove();
        }
        // -> editor-only
        // clippingShapesChanged.notify();
        // <- editor-only

        break;
    }
  }

  // -> editor-only
  static Tendon bind(SkeletalComponent bone, ContainerComponent skinnable) {
    assert(bone != null);
    assert(bone.context != null,
        'the bone needs to already have been added to core');
    var core = bone.context;
    Tendon tendon;
    core.batchAdd(
      () {
        bone.calculateWorldTransform();
        var boneWorld = bone.worldTransform;

        tendon = core.addObject(
          Tendon()
            ..boneId = bone.id
            ..xx = boneWorld[0]
            ..xy = boneWorld[1]
            ..yx = boneWorld[2]
            ..yy = boneWorld[3]
            ..tx = boneWorld[4]
            ..ty = boneWorld[5],
        );
        var skinComponent = skinnable.children
            .firstWhere((child) => child is Skin, orElse: () => null);
        Skin skin;
        if (skinComponent != null) {
          skin = skinComponent as Skin;
        } else {
          skin = core.addObject(Skin());
          skinnable.appendChild(skin);
        }

        skin.appendChild(tendon);
      },
    );
    return tendon;
  }
  // <- editor-only
}
