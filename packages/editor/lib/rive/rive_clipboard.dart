import 'dart:collection';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:core/id.dart';
import 'package:rive_core/animation/interpolator.dart';
import 'package:rive_core/animation/keyframe.dart';
import 'package:rive_core/animation/keyed_object.dart';
import 'package:rive_core/animation/keyed_property.dart';
import 'package:rive_core/animation/keyframe_draw_order.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_core/runtime/runtime_importer.dart';
import 'package:rive_editor/rive/open_file_context.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:utilities/binary_buffer/binary_reader.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';
import 'package:utilities/utilities.dart';

abstract class RiveClipboard {
  RiveClipboard._();
  factory RiveClipboard.copy(OpenFileContext file) {
    assert(file != null, 'can\'t copy from null file');
    var keyFrameManager = file.keyFrameManager.value;
    if (keyFrameManager != null && keyFrameManager.selection.value.isNotEmpty) {
      return _RiveKeyFrameClipboard(keyFrameManager.selection.value);
    } else {
      return _RiveHierarchyClipboard(file);
    }
  }
  bool paste(OpenFileContext file);
}

class _RiveKeyFrameClipboard extends RiveClipboard {
  Uint8List bytes;
  final List<Id> keyedObjectIds = [];
  _RiveKeyFrameClipboard(HashSet<KeyFrame> keyFrames) : super._() {
    var export = <KeyedObject, HashMap<KeyedProperty, HashSet<KeyFrame>>>{};

    var interpolators = <Core>{};
    for (final keyframe in keyFrames) {
      var kp = keyframe.keyedProperty;
      var ko = kp.keyedObject;
      if (keyframe.interpolator is Core) {
        interpolators.add(keyframe.interpolator as Core);
      }
      var exportKeyedObject =
          export[ko] ??= HashMap<KeyedProperty, HashSet<KeyFrame>>();
      var keyframes = exportKeyedObject[kp] ??= HashSet<KeyFrame>();
      keyframes.add(keyframe);
    }

    // Build up an idLookup table for the ids of the referenced interpolators to
    // their export key (an index in the interpolator list).
    var idLookup = HashMap<Id, int>();
    var interpolatorList = interpolators.toList();
    for (int i = 0; i < interpolatorList.length; i++) {
      var interpolator = interpolatorList[i];
      idLookup[interpolator.id] = i;
    }

    var writer = BinaryWriter();
    writer.writeVarUint(interpolatorList.length);
    for (final interpolator in interpolatorList) {
      interpolator.writeRuntime(writer);
    }

    writer.writeVarUint(export.length);
    for (final keyedObject in export.keys) {
      keyedObjectIds.add(keyedObject.objectId);
      keyedObject.writeRuntimeSubset(writer, export[keyedObject], idLookup);
    }

    bytes = writer.uint8Buffer;
    return;
  }

  @override
  bool paste(OpenFileContext file) {
    var core = file.core;
    var keyFrameManager = file.keyFrameManager.value;
    var animationManager = file.editingAnimationManager.value;

    // Can't paste keyframes if we're not in animation mode.
    if (!core.isAnimating || keyFrameManager == null) {
      return false;
    }
    var reader = BinaryReader.fromList(bytes);
    var interpolatorCount = reader.readVarUint();
    var interpolators = List<Core>(interpolatorCount);

    core.batchAdd(() {
      for (int i = 0; i < interpolatorCount; i++) {
        var interpolator = interpolators[i] = core.readRuntimeObject(reader);
        if (interpolator is Interpolator) {
          core.addObject(interpolator);
        }
      }

      var idRemap = RuntimeIdRemap(core.idType, core.intType);
      var remaps = <RuntimeRemap>[idRemap];

      int minTime = double.maxFinite.toInt();
      List<KeyFrame> addedKeyFrames = [];
      var animation = keyFrameManager.animation;
      var keyedObjectCount = reader.readVarUint();
      for (int i = 0; i < keyedObjectCount; i++) {
        var keyedObject = core.readRuntimeObject<KeyedObject>(reader, remaps);
        if (keyedObject == null) {
          continue;
        }
        // Original keyed object for the id we're trying to key.
        var existingObjectToKey = core.resolve<Core>(keyedObjectIds[i]);
        // Make sure it is actually keyed in this animation (use could've
        // changed animation).
        if (animation.getKeyed(existingObjectToKey) != null) {
          keyedObject = animation.getKeyed(existingObjectToKey);
        } else {
          // The animation didn't already key this object, so let's pipe in our
          // new keyedObject to it.
          core.addObject(keyedObject);
          keyedObject.animationId = keyFrameManager.animation.id;
        }
        var numKeyedProperties = reader.readVarUint();
        for (int k = 0; k < numKeyedProperties; k++) {
          var keyedProperty =
              core.readRuntimeObject<KeyedProperty>(reader, remaps);
          if (keyedProperty == null) {
            continue;
          }
          // Figure out if we want to add th keyedProperty to core or use an
          // existing one.

          if (keyedObject.getKeyed(keyedProperty.propertyKey) != null) {
            // This property is already keyed, make sure we tack on our
            // keyframes to the existing list.
            keyedProperty = keyedObject.getKeyed(keyedProperty.propertyKey);
          } else {
            // Add our newed up keyedProperty to the keyedObject as we didn't
            // already keyframe this property.
            core.addObject(keyedProperty);
            keyedProperty.keyedObjectId = keyedObject.id;
          }

          var numKeyframes = reader.readVarUint();

          for (int l = 0; l < numKeyframes; l++) {
            var keyframe = core.readRuntimeObject<KeyFrame>(reader, remaps);
            if (keyframe.frame < minTime) {
              minTime = keyframe.frame;
            }
            addedKeyFrames.add(keyframe);
            core.addObject(keyframe);
            keyframe.keyedPropertyId = keyedProperty.id;
            if (keyframe is KeyFrameDrawOrder) {
              keyframe.readRuntimeValues(core, reader, idRemap);
            }
          }
        }
      }
      // Perform the id remapping for the interpolators.
      for (final remap in idRemap.properties) {
        var id = interpolators[remap.value]?.id;
        if (id != null) {
          core.setObjectProperty(remap.object, remap.propertyKey, id);
        }
      }

      // Put them all relative to the playhead...
      for (final keyframe in addedKeyFrames) {
        keyframe.frame = keyframe.frame - minTime + animationManager.frame;
      }
    });

    return true;
  }
}

class _RiveHierarchyClipboard extends RiveClipboard {
  Uint8List bytes;
  Set<Component> copiedComponents;

  _RiveHierarchyClipboard(OpenFileContext file) : super._() {
    var components = <Component>{};
    for (final item in file.selection.items) {
      if (item is StageItem && item.component is Component) {
        components.add(item.component as Component);
      }
    }
    copiedComponents = <Component>{};

    for (final component in tops(components)) {
      // This is a top level component, add it and any of its children to the
      // copy set.
      copiedComponents.add(component);
      if (component is ContainerComponent) {
        component.forEachChild((child) {
          copiedComponents.add(child);
          return true;
        });
      }
    }

    HashMap<Id, int> idToIndex = HashMap<Id, int>();
    int index = 0;
    for (final component in copiedComponents) {
      idToIndex[component.id] = index++;
    }

    var writer = BinaryWriter();
    writer.writeVarUint(copiedComponents.length);
    for (final component in copiedComponents) {
      component.writeRuntime(writer, idToIndex);
    }
    bytes = writer.uint8Buffer;
  }

  @override
  bool paste(OpenFileContext file) {
    var selectedItems = file.selection.items;
    var selectedItem = selectedItems.isNotEmpty ? selectedItems.last : null;
    Component pasteDestination;
    if (selectedItem is StageItem &&
        selectedItem.component is Component &&
        !copiedComponents.contains(selectedItem.component)) {
      pasteDestination = selectedItem.component as Component;
    } else {
      pasteDestination = file.core.backboard.activeArtboard;
    }

    var reader = BinaryReader.fromList(bytes);
    var numObjects = reader.readVarUint();
    var core = file.core;

    var idRemap = RuntimeIdRemap(core.idType, core.intType);
    var drawOrderRemap = DrawOrderRemap(core.fractionalIndexType, core.intType);
    var remaps = <RuntimeRemap>[idRemap, drawOrderRemap];

    var targetArtboard = pasteDestination.artboard;
    var objects = List<Component>(numObjects);
    core.batchAdd(() {
      for (int i = 0; i < numObjects; i++) {
        var component = core.readRuntimeObject<Component>(reader, remaps);
        if (component != null) {
          // TODO: kill
          if (component.name != null) {
            component.name = 'PASTED: ${component.name}';
          }
          objects[i] = component;
          core.addObject(component);
        }
      }

      // Patch up the draw order using the last drawable as the min for the
      // newly added drawables.
      drawOrderRemap.remap(
          core,
          targetArtboard.drawables.isNotEmpty
              ? targetArtboard.drawables.last?.drawOrder
              : null);

      // Perform the id remapping.
      for (final remap in idRemap.properties) {
        var id = objects[remap.value]?.id;
        if (id != null) {
          core.setObjectProperty(remap.object, remap.propertyKey, id);
        }
      }

      // Any component objects with no id map to the pasteDestination.
      for (final object in objects) {
        if (object is Component && object.parentId == null) {
          object.parentId = pasteDestination.id;
        }
      }
    });

    // Finally select the newly added items.
    var selection = <StageItem>{};
    for (final component in objects) {
      // Select only stageItems that have been added to the stage.
      if (component == null ||
          component.stageItem == null ||
          component.stageItem.stage == null) {
        continue;
      }
      selection.add(component.stageItem);
    }
    if (selection.isNotEmpty) {
      file.selection.selectMultiple(selection);
    }

    return true;
  }
}
