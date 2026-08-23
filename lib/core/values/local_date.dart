class LocalDate implements Comparable<LocalDate> {
  const LocalDate._(this.year, this.month, this.day);

  factory LocalDate(int year, int month, int day) {
    final candidate = DateTime(year, month, day);
    if (candidate.year != year ||
        candidate.month != month ||
        candidate.day != day) {
      throw const FormatException('유효한 날짜를 입력해 주세요.');
    }
    return LocalDate._(year, month, day);
  }

  factory LocalDate.parseIso(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (match == null) throw const FormatException('날짜 형식은 YYYY-MM-DD여야 합니다.');
    return LocalDate(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
  }

  final int year;
  final int month;
  final int day;

  String get iso =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

  String get display =>
      '$year. ${month.toString().padLeft(2, '0')}. ${day.toString().padLeft(2, '0')}';

  @override
  int compareTo(LocalDate other) => iso.compareTo(other.iso);

  @override
  bool operator ==(Object other) => other is LocalDate && iso == other.iso;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => iso;
}
