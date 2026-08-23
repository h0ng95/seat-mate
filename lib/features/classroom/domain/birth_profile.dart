import '../../../core/values/local_date.dart';

class BirthProfile {
  const BirthProfile({required this.date, this.hour, this.minute})
    : assert(
        (hour == null && minute == null) ||
            (hour != null &&
                minute != null &&
                hour >= 0 &&
                hour <= 23 &&
                minute >= 0 &&
                minute <= 59),
      );

  final LocalDate date;
  final int? hour;
  final int? minute;

  bool get hasBirthTime => hour != null && minute != null;

  String get canonical => hasBirthTime
      ? '${date.iso}T${hour!.toString().padLeft(2, '0')}:${minute!.toString().padLeft(2, '0')}'
      : date.iso;

  String get timeLabel => hasBirthTime
      ? '${hour!.toString().padLeft(2, '0')}:${minute!.toString().padLeft(2, '0')}'
      : '모름';

  @override
  bool operator ==(Object other) =>
      other is BirthProfile &&
      date == other.date &&
      hour == other.hour &&
      minute == other.minute;

  @override
  int get hashCode => Object.hash(date, hour, minute);
}
