import 'package:flutter_test/flutter_test.dart';
import 'package:seat_mate/core/values/local_date.dart';
import 'package:seat_mate/features/classroom/domain/birth_profile.dart';
import 'package:seat_mate/features/classroom/domain/saju_chart.dart';
import 'package:seat_mate/features/classroom/domain/saju_compatibility.dart';

void main() {
  final chartCalculator = SajuChartCalculator();
  const engine = SajuCompatibilityEngine();

  SajuChart chart(String date, {int? hour, int? minute}) {
    return chartCalculator.calculate(
      BirthProfile(date: LocalDate.parseIso(date), hour: hour, minute: minute),
    );
  }

  test('compatibility score is the sum of four visible rule groups', () {
    final result = engine.analyze(
      owner: chart('1995-06-12'),
      member: chart('1996-03-17'),
    );

    expect(result.evidence, hasLength(4));
    expect(
      result.heartScore,
      result.evidence.fold<int>(0, (sum, item) => sum + item.score),
    );
    expect(result.heartScore, inInclusiveRange(32, 98));
    expect(result.rulesVersion, SajuCompatibilityEngine.rulesVersion);
  });

  test('the same two charts always return the same auditable result', () {
    final owner = chart('1995-06-12', hour: 9, minute: 10);
    final member = chart('1997-08-04', hour: 17, minute: 40);

    final first = engine.analyze(owner: owner, member: member);
    final second = engine.analyze(owner: owner, member: member);

    expect(first.toJson(), second.toJson());
    expect(first.analysisDepth, SajuAnalysisDepth.fourPillars);
    expect(first.analysisScope, contains('4/4'));
  });

  test('score stays symmetric when owner and member are swapped', () {
    final firstChart = chart('1995-11-23');
    final secondChart = chart('2001-01-01');

    final forward = engine.analyze(owner: firstChart, member: secondChart);
    final reverse = engine.analyze(owner: secondChart, member: firstChart);

    expect(forward.heartScore, reverse.heartScore);
    expect(
      forward.evidence.map((item) => item.score),
      reverse.evidence.map((item) => item.score),
    );
  });

  test('serialized result preserves calculation evidence', () {
    final result = engine.analyze(
      owner: chart('1995-06-12'),
      member: chart('1996-03-17'),
    );

    final restored = SajuCompatibility.fromJson(result.toJson());

    expect(restored.heartScore, result.heartScore);
    expect(restored.relationshipType, result.relationshipType);
    expect(restored.evidence.first.summary, result.evidence.first.summary);
  });
}
