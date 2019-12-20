import 'dart:convert';
import 'dart:typed_data';

var _variableEncodeList = Uint8List(8);
var _utf8Encoder = const Utf8Encoder();

class BinaryWriter {
  /// Stride we allocate buffer in chunks of.
  final int alignment;
  final Endian endian;
  Uint8List _buffer;
  ByteData get buffer => ByteData.view(_buffer.buffer, 0, size);

  ByteData _byteData;
  int _writeIndex = 0;
  int get size => _writeIndex;

  BinaryWriter({this.alignment = 1024, this.endian = Endian.little}) {
    _buffer = Uint8List(alignment);
    _byteData = ByteData.view(_buffer.buffer);
  }

  void _ensureAvailable(int byteLength) {
    if (_writeIndex + byteLength > _buffer.length) {
      do {
        _buffer = Uint8List(_buffer.length + alignment)
          ..setRange(0, _buffer.length, _buffer);
      } while (_writeIndex + byteLength > _buffer.length);
      _byteData = ByteData.view(_buffer.buffer);
    }
  }

  void writeFloat32(double value) {
    _ensureAvailable(4);
    _byteData.setFloat32(_writeIndex, value, endian);
    _writeIndex += 4;
  }

  void writeFloat64(double value) {
    _ensureAvailable(8);
    _byteData.setFloat64(_writeIndex, value, endian);
    _writeIndex += 8;
  }

  void writeInt8(int value) {
    _ensureAvailable(1);
    _byteData.setInt8(_writeIndex, value);
    _writeIndex += 1;
  }

  void writeUint8(int value) {
    _ensureAvailable(1);
    _byteData.setUint8(_writeIndex, value);
    _writeIndex += 1;
  }

  void writeInt16(int value) {
    _ensureAvailable(2);
    _byteData.setInt16(_writeIndex, value, endian);
    _writeIndex += 2;
  }

  void writeUint16(int value) {
    _ensureAvailable(2);
    _byteData.setUint16(_writeIndex, value, endian);
    _writeIndex += 2;
  }

  void writeInt32(int value) {
    _ensureAvailable(4);
    _byteData.setInt32(_writeIndex, value, endian);
    _writeIndex += 4;
  }

  void writeUint32(int value) {
    _ensureAvailable(4);
    _byteData.setUint32(_writeIndex, value, endian);
    _writeIndex += 4;
  }

  void writeInt64(int value) {
    _ensureAvailable(8);
    _byteData.setInt64(_writeIndex, value, endian);
    _writeIndex += 8;
  }

  void writeUint64(int value) {
    _ensureAvailable(8);
    _byteData.setUint64(_writeIndex, value, endian);
    _writeIndex += 8;
  }

  /// Write bytes into the buffer. Optional [length] to write a specific number
  /// of [bytes], otherwise the length from [bytes] is used.
  void write(Uint8List bytes, [int length]) {
    length ??= bytes.length;
    _ensureAvailable(length);
    _buffer.setRange(_writeIndex, _writeIndex + length, bytes);
    _writeIndex += length;
  }

  /// Write an integer as a list of bytes that contain an LEB128 signed integer.
  /// The size of the integer is decided automatically.
  void writeVarInt(int value) {
    var more = true;
    int index = 0;
    while (more) {
      var byte = value & 0x7f;
      value >>= 7;
      if (value == 0 && (byte & 0x40) == 0) {
        more = false;
      } else if (value == -1 && (byte & 0x40) > 0) {
        more = false;
      } else {
        byte |= 0x80;
      }
      _variableEncodeList[index++] = byte;
    }

    write(_variableEncodeList, index);
  }

  /// Write an integer as a list of bytes that contain an LEB128 unsigned
  /// integer. The size of the integer is decided automatically.
  void writeVarUint(int value) {
    int size = (value.toRadixString(2).length / 7.0).ceil();
    int index = 0;
    int i = 0;
    while (i < size) {
      int part = value & 0x7f;
      value >>= 7;
      _variableEncodeList[index++] = part;
      i += 1;
    }
    for (var i = 0; i < index - 1; i++) {
      _variableEncodeList[i] |= 0x80;
    }
    write(_variableEncodeList, index);
  }

  /// Encode a string into the buffer. Strings are encoded with a varuint
  /// integer length written first followed by length number of utf8 encoded
  /// bytes.
  void writeString(String value) {
    var list = _utf8Encoder.convert(value);
    writeVarUint(list.length);
    write(list);
  }
}
