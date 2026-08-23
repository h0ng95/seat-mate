import 'package:flutter/material.dart';

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
  final bool isOwner;
}
