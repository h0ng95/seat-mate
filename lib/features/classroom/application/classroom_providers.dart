import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/app_config.dart';
import '../data/fake_classroom_repository.dart';
import '../data/supabase_classroom_repository.dart';
import '../domain/classroom.dart';
import '../domain/classroom_repository.dart';

final appConfigProvider = Provider<AppConfig>(
  (ref) => AppConfig.fromEnvironment(),
);

final classroomRepositoryProvider = Provider<ClassroomRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.hasSupabase) {
    return SupabaseClassroomRepository(Supabase.instance.client);
  }
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

class JoinClassroomController
    extends Notifier<AsyncValue<JoinClassroomResult>?> {
  @override
  AsyncValue<JoinClassroomResult>? build() => null;

  Future<JoinClassroomResult?> join(JoinClassroomCommand command) async {
    if (state?.isLoading ?? false) return null;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(classroomRepositoryProvider).joinClassroom(command),
    );
    state = result;
    return result.value;
  }

  void reset() => state = null;
}

final joinClassroomControllerProvider =
    NotifierProvider<JoinClassroomController, AsyncValue<JoinClassroomResult>?>(
      JoinClassroomController.new,
    );
