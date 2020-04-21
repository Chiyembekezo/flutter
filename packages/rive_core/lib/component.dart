import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:rive_core/animation/animation.dart';
import 'package:rive_core/animation/keyframe.dart';
import 'package:rive_core/animation/keyframe_double.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_core/rive_core_field_type.dart';
import 'package:rive_core/rive_file.dart';
import 'package:utilities/dependency_sorter.dart';

import 'src/generated/component_base.dart';

export 'src/generated/component_base.dart';

final log = Logger('rive_core');

abstract class Component extends ComponentBase<RiveFile>
    implements DependencyGraphNode<Component> {
  Artboard _artboard;
  dynamic _userData;

  // Used during update process.
  int graphOrder = 0;
  int dirt = 0;

  // This is really only for sanity and earlying out of recursive loops.
  static const int maxTreeDepth = 5000;

  bool addDirt(int value, {bool recurse = false}) {
    if ((dirt & value) == value) {
      // Already marked.
      return false;
    }

    // Make sure dirt is set before calling anything that can set more dirt.
    dirt |= value;

    onDirty(dirt);
    artboard?.onComponentDirty(this);

    if (!recurse) {
      return true;
    }

    for (final d in dependents) {
      d.addDirt(value, recurse: recurse);
    }
    return true;
  }

  void onDirty(int mask) {}
  void update(int dirt);

  /// The artboard this component belongs to.
  Artboard get artboard => _artboard;

  // Note that this isn't a setter as we don't want anything externally changing
  // the artboard.
  void _changeArtboard(Artboard value) {
    if (_artboard == value) {
      return;
    }
    _artboard?.removeComponent(this);
    _artboard = value;
    _artboard?.addComponent(this);
  }

  /// Called whenever we're resolving the artboard, we piggy back on that
  /// process to visit ancestors in the tree. This is a good opportunity to
  /// check if we have an ancestor of a specific type. For example, a Path needs
  /// to know which Shape it's within.
  void visitAncestor(Component ancestor) {}

  /// Find the artboard in the hierarchy.
  bool resolveArtboard() {
    int sanity = maxTreeDepth;
    for (Component curr = this;
        curr != null && sanity > 0;
        curr = curr.parent, sanity--) {
      visitAncestor(curr);
      if (curr is Artboard) {
        _changeArtboard(curr);
        return true;
      }
    }
    _changeArtboard(null);
    return false;
  }

  dynamic get userData => _userData;
  set userData(dynamic value) {
    if (value == _userData) {
      return;
    }
    dynamic last = _userData;
    _userData = value;
    userDataChanged(last, value);
  }

  void userDataChanged(dynamic from, dynamic to) {}

  @override
  void parentIdChanged(Id from, Id to) {
    super.parentIdChanged(from, to);
    parent = context?.resolve(to);
  }

  @override
  void childOrderChanged(FractionalIndex from, FractionalIndex to) {
    super.childOrderChanged(from, to);

    if (parent != null) {
      // Let the context know that our parent needs to be re-sorted.
      context?.markChildSortDirty(parent);
    }
  }

  ContainerComponent _parent;
  ContainerComponent get parent => _parent;
  set parent(ContainerComponent value) {
    if (_parent == value) {
      return;
    }
    var old = _parent;
    _parent = value;
    parentId = value?.id;
    parentChanged(old, value);
  }

  @protected
  void parentChanged(ContainerComponent from, ContainerComponent to) {
    if (from != null) {
      from.children.remove(this);
      from.childRemoved(this);
    }
    if (to != null) {
      to.children.add(this);
      to.childAdded(this);
    }
    // We need to resolve our artboard.
    markDependenciesDirty();
  }

  /// Components that depend on this component.
  final Set<Component> _dependents = {};

  /// Components that this component depends on.
  final Set<Component> _dependsOn = {};

  @override
  Set<Component> get dependents => _dependents;

  bool addDependent(Component dependent) {
    assert(dependent != null, "Dependent cannot be null.");
    assert(artboard == dependent.artboard,
        "Components must be in the same artboard.");

    if (!_dependents.add(dependent)) {
      return false;
    }
    dependent._dependsOn.add(this);
    markRebuildDependentIds();
    return true;
  }

  void markRebuildDependentIds() {
    context?.markDependentIdsDirty(this);
  }

  bool isValidParent(Component parent) => parent is ContainerComponent;

  void markDependenciesDirty() {
    if (context == null || !context.markDependenciesDirty(this)) {
      // no context, or already dirty.
      return;
    }
    for (final dependent in _dependents) {
      dependent.markDependenciesDirty();
    }
  }

  @mustCallSuper
  void buildDependencies() {
    for (final parentDep in _dependsOn) {
      parentDep._dependents.remove(this);
      parentDep.markRebuildDependentIds();
    }
    _dependsOn.clear();
    // by default a component depends on nothing (likely it will depend on the
    // parent but we leave that for specific implementations to supply).
  }

  /// Something we depend on has been removed. It's important to clear out any
  /// stored references to that dependency so it can be garbage collected (if
  /// necessary).
  void onDependencyRemoved(Component dependent) {}

  @override
  void onAdded() {}

  @override
  void onAddedDirty() {
    if (parentId != null) {
      parent = context?.resolve(parentId);
      if (parent == null) {
        log.finest("Failed to resolve parent with id $parentId");
      }
    }
  }

  /// When a component has been removed from the Core Context, we clean up any
  /// dangling references left on the parent and on any other dependent
  /// component. It's important for specialization of Component to respond to
  /// override [onDependencyRemoved] and clean up any further stored references
  /// to that component (for example the target of a Constraint).
  @override
  @mustCallSuper
  void onRemoved() {
    for (final parentDep in _dependsOn) {
      parentDep._dependents.remove(this);
    }
    _dependsOn.clear();

    for (final dependent in _dependents) {
      dependent.onDependencyRemoved(this);
    }
    _dependents.clear();

    // silently clear from the parent in order to not cause any further undo
    // stack changes
    if (parent != null) {
      parent.children.remove(this);
      parent.childRemoved(this);
    }

    // The artboard containing this component will need it's dependencies
    // re-sorted.
    if (artboard != null) {
      context?.markDependencyOrderDirty(artboard);
      _changeArtboard(null);
    }
  }

  @override
  String toString() {
    return '${super.toString()} ($id)';
  }

  /// Remove this component from the core system. This will unregister the
  /// component with the core context which does the work of synchronizing the
  /// removal from the system and then calling [onRemoved] on the Component when
  /// it's safe to clean up references to parents and anything that depends on
  /// this component.
  void remove() => context?.remove(this);

  T makeKeyFrame<T extends KeyFrame>(int propertyKey) {
    var coreType = context.coreType(propertyKey);
    if (coreType is KeyFrameGenerator<T>) {
      return (coreType as KeyFrameGenerator<T>).makeKeyFrame();
    }
    return null;
  }

  T addKeyFrame<T extends KeyFrame>(
      Animation animation, int propertyKey, int time) {
    assert(hasProperty(propertyKey),
        '$this doesn\'t store a property with key $propertyKey');
    var keyedObject = animation.getKeyed(this);
    keyedObject ??= animation.makeKeyed(this);

    var property = keyedObject.getKeyed(propertyKey);
    property ??= keyedObject.makeKeyed(propertyKey);

    var keyFrameIndex = property.indexOfFrame(time);

    if (keyFrameIndex == 0) {
      // add to start
    } else if (keyFrameIndex < property.numFrames) {
      // might match a frame
      KeyFrame frame = property.getFrameAt(keyFrameIndex);
      if (frame.time == time) {
        // already have a frame at this time, return it.
        assert(frame is T);
        return frame as T;
      } else {
        // insert after index-1, before index
      }
    } else {
      // add to end
    }
    return null;
  }

  KeyFrameDouble addKeyFrameDouble(
      Animation animation, int propertyKey, int time) {}
}
