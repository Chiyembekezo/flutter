import 'dart:typed_data';

import 'package:rive/rive_core/runtime/runtime_header.dart';
import 'package:rive/rive_core/backboard.dart';
import 'package:rive/src/core/core.dart';
import 'package:rive/src/utilities/binary_buffer/binary_reader.dart';
import 'package:rive/rive_core/runtime/exceptions/rive_format_error_exception.dart';
import 'package:rive/rive_core/component.dart';
import 'package:rive/rive_core/animation/animation.dart';
import 'package:rive/rive_core/animation/keyed_object.dart';
import 'package:rive/rive_core/animation/keyed_property.dart';
import 'package:rive/rive_core/animation/keyframe.dart';
import 'package:rive/rive_core/animation/linear_animation.dart';
import 'package:rive/rive_core/artboard.dart';

class RiveFile {
  RuntimeHeader _header;
  RuntimeHeader get header => _header;
  Backboard _backboard;
  Backboard get backboard => _backboard;

  final List<Artboard> _artboards = [];
  List<Artboard> get artboards => _artboards;

  Artboard get mainArtboard => _artboards.first;

  bool import(ByteData bytes) {
    assert(_header == null, 'can only import once');
    var reader = BinaryReader(bytes);
    _header = RuntimeHeader.read(reader);

    _backboard = readRuntimeObject<Backboard>(reader);
    if (_backboard == null) {
      throw const RiveFormatErrorException(
          'expected first object to be a Backboard');
    }
    // core.addObject(_backboard);
    int numArtboards = reader.readVarUint();
    for (int i = 0; i < numArtboards; i++) {
      var artboard = readRuntimeObject(reader, RuntimeArtboard());
      artboard?.context = artboard;
      _artboards.add(artboard);
      var numObjects = reader.readVarUint();
      // var objects = List<Core<RiveCoreContext>>(numObjects);
      for (int i = 0; i < numObjects; i++) {
        Core<CoreContext> object = readRuntimeObject(reader);
        // N.B. we add objects that don't load (null) too as we need to look
        // them up by index.
        artboard.addObject(object);
      }

      // Animations also need to reference objects, so make sure they get read
      // in before the hierarchy resolves (batch add completes).
      var numAnimations = reader.readVarUint();
      for (int i = 0; i < numAnimations; i++) {
        var animation = readRuntimeObject<Animation>(reader);
        if (animation == null) {
          continue;
        }
        artboard.addObject(animation);
        animation.artboard = artboard;
        if (animation is LinearAnimation) {
          var numKeyedObjects = reader.readVarUint();
          for (int j = 0; j < numKeyedObjects; j++) {
            var keyedObject = readRuntimeObject<KeyedObject>(reader);
            if (keyedObject == null) {
              continue;
            }
            artboard.addObject(keyedObject);

            animation.internalAddKeyedObject(keyedObject);

            var numKeyedProperties = reader.readVarUint();
            for (int k = 0; k < numKeyedProperties; k++) {
              var keyedProperty = readRuntimeObject<KeyedProperty>(reader);
              if (keyedProperty == null) {
                continue;
              }
              artboard.addObject(keyedProperty);
              keyedObject.internalAddKeyedProperty(keyedProperty);

              var numKeyframes = reader.readVarUint();
              for (int l = 0; l < numKeyframes; l++) {
                var keyframe = readRuntimeObject<KeyFrame>(reader);
                if (keyframe == null) {
                  continue;
                }
                artboard.addObject(keyframe);
                keyedProperty.internalAddKeyFrame(keyframe);
                keyframe.computeSeconds(animation);
              }
            }
          }
        }
      }

      // Any component objects with no id map to the artboard.
      for (final object in artboard.objects) {
        if (object is Component && object.parentId == null) {
          object.parent = artboard;
        }
        object?.onAddedDirty();
      }
      for (final object in artboard.objects) {
        object?.onAdded();
      }
      artboard.clean();
    }

    return true;
  }
}

T readRuntimeObject<T extends Core<CoreContext>>(BinaryReader reader,
    [T instance]) {
  int coreObjectKey = reader.readVarUint();

  var object = instance ?? RiveCoreContext.makeCoreInstance(coreObjectKey);
  if (object is! T) {
    return null;
  }

  while (true) {
    int propertyKey = reader.readVarUint();
    if (propertyKey == 0) {
      // Terminator. https://media.giphy.com/media/7TtvTUMm9mp20/giphy.gif
      break;
    }
    int propertyLength = reader.readVarUint();
    Uint8List valueBytes = reader.read(propertyLength);

    var fieldType = RiveCoreContext.coreType(propertyKey);
    if (fieldType == null) {
      // This is considered an acceptable failure. A runtime may not support
      // the same properties that were exported. The older object could still
      // function without them, however, so it's up to the implementation to
      // make sure that major versions are revved when breaking properties are
      // added. Note that we intentionally first read the entire value bytes
      // for the property so we can advance as expected even if we are
      // skipping this value.
      continue;
    }

    // We know what to expect, let's try to read the value. We instance a new
    // reader here so that we don't overflow the exact length we're allowed to
    // read.
    var valueReader = BinaryReader.fromList(valueBytes);

    // This will attempt to set the object property, but failure here is
    // acceptable.
    RiveCoreContext.setObjectProperty(
        object, propertyKey, fieldType.deserialize(valueReader));
  }
  return object as T;
}
