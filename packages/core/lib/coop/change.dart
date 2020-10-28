import 'dart:typed_data';

import 'package:utilities/binary_buffer/binary_writer.dart';
import 'package:utilities/binary_buffer/binary_reader.dart';
import 'package:core/id.dart';

import 'coop_command.dart';

/// An individual change.
class Change {
  int op;
  Uint8List value;

  void serialize(BinaryWriter writer) {
    writer.writeVarUint(op);
    if (value == null) {
      writer.writeVarUint(0);
      return;
    }
    writer.writeVarUint(value.length);
    writer.write(value);
  }

  void deserialize(BinaryReader reader) {
    op = reader.readVarUint();
    int length = reader.readVarUint();
    value = reader.read(length);
  }

  Change clone() {
    return Change()
      ..op = op
      ..value = Uint8List.fromList(value);
  }
}

/// A list of changes for an object.
class ObjectChanges {
  Id objectId;
  List<Change> changes;

  void serialize(BinaryWriter writer) {
    objectId.serialize(writer);
    writer.writeVarUint(changes?.length ?? 0);
    if (changes != null) {
      for (final change in changes) {
        change.serialize(writer);
      }
    }
  }

  void deserialize(BinaryReader reader) {
    objectId = Id.deserialize(reader);
    int changesLength = reader.readVarUint();
    changes = List<Change>(changesLength);
    for (int i = 0; i < changes.length; i++) {
      changes[i] = Change()..deserialize(reader);
    }
  }

  ObjectChanges clone([bool test(Change change)]) {
    var cloneChanges = test == null ? changes : changes?.where(test);
    return ObjectChanges()
      ..objectId = objectId
      ..changes = cloneChanges?.map((change) => change.clone())?.toList();
  }
}

/// A set of changes associated to an id.
class ChangeSet {
  int _id;

  /// Session scoped change identifier. Should never be 0-9 as these are
  /// reserved for other (non-change) actions.
  int get id => _id;
  set id(int value) {
    assert(value >= CoopCommand.minChangeId,
        'ChangeSet id must be >= $CoopCommand.minChangeId.');
    _id = value;
  }

  List<ObjectChanges> objects;

  int get numProperties {
    return objects.fold(0, (previous, object) {
      return previous + object.changes.length;
    });
  }

  void serialize(BinaryWriter writer) {
    writer.writeVarUint(id);
    writer.writeVarUint(objects?.length ?? 0);
    if (objects != null) {
      for (final change in objects) {
        change.serialize(writer);
      }
    }
  }

  void deserialize(BinaryReader reader, [int preReadOp]) {
    id = preReadOp ?? reader.readVarUint();
    int changesLength = reader.readVarUint();
    objects = List<ObjectChanges>(changesLength);
    for (int i = 0; i < objects.length; i++) {
      objects[i] = ObjectChanges()..deserialize(reader);
    }
  }
}
