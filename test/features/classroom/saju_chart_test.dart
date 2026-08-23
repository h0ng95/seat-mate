import 'package:flutter_test/flutter_test.dart';
import 'package:seat_mate/core/values/local_date.dart';
import 'package:seat_mate/features/classroom/domain/birth_profile.dart';
import 'package:seat_mate/features/classroom/domain/saju_chart.dart';

void main() {
  final calculator = SajuChartCalculator();

  test('calculates a stable three-pillar chart without birth time', () {
    final birth = BirthProfile(date: LocalDate.parseIso('1995-06-12'));

    final first = calculator.calculate(birth);
    final second = calculator.calculate(birth);

    expect(first.toJson(), second.toJson());
    expect(first.depth, SajuAnalysisDepth.threePillars);
    expect(first.availablePillars, hasLength(3));
    expect(first.elementCounts.values.reduce((a, b) => a + b), 6);
  });

  test('includes the hour pillar when exact birth time is available', () {
    final chart = calculator.calculate(
      BirthProfile(date: LocalDate.parseIso('2026-02-18'), hour: 12, minute: 0),
    );

    expect(chart.depth, SajuAnalysisDepth.fourPillars);
    expect(chart.availablePillars, hasLength(4));
    expect(chart.elementCounts.values.reduce((a, b) => a + b), 8);
    expect(chart.year.hanja, '丙午');
    expect(chart.month.hanja, '庚寅');
    expect(chart.day.hanja, '癸亥');
    expect(chart.hour?.hanja, '戊午');
  });

  test('serializes chart metadata without losing analysis depth', () {
    final chart = calculator.calculate(
      BirthProfile(date: LocalDate.parseIso('1996-03-17'), hour: 8, minute: 30),
    );

    final restored = SajuChart.fromJson(chart.toJson());

    expect(restored.day.hanja, chart.day.hanja);
    expect(restored.hour?.hanja, chart.hour?.hanja);
    expect(restored.elementCounts, chart.elementCounts);
    expect(restored.depth, SajuAnalysisDepth.fourPillars);
  });
}
