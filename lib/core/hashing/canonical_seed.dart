import 'dart:convert';

abstract final class CanonicalSeed {
  static String build({
    required int version,
    required String purpose,
    required Map<String, String> fields,
  }) {
    final buffer = StringBuffer('v$version');
    _append(buffer, 'purpose', purpose);
    for (final entry in fields.entries) {
      _append(buffer, entry.key, entry.value);
    }
    return buffer.toString();
  }

  static void _append(StringBuffer buffer, String key, String value) {
    buffer
      ..write('|')
      ..write(key)
      ..write('=')
      ..write(utf8.encode(value).length)
      ..write(':')
      ..write(value);
  }
}
