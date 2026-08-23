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

final demoClassroomRepositoryProvider = Provider<FakeClassroomRepository>(
  (ref) => FakeClassroomRepository(),
);

final classroomProvider = FutureProvider.family<Classroom, String>((
  ref,
  shareCode,
) {
  final repository = shareCode == 'preview'
      ? ref.watch(demoClassroomRepositoryProvider)
      : ref.watch(classroomRepositoryProvider);
  return repository.getClassroom(shareCode);
});

final savedClassroomsProvider =
    FutureProvider.family<List<SavedClassroomSummary>, String>((ref, ownerId) {
      return ref.watch(classroomRepositoryProvider).getMyClassrooms();
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
    final repository = command.shareCode == 'preview'
        ? ref.read(demoClassroomRepositoryProvider)
        : ref.read(classroomRepositoryProvider);
    final result = await AsyncValue.guard(
      () => repository.joinClassroom(command),
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

class DeleteClassroomController extends Notifier<AsyncValue<void>?> {
  @override
  AsyncValue<void>? build() => null;

  Future<bool> delete(String shareCode) async {
    if (state?.isLoading ?? false) return false;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(classroomRepositoryProvider).deleteMyClassroom(shareCode),
    );
    state = result;
    if (result.hasValue) ref.invalidate(savedClassroomsProvider);
    return result.hasValue;
  }
}

final deleteClassroomControllerProvider =
    NotifierProvider<DeleteClassroomController, AsyncValue<void>?>(
      DeleteClassroomController.new,
    );
