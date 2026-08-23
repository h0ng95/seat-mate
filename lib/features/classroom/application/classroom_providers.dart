import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/fake_classroom_repository.dart';
import '../domain/classroom.dart';
import '../domain/classroom_repository.dart';

final classroomRepositoryProvider = Provider<ClassroomRepository>((ref) {
  return FakeClassroomRepository();
});

final classroomProvider = FutureProvider.family<Classroom, String>((
  ref,
  shareCode,
) {
  return ref.watch(classroomRepositoryProvider).getClassroom(shareCode);
});

class CreateClassroomController extends Notifier<AsyncValue<Classroom>?> {
  @override
  AsyncValue<Classroom>? build() => null;

  Future<Classroom?> create(CreateClassroomCommand command) async {
    if (state?.isLoading ?? false) return null;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(classroomRepositoryProvider).createClassroom(command),
    );
    state = result;
    return result.value;
  }
}

final createClassroomControllerProvider =
    NotifierProvider<CreateClassroomController, AsyncValue<Classroom>?>(
      CreateClassroomController.new,
    );
