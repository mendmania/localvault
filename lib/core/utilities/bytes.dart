import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

final Random _secureRandom = Random.secure();

Uint8List secureRandomBytes(int length) {
  return Uint8List.fromList(
    List<int>.generate(length, (_) => _secureRandom.nextInt(256)),
  );
}

String bytesToBase64(List<int> bytes) => base64Encode(bytes);

Uint8List base64ToBytes(String value) => base64Decode(value);

String bytesToHex(List<int> bytes) {
  final buffer = StringBuffer();
  for (final byte in bytes) {
    buffer.write(byte.toRadixString(16).padLeft(2, '0'));
  }
  return buffer.toString();
}

void clearBytes(List<int>? bytes) {
  if (bytes == null) {
    return;
  }
  for (var index = 0; index < bytes.length; index++) {
    bytes[index] = 0;
  }
}
