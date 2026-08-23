import 'package:flutter/services.dart';

class SeparatedDigitsInputFormatter extends TextInputFormatter {
  const SeparatedDigitsInputFormatter({
    required this.groupLengths,
    required this.separator,
  });

  final List<int> groupLengths;
  final String separator;

  int get _maxDigits => groupLengths.fold(0, (sum, length) => sum + length);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = _digitsOnly(newValue.text);
    var baseDigits = _digitCountBefore(
      newValue.text,
      newValue.selection.baseOffset,
    );
    var extentDigits = _digitCountBefore(
      newValue.text,
      newValue.selection.extentOffset,
    );

    if (_deletedTrailingSeparator(oldValue, newValue) && extentDigits > 0) {
      final removedDigitIndex = extentDigits - 1;
      digits = digits.replaceRange(removedDigitIndex, extentDigits, '');
      if (baseDigits > removedDigitIndex) baseDigits--;
      if (extentDigits > removedDigitIndex) extentDigits--;
    }

    if (digits.length > _maxDigits) {
      digits = digits.substring(0, _maxDigits);
    }
    baseDigits = baseDigits.clamp(0, digits.length);
    extentDigits = extentDigits.clamp(0, digits.length);

    final formatted = _format(digits);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection(
        baseOffset: _formattedOffset(
          formatted,
          baseDigits,
          advancePastSeparator: _advancePastSeparator(
            newValue.text,
            newValue.selection.baseOffset,
          ),
        ),
        extentOffset: _formattedOffset(
          formatted,
          extentDigits,
          advancePastSeparator: _advancePastSeparator(
            newValue.text,
            newValue.selection.extentOffset,
          ),
        ),
      ),
    );
  }

  String _format(String digits) {
    final buffer = StringBuffer();
    var completedDigits = 0;
    var groupIndex = 0;

    for (var index = 0; index < digits.length; index++) {
      buffer.write(digits[index]);
      completedDigits++;
      if (groupIndex < groupLengths.length - 1 &&
          completedDigits == groupLengths[groupIndex]) {
        buffer.write(separator);
        completedDigits = 0;
        groupIndex++;
      }
    }
    return buffer.toString();
  }

  String _digitsOnly(String value) => value.replaceAll(RegExp(r'\D'), '');

  int _digitCountBefore(String value, int offset) {
    final safeOffset = offset.clamp(0, value.length);
    return _digitsOnly(value.substring(0, safeOffset)).length;
  }

  int _formattedOffset(
    String formatted,
    int digitCount, {
    required bool advancePastSeparator,
  }) {
    if (digitCount == 0) return 0;

    var seenDigits = 0;
    var offset = 0;
    while (offset < formatted.length && seenDigits < digitCount) {
      if (_isDigit(formatted[offset])) seenDigits++;
      offset++;
    }
    if (advancePastSeparator) {
      while (offset < formatted.length && formatted[offset] == separator) {
        offset++;
      }
    }
    return offset;
  }

  bool _advancePastSeparator(String value, int offset) {
    final safeOffset = offset.clamp(0, value.length);
    return safeOffset == value.length ||
        (safeOffset > 0 && value[safeOffset - 1] == separator);
  }

  bool _deletedTrailingSeparator(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (!oldValue.selection.isCollapsed ||
        !newValue.selection.isCollapsed ||
        oldValue.text.length != newValue.text.length + 1 ||
        oldValue.selection.extentOffset !=
            newValue.selection.extentOffset + 1) {
      return false;
    }
    final removedAt = newValue.selection.extentOffset;
    return removedAt >= 0 &&
        removedAt < oldValue.text.length &&
        oldValue.text[removedAt] == separator;
  }

  bool _isDigit(String character) {
    final codeUnit = character.codeUnitAt(0);
    return codeUnit >= 48 && codeUnit <= 57;
  }
}
