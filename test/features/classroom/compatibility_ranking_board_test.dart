import 'package:flutter_test/flutter_test.dart';
import 'package:seat_mate/features/classroom/data/fake_classroom_repository.dart';
import 'package:seat_mate/features/classroom/presentation/widgets/compatibility_ranking_board.dart';

void main() {
  test('ranks non-owner members by compatibility score', () async {
    final classroom = await FakeClassroomRepository().getClassroom('preview');

    final ranked = rankByCompatibility(classroom.members);
    final scores = ranked
        .map((member) => member.compatibility!.heartScore)
        .toList();

    expect(ranked, hasLength(3));
    expect(ranked.any((member) => member.isOwner), isFalse);
    expect(scores, orderedEquals([...scores]..sort((a, b) => b.compareTo(a))));
  });
}
