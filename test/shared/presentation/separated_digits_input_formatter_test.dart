import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seat_mate/shared/presentation/separated_digits_input_formatter.dart';

void main() {
  const dateFormatter = SeparatedDigitsInputFormatter(
    groupLengths: [4, 2, 2],
    separator: '-',
  );
  const timeFormatter = SeparatedDigitsInputFormatter(
    groupLengths: [2, 2],
    separator: ':',
  );

  test('adds birth date separators while digits are entered', () {
    expect(_type(dateFormatter, '1995'), '1995-');
    expect(_type(dateFormatter, '199506'), '1995-06-');
    expect(_type(dateFormatter, '19950612'), '1995-06-12');
  });

  test('adds a birth time separator and limits the digit count', () {
    expect(_type(timeFormatter, '09'), '09:');
    expect(_type(timeFormatter, '093012'), '09:30');
  });

  test('normalizes pasted separators and non-digit characters', () {
    const oldValue = TextEditingValue();
    const newValue = TextEditingValue(
      text: '1995. 06/12',
      selection: TextSelection.collapsed(offset: 11),
    );

    expect(
      dateFormatter.formatEditUpdate(oldValue, newValue).text,
      '1995-06-12',
    );
  });

  test('backspace after an automatic separator deletes the prior digit', () {
    const oldValue = TextEditingValue(
      text: '1995-',
      selection: TextSelection.collapsed(offset: 5),
    );
    const newValue = TextEditingValue(
      text: '1995',
      selection: TextSelection.collapsed(offset: 4),
    );

    expect(dateFormatter.formatEditUpdate(oldValue, newValue).text, '199');
  });
}

String _type(SeparatedDigitsInputFormatter formatter, String digits) {
  var value = const TextEditingValue();
  for (final digit in digits.split('')) {
    final updated = TextEditingValue(
      text: '${value.text}$digit',
      selection: TextSelection.collapsed(offset: value.text.length + 1),
    );
    value = formatter.formatEditUpdate(value, updated);
  }
  return value.text;
}
