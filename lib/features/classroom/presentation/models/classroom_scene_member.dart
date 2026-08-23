import 'package:flutter/material.dart';

import '../../domain/saju_chart.dart';
import '../../domain/saju_compatibility.dart';

class ClassroomSceneMember {
  const ClassroomSceneMember({
    required this.name,
    required this.seatIndex,
    required this.relationshipTitle,
    required this.relationshipDescription,
    required this.seatDescription,
    required this.focusDelta,
    required this.joyDelta,
    required this.color,
    required this.characterSeed,
    required this.sajuChart,
    required this.ownerSajuChart,
    required this.compatibility,
    this.isOwner = false,
  });

  final String name;
  final int seatIndex;
  final String relationshipTitle;
  final String relationshipDescription;
  final String seatDescription;
  final int focusDelta;
  final int joyDelta;
  final Color color;
  final String characterSeed;
  final SajuChart? sajuChart;
  final SajuChart? ownerSajuChart;
  final SajuCompatibility? compatibility;
  final bool isOwner;
}
