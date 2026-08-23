import 'package:saju/saju.dart' as saju;
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

import 'birth_profile.dart';

enum SajuAnalysisDepth { threePillars, fourPillars }

extension SajuAnalysisDepthDefinition on SajuAnalysisDepth {
  String get label => switch (this) {
    SajuAnalysisDepth.threePillars => '삼주 기본 분석',
    SajuAnalysisDepth.fourPillars => '사주 상세 분석',
  };

  String get description => switch (this) {
    SajuAnalysisDepth.threePillars => '출생시간이 없어 년주·월주·일주만 반영했어요.',
    SajuAnalysisDepth.fourPillars => '출생시간을 포함해 년주·월주·일주·시주를 반영했어요.',
  };
}

class SajuPillarValue {
  const SajuPillarValue({
    required this.hanja,
    required this.korean,
    required this.stemElement,
    required this.branchElement,
    required this.stemPolarity,
  });

  final String hanja;
  final String korean;
  final String stemElement;
  final String branchElement;
  final String stemPolarity;

  Map<String, dynamic> toJson() => {
    'hanja': hanja,
    'korean': korean,
    'stem_element': stemElement,
    'branch_element': branchElement,
    'stem_polarity': stemPolarity,
  };

  factory SajuPillarValue.fromJson(Map<String, dynamic> json) {
    return SajuPillarValue(
      hanja: json['hanja'] as String,
      korean: json['korean'] as String,
      stemElement: json['stem_element'] as String,
      branchElement: json['branch_element'] as String,
      stemPolarity: json['stem_polarity'] as String,
    );
  }
}

class SajuChart {
  const SajuChart({
    required this.year,
    required this.month,
    required this.day,
    required this.hour,
    required this.elementCounts,
    required this.depth,
    required this.solarYear,
    required this.sunLongitude,
    this.engineVersion = 'saju-0.1.1',
  });

  final SajuPillarValue year;
  final SajuPillarValue month;
  final SajuPillarValue day;
  final SajuPillarValue? hour;
  final Map<String, int> elementCounts;
  final SajuAnalysisDepth depth;
  final int solarYear;
  final double sunLongitude;
  final String engineVersion;

  String get dayMaster => day.hanja.substring(0, 1);
  String get dayMasterKorean => day.korean.substring(0, 1);
  String get dayMasterElement => day.stemElement;
  String get dayMasterPolarity => day.stemPolarity;
  bool get hasBirthTime => depth == SajuAnalysisDepth.fourPillars;

  List<SajuPillarValue> get availablePillars => [year, month, day, ?hour];

  Map<String, dynamic> toJson() => {
    'year': year.toJson(),
    'month': month.toJson(),
    'day': day.toJson(),
    'hour': hour?.toJson(),
    'element_counts': elementCounts,
    'depth': depth.name,
    'solar_year': solarYear,
    'sun_longitude': sunLongitude,
    'engine_version': engineVersion,
  };

  factory SajuChart.fromJson(Map<String, dynamic> json) {
    final hourJson = json['hour'];
    return SajuChart(
      year: SajuPillarValue.fromJson(
        Map<String, dynamic>.from(json['year'] as Map),
      ),
      month: SajuPillarValue.fromJson(
        Map<String, dynamic>.from(json['month'] as Map),
      ),
      day: SajuPillarValue.fromJson(
        Map<String, dynamic>.from(json['day'] as Map),
      ),
      hour: hourJson == null
          ? null
          : SajuPillarValue.fromJson(
              Map<String, dynamic>.from(hourJson as Map),
            ),
      elementCounts: Map<String, int>.from(json['element_counts'] as Map),
      depth: SajuAnalysisDepth.values.byName(json['depth'] as String),
      solarYear: json['solar_year'] as int,
      sunLongitude: (json['sun_longitude'] as num).toDouble(),
      engineVersion: json['engine_version'] as String? ?? 'saju-0.1.1',
    );
  }
}

class SajuChartCalculator {
  SajuChartCalculator() {
    _initializeTimeZones();
  }

  static bool _timeZonesInitialized = false;

  static void _initializeTimeZones() {
    if (_timeZonesInitialized) return;
    timezone_data.initializeTimeZones();
    _timeZonesInitialized = true;
  }

  SajuChart calculate(BirthProfile birth) {
    final location = timezone.getLocation('Asia/Seoul');
    final birthTime = timezone.TZDateTime(
      location,
      birth.date.year,
      birth.date.month,
      birth.date.day,
      birth.hour ?? 12,
      birth.minute ?? 0,
    );
    final result = saju.getFourPillars(
      birthTime,
      tzOffsetHours: 9,
      preset: saju.standardPreset,
    );
    final pillars = [
      result.pillars.year,
      result.pillars.month,
      result.pillars.day,
      if (birth.hasBirthTime) result.pillars.hour,
    ];
    final counts = {for (final element in saju.Element.values) element.key: 0};
    for (final pillar in pillars) {
      counts[pillar.stem.element.key] = counts[pillar.stem.element.key]! + 1;
      counts[pillar.branch.element.key] =
          counts[pillar.branch.element.key]! + 1;
    }

    return SajuChart(
      year: _pillarValue(result.pillars.year),
      month: _pillarValue(result.pillars.month),
      day: _pillarValue(result.pillars.day),
      hour: birth.hasBirthTime ? _pillarValue(result.pillars.hour) : null,
      elementCounts: Map.unmodifiable(counts),
      depth: birth.hasBirthTime
          ? SajuAnalysisDepth.fourPillars
          : SajuAnalysisDepth.threePillars,
      solarYear: result.solarYear,
      sunLongitude: result.sunLonDeg,
    );
  }

  SajuPillarValue _pillarValue(saju.Pillar pillar) {
    return SajuPillarValue(
      hanja: pillar.hanja,
      korean: pillar.korean,
      stemElement: pillar.stem.element.key,
      branchElement: pillar.branch.element.key,
      stemPolarity: pillar.stem.polarity.key,
    );
  }
}
