import 'dart:convert';

import 'package:crypto/crypto.dart';

abstract final class StableHash {
  static List<int> bytes(String seed) =>
      sha256.convert(utf8.encode(seed)).bytes;

  static int uint16(String seed) {
    final digest = bytes(seed);
    return (digest[0] << 8) | digest[1];
  }

  static int uint32(String seed) {
    final digest = bytes(seed);
    return (digest[0] << 24) | (digest[1] << 16) | (digest[2] << 8) | digest[3];
  }

  static String hex(String seed) =>
      sha256.convert(utf8.encode(seed)).toString();

  static int mapByteToRange(int byte, ({int min, int max}) range) {
    return range.min + (byte * (range.max - range.min + 1) ~/ 256);
  }
}
