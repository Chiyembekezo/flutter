import 'dart:async';
import 'dart:collection';

import 'package:core/core.dart';
import 'package:core/debounce.dart';
import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';
import 'package:rive_core/animation/keyed_object.dart';
import 'package:rive_core/animation/keyed_property.dart';
import 'package:rive_core/animation/keyframe.dart';
import 'package:rive_core/animation/linear_animation.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/event.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_editor/rive/managers/animation/animation_time_manager.dart';
import 'package:rive_editor/rive/open_file_context.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/selectable_item.dart';
import 'package:rxdart/rxdart.dart';

@immutable
class KeyComponentsEvent {
  final Iterable<Component> components;
  final int propertyKey;

  const KeyComponentsEvent({
    @required this.components,
    @required this.propertyKey,
  });
}

/// Animation manager for the currently editing [LinearAnimation].
class EditingAnimationManager extends AnimationTimeManager
    with RiveFileDelegate {
  EditingAnimationManager(
    LinearAnimation animation,
    OpenFileContext activeFile, {
    this.selectedFrameStream,
    this.changeSelectedFrameStream,
  }) : super(animation, activeFile) {
    animation.context.addDelegate(this);
    _updateHierarchy();
    _keyController.stream.listen(_keyComponents);
    _mouseOverController.stream.listen(_mouseOver);
    _mouseExitController.stream.listen(_mouseExit);
    _selectController.stream.listen(_select);
    _selectMultipleController.stream.listen(_selectMultiple);
    _selectedFrameSubscription =
        selectedFrameStream.listen(_debounceSelectedFramesChanged);
  }

  StreamSubscription<HashSet<KeyFrame>> _selectedFrameSubscription;
  final ValueStream<HashSet<KeyFrame>> selectedFrameStream;
  final Sink<HashSet<KeyFrame>> changeSelectedFrameStream;

  final _componentViewModels = HashMap<Component, KeyedComponentViewModel>();
  HashMap<Component, KeyedComponentViewModel> get componentViewModels =>
      _componentViewModels;

  final _componentGroupViewModels =
      HashMap<Component, HashMap<String, KeyedGroupViewModel>>();

  final _allPropertiesHelpers = HashSet<_AllPropertiesHelper>();

  final _hierarchyController =
      BehaviorSubject<Iterable<KeyHierarchyViewModel>>();
  ValueStream<Iterable<KeyHierarchyViewModel>> get hierarchy =>
      _hierarchyController.stream;

  final _keyController = StreamController<KeyComponentsEvent>();

  final _mouseOverController = StreamController<KeyHierarchyViewModel>();
  Sink<KeyHierarchyViewModel> get mouseOver => _mouseOverController;
  final _mouseExitController = StreamController<KeyHierarchyViewModel>();
  Sink<KeyHierarchyViewModel> get mouseExit => _mouseExitController;

  final _selectController = StreamController<KeyHierarchyViewModel>();
  Sink<KeyHierarchyViewModel> get select => _selectController;
  final _selectMultipleController =
      StreamController<Iterable<KeyHierarchyViewModel>>();
  Sink<Iterable<KeyHierarchyViewModel>> get selectMultiple =>
      _selectMultipleController;

  final Event _hierarchySelectionChanged = Event();
  Listenable get hierarchySelectionChanged => _hierarchySelectionChanged;

  /// Set a keyframe on a property for a bunch of components.
  Sink<KeyComponentsEvent> get keyComponents => _keyController;

  void _keyComponents(KeyComponentsEvent event) {
    for (final component in event.components) {
      onAutoKey(component, event.propertyKey);
    }
    animation.context.captureJournalEntry();
  }

  void _mouseOver(KeyHierarchyViewModel vm) {
    if (vm is KeyedComponentViewModel) {
      var stageItem = vm.component.stageItem;
      if (stageItem != null && stageItem.stage != null) {
        stageItem.isHovered = true;
      }
    } else if (vm is KeyedPropertyViewModel) {
      vm.selection.isHovered = true;
    }
  }

  void _mouseExit(KeyHierarchyViewModel vm) {
    if (vm is KeyedComponentViewModel) {
      var stageItem = vm.component.stageItem;
      if (stageItem != null && stageItem.stage != null) {
        stageItem.isHovered = false;
      }
    } else if (vm is KeyedPropertyViewModel) {
      vm.selection.isHovered = false;
    }
  }

  void _select(KeyHierarchyViewModel vm) {
    if (vm is KeyedComponentViewModel &&
        vm.component.stageItem != null &&
        vm.component.stageItem.stage != null) {
      activeFile.select(vm.component.stageItem);
    } else if (vm is KeyedPropertyViewModel) {
      // vm.keyedProperty.keyframes
      changeSelectedFrameStream
          .add(HashSet<KeyFrame>.from(vm.keyedProperty.keyframes));
    }
  }

  void _selectMultiple(Iterable<KeyHierarchyViewModel> vms) {
    var selectStageItems = HashSet<StageItem>();
    var selectKeyFrames = HashSet<KeyFrame>();
    for (final vm in vms) {
      if (vm is KeyedComponentViewModel) {
        var item = vm.component.stageItem;
        if (item == null || item.stage == null) {
          // Some keyed components don't have stageItems (Fills)
          continue;
        }
        selectStageItems.add(item);
      } else if (vm is KeyedPropertyViewModel) {
        selectKeyFrames.addAll(vm.keyedProperty.keyframes);
      }
    }
    changeSelectedFrameStream.add(selectKeyFrames);
    activeFile.selection.selectMultiple(selectStageItems);
  }

  var _selectedProperties = HashSet<KeyedPropertyViewModel>();

  void _debounceSelectedFramesChanged(HashSet<KeyFrame> keyframes) {
    debounce(_selectedFramesChanged);
  }

  void _selectedFramesChanged() {
    var keyframes = selectedFrameStream.value;
    var core = activeFile.core;

    // First get the set of unique keyed properties (do it by ID so each
    // iteration doesn't need to do multiple core lookups). It would be three
    // core lookups per keyframe (one for the keyedPropertyId, one for the
    // keyedObjectId, and one for the objectId).
    var keyedPropertyIds = HashSet<Id>();
    for (final frame in keyframes) {
      keyedPropertyIds.add(frame.keyedPropertyId);
    }

    var selectPropertyViewModels = HashSet<KeyedPropertyViewModel>();
    for (final keyedPropertyId in keyedPropertyIds) {
      var keyedProperty = core.resolve<KeyedProperty>(keyedPropertyId);
      if (keyedProperty == null) {
        continue;
      }
      var component =
          core.resolve<Component>(keyedProperty.keyedObject.objectId);

      if (component == null) {
        continue;
      }
      var vm = _componentViewModels[component.timelineProxy];
      if (vm == null) {
        continue;
      }
      for (final child in vm.children) {
        if (child is KeyedPropertyViewModel &&
            child.keyedProperty == keyedProperty) {
          selectPropertyViewModels.add(child);
          child.selection.isSelected = true;
          break;
        }
      }
    }

    // Finally clean up previously selected items by marking them no longer
    // selected.
    for (final previouslySelected
        in _selectedProperties.difference(selectPropertyViewModels)) {
      previouslySelected.selection.isSelected = false;
    }

    _selectedProperties = selectPropertyViewModels;
  }

  @override
  void dispose() {
    for (final allHelper in _allPropertiesHelpers) {
      allHelper.reset();
    }
    for (final vm in _componentViewModels.values) {
      vm.selectionState?.removeListener(_vmSelectionStateChanged);
      for (final child in vm.children) {
        child.selectionState?.removeListener(_vmSelectionStateChanged);
      }
    }

    cancelDebounce(_updateHierarchy);
    _hierarchyController.close();
    _keyController.close();
    _mouseOverController.close();
    _mouseExitController.close();
    _selectController.close();
    _selectMultipleController.close();
    animation.context.removeDelegate(this);
    _selectedFrameSubscription.cancel();
    cancelDebounce(_selectedFramesChanged);
    super.dispose();
  }

  @override
  void onAutoKey(Component component, int propertyKey) {
    /// The stage will switch the active artboard for us, but some of these
    /// operations are debounced so there's a risk onAutoKey will call while
    /// another artboard's animation is still active so we early out here if
    /// autoKey is triggered for a property on an object that is not in the same
    /// artboard as our currently editing animation.
    if (component.artboard != animation.artboard) {
      return;
    }
    var keyFrame = component.addKeyFrame(animation, propertyKey, frame);
    // Set the value of the keyframe.
    keyFrame.valueFrom(component, propertyKey);
  }

  @override
  void onObjectAdded(Core object) {
    switch (object.coreType) {
      case KeyedObjectBase.typeKey:
      case KeyedPropertyBase.typeKey:
        debounce(_updateHierarchy);
        break;
    }
  }

  @override
  void onObjectRemoved(Core object) {
    switch (object.coreType) {
      case KeyedObjectBase.typeKey:
      case KeyedPropertyBase.typeKey:
        debounce(_updateHierarchy);
        break;
    }
  }

  void _vmSelectionStateChanged() => _hierarchySelectionChanged.notify();

  KeyedComponentViewModel _makeComponentViewModel(
    Component timelineComponent, {
    KeyedObject keyedObject,
  }) {
    KeyedComponentViewModel viewModel;
    Set<KeyHierarchyViewModel> children = {};
    final allProperties = _AllPropertiesHelper(animation);
    _allPropertiesHelpers.add(allProperties);
    _componentViewModels[timelineComponent] =
        viewModel = KeyedComponentViewModel(
      component: timelineComponent,
      keyedObject: keyedObject,
      children: children,
      allProperties: allProperties,
    );
    viewModel.selectionState?.addListener(_vmSelectionStateChanged);
    return viewModel;
  }

  void _updateHierarchy() {
    var keyedObjects = animation.keyedObjects;
    var core = animation.context;

    // Reset children.
    for (final vm in _componentViewModels.values) {
      for (final child in vm.children) {
        child.selectionState?.removeListener(_vmSelectionStateChanged);
      }
      vm.children.clear();
      // Clear component groups.
      var groups = _componentGroupViewModels[vm.component];
      if (groups != null) {
        for (final group in groups.values) {
          group.children.clear();
        }
      }
    }

    // Reset helpers.
    for (final allHelper in _allPropertiesHelpers) {
      allHelper.reset();
    }

    // First pass, build all viewmodels for keyed objects and properties, no
    // parenting yet but track which ones need to be.
    Set<KeyHierarchyViewModel> hierarchy = {};
    List<KeyedComponentViewModel> needParenting = [];
    for (final keyedObject in keyedObjects) {
      var component = core.resolve<Component>(keyedObject.objectId);
      Component timelineComponent = component?.timelineProxy;
      if (timelineComponent == null) {
        // Exclude this item from the hierarchy temporarily, maybe we're still
        // loading? This shouldn't really happen, figure out why it's happening.
        // KeyedObjects that don't resolve remove themselves, so probably the
        // animation manager is open during a reload or something.
        continue;
      }

      var viewModel = _componentViewModels[timelineComponent];
      if (viewModel == null) {
        _componentViewModels[timelineComponent] = viewModel =
            _makeComponentViewModel(timelineComponent,
                keyedObject: keyedObject);
      }

      // Build up a list of the properties that we can sort and then build into
      // viewmodels.
      var keyedProperties = keyedObject.keyedProperties;
      List<_KeyedPropertyHelper> properties =
          List<_KeyedPropertyHelper>(keyedProperties.length);
      int index = 0;
      for (final keyedProperty in keyedObject.keyedProperties) {
        properties[index++] = _KeyedPropertyHelper(
          keyedProperty: keyedProperty,
          // Properties that have the same group key will be grouped together
          // after ordering.
          groupKey: RiveCoreContext.propertyKeyGroupHashCode(
              keyedProperty.propertyKey),
          // For now use the propertyKey as the order value, if we find we
          // want to customize this further, the core generator will need to
          // provide a custom sort value that can be specified in the
          // definition files.
          propertyOrder: keyedProperty.propertyKey,
        );
      }
      // Do the first (arguably heavier as we should have less grouped
      // properties) with regular (unstable) sort.
      properties.sort((a, b) => a.propertyOrder.compareTo(b.propertyOrder));
      // Then use a stable sort to sort by group.

      // TODO: this wasn't stable, if grouped property keys do not have adjacent
      // integer values, there's a risk that they grouping won't work (below
      // groupKey != lastGroupKey). In that case we need a stable sort to run
      // here by the groupKey. mergeSort<_KeyedPropertyHelper>(properties,
      // compare: (a, b) => a.groupKey.compareTo(b.groupKey));

      // Finally we can build up the children.
      int lastGroupKey = 0;
      String groupLabel;
      for (final property in properties) {
        String displayGroupLabel;

        if (property.groupKey != 0) {
          if (property.groupKey != lastGroupKey) {
            groupLabel = RiveCoreContext.propertyKeyGroupName(
                property.keyedProperty.propertyKey);
          }
          displayGroupLabel = property.groupKey == lastGroupKey
              // Previous property had the same group key, so let's just use an
              // empty label.
              ? ''
              // Mark the label...
              : groupLabel;
        }
        var propertyKeyName =
            RiveCoreContext.propertyKeyName(property.keyedProperty.propertyKey);
        var propertyViewModel = KeyedPropertyViewModel(
          keyedProperty: property.keyedProperty,
          label: displayGroupLabel ?? propertyKeyName,
          subLabel:
              displayGroupLabel != null ? '$groupLabel.$propertyKeyName' : null,
          component: component,
          selection: SelectableItem(),
        );
        propertyViewModel.selectionState.addListener(_vmSelectionStateChanged);
        viewModel.children.add(propertyViewModel);

        // Also add it to the keyed properties, this is the first step in
        // building up the all properties.
        viewModel.allProperties.add(property.keyedProperty);

        lastGroupKey = property.groupKey;
      }

      if (timelineComponent.timelineParent == null) {
        hierarchy.add(viewModel);
      } else {
        needParenting.add(viewModel);
      }
    }

    // Now iterate the ones that need parenting. For loop as we might alter the
    // collection.
    for (int i = 0; i < needParenting.length; i++) {
      // This will always be a ComponentViewModel.
      final viewModel = needParenting[i];
      var allProps = viewModel.allProperties;

      // Make sure that all the parents were included in the timeline, some may
      // not be if they weren't keyed (there'd be no KeyedObject in the file for
      // them).
      var timelineParent = viewModel.component.timelineParent;

      var parent = _componentViewModels[timelineParent];
      parent ??= _makeComponentViewModel(timelineParent);

      // Aggregate the all properties...
      parent.allProperties.merge(allProps);

      if (timelineParent.timelineParent != null) {
        needParenting.add(parent);
      } else {
        hierarchy.add(parent);
      }

      // if (parent is KeyedComponentViewModel) {
      var groupName = viewModel.component.timelineParentGroup;
      if (groupName != null) {
        // Find the right one.
        var groups = _componentGroupViewModels[parent.component] ??=
            HashMap<String, KeyedGroupViewModel>();

        var group = groups[groupName];
        // Create the group if we didn't have it.
        if (group == null) {
          Set<KeyHierarchyViewModel> children = {};
          final allProperties = _AllPropertiesHelper(animation);
          _allPropertiesHelpers.add(allProperties);
          groups[groupName] = group = KeyedGroupViewModel(
            label: groupName,
            children: children,
            allProperties: allProperties,
          );
        }
        // Make sure all properties from the component get inserted into the
        // group.
        parent.allProperties.merge(allProps);
        group.allProperties.merge(allProps);
        // Keep pushing them up the tree (could later change this to be
        // recursive).
        if (parent.component.timelineParent != null) {
          var propagate = parent.component;
          while (propagate.timelineParent != null) {
            var parentViewModel =
                _componentViewModels[propagate.timelineParent];
            if (parentViewModel == null) {
              break;
            }
            parentViewModel.allProperties.merge(allProps);
            var groupName = propagate.timelineParentGroup;
            if (groupName != null) {
              var groups = _componentGroupViewModels[parentViewModel.component];
              if (groups != null) {
                var group = groups[groupName];
                if (group != null) {
                  group.allProperties.merge(allProps);
                }
              }
            }
            propagate = parentViewModel.component;
          }
        }

        // Make sure parent contains group. It's a set so we can do this.
        parent.children.add(group);
        // Add us to the group.
        group.children.add(viewModel);
      } else {
        parent.children.add(viewModel);
      }
      // }
    }

    _hierarchyController.add(hierarchy.toList(growable: false));
  }
}

/// Base class for a node with children in the hierarchy. This can be either a
/// keyed object or a named group (like Strokes is a named group within a
/// KeyedObject with more KeyedObjects within it).
@immutable
abstract class KeyHierarchyViewModel {
  ValueListenable<SelectionState> get selectionState;
  Set<KeyHierarchyViewModel> get children;
  const KeyHierarchyViewModel();
}

/// Base class for a KeyedViewModel with all keys.
@immutable
abstract class AllKeysViewModel extends KeyHierarchyViewModel {
  _AllPropertiesHelper get allProperties;
  const AllKeysViewModel();
}

/// Represents a Component in the hierarchy that may have a keyedObject if it
/// has keyed properties. It may not have keyed properties if it's just
/// containing other groups/objects that themselves have keyed properties.
@immutable
class KeyedComponentViewModel extends AllKeysViewModel {
  /// There's no guarantee that there will be a keyedObject for this
  /// view model
  final KeyedObject keyedObject;

  /// A component is always present in the viewmodel.
  final Component component;

  @override
  ValueListenable<SelectionState> get selectionState =>
      component?.stageItem?.selectionState;

  @override
  final Set<KeyHierarchyViewModel> children;

  /// All keyed properties within this viewmodel.
  @override
  final _AllPropertiesHelper allProperties;

  const KeyedComponentViewModel({
    @required this.component,
    this.keyedObject,
    this.allProperties,
    this.children = const {},
  }) : assert(component != null);
}

/// An ephemeral group that has no backing core properties, just a logical
/// grouping of sub keyed objects. N.B. that a group is never multi-nested, a
/// KeyedGroupViewModel's children will always be KeyedComponentViewModel but we
/// conform to KeyHierarchyViewModel to fit the class hierarchy/override for
/// children.
@immutable
class KeyedGroupViewModel extends AllKeysViewModel {
  final String label;

  @override
  ValueListenable<SelectionState> get selectionState => null;

  /// All keyed properties within this viewmodel.
  @override
  final _AllPropertiesHelper allProperties;

  @override
  final Set<KeyHierarchyViewModel> children;

  const KeyedGroupViewModel({
    this.label,
    this.allProperties,
    this.children = const {},
  });
}

/// A leaf in the animation hierarchy tree, a property with real keyframes.
@immutable
class KeyedPropertyViewModel extends KeyHierarchyViewModel {
  final KeyedProperty keyedProperty;
  final String label;
  final String subLabel;

  final SelectableItem selection;

  @override
  ValueListenable<SelectionState> get selectionState =>
      selection.selectionState;

  // /// The component in the timeline that'll show this property (may not match
  // /// the component that stores the property).
  // final Component timelineComponent;

  /// The component that actually stores the property.
  final Component component;

  @override
  Set<KeyHierarchyViewModel> get children => {};

  const KeyedPropertyViewModel({
    this.keyedProperty,
    this.label,
    this.subLabel,
    // this.timelineComponent,
    this.component,
    this.selection,
  });
}

/// Helper used to sort keyed properties.
class _KeyedPropertyHelper {
  final int groupKey;
  final int propertyOrder;
  final KeyedProperty keyedProperty;

  _KeyedPropertyHelper({
    this.groupKey,
    this.keyedProperty,
    this.propertyOrder,
  });
}

class AllKeyFrame implements KeyFrameInterface {
  final HashSet<KeyFrame> keyframes = HashSet<KeyFrame>();

  @override
  final int frame;

  AllKeyFrame(this.frame);
}

class _AllPropertiesHelper {
  final LinearAnimation animation;
  final HashSet<KeyedProperty> _all = HashSet<KeyedProperty>();
  final HashSet<KeyedObject> _objects = HashSet<KeyedObject>();
  KeyFrameList<AllKeyFrame> _cached;

  _AllPropertiesHelper(this.animation);

  /// Lazily rebuild the frames list when requested.
  KeyFrameList<AllKeyFrame> get cached {
    if (_cached != null) {
      return _cached;
    }

    HashMap<int, AllKeyFrame> lut = HashMap<int, AllKeyFrame>();
    // Merge the frames.
    for (final keyedProperty in _all) {
      for (final keyframe in keyedProperty.keyframes) {
        var allKey = lut[keyframe.frame];
        if (allKey == null) {
          lut[keyframe.frame] = allKey = AllKeyFrame(keyframe.frame);
        }
        allKey.keyframes.add(keyframe);
      }
    }
    _cached = KeyFrameList<AllKeyFrame>();
    _cached.keyframes = lut.values;
    _cached.sort();
    return _cached;
  }

  void add(KeyedProperty property) {
    _all.add(property);
    var ko = property.keyedObject;
    if (_objects.add(ko)) {
      ko.keyframesMoved.addListener(_markDirty);
      // Kind of a hack just to listen to the animation too, but only when we
      // actually have a keyframe.
      if (_objects.length == 1) {
        animation.keyframesChanged.addListener(_markDirty);
      }
    }
  }

  void merge(_AllPropertiesHelper allHelper) {
    allHelper._all.forEach(add);
  }

  void reset() {
    animation.keyframesChanged.removeListener(_markDirty);
    for (final object in _objects) {
      object.keyframesMoved.removeListener(_markDirty);
    }
    _objects.clear();
    _all.clear();
    _markDirty();
  }

  void _markDirty() {
    _cached = null;
  }
}
