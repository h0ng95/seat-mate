import 'package:characters/characters.dart';

class Nickname {
  Nickname(String value)
    : display = _normalizeDisplay(value),
      normalized = _normalizeDisplay(value).toLowerCase() {
    final length = display.characters.length;
    if (length < 1 || length > 12) {
      throw const FormatException('별명은 1자 이상 12자 이하로 입력해 주세요.');
    }
  }

  final String display;
  final String normalized;

  static String _normalizeDisplay(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  @override
  bool operator ==(Object other) =>
      other is Nickname && normalized == other.normalized;

  @override
  int get hashCode => normalized.hashCode;

  @override
  String toString() => display;
}
