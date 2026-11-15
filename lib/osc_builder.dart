import 'dart:convert';
import 'dart:typed_data';

class OscBuilder {
  static Uint8List _padString(String str) {
    final bytes = utf8.encode(str);
    final padLength = 4 - (bytes.length % 4);
    final result = Uint8List(bytes.length + padLength);
    result.setAll(0, bytes);
    return result;
  }

  static Uint8List buildFloatPacket(String address, double value) {
    final addrBytes = _padString(address);
    final typeBytes = _padString(',f');
    final valBytes = ByteData(4)..setFloat32(0, value, Endian.big);

    final builder = BytesBuilder()
      ..add(addrBytes)
      ..add(typeBytes)
      ..add(valBytes.buffer.asUint8List());
    return builder.toBytes();
  }

  static Uint8List buildIntPacket(String address, int value) {
    final addrBytes = _padString(address);
    final typeBytes = _padString(',i');
    final valBytes = ByteData(4)..setInt32(0, value, Endian.big);

    final builder = BytesBuilder()
      ..add(addrBytes)
      ..add(typeBytes)
      ..add(valBytes.buffer.asUint8List());
    return builder.toBytes();
  }

  static Uint8List buildCommandPacket(String address) {
    return _padString(address);
  }
}
