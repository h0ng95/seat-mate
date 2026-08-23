import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/app_config.dart';
import '../data/active_classroom_storage.dart';
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

final activeClassroomStorageProvider = Provider<ActiveClassroomStorage>(
  (ref) => MemoryActiveClassroomStorage(),
);

class ActiveClassroomController extends Notifier<String?> {
  @override
  String? build() => ref.watch(activeClassroomStorageProvider).read();

  void remember(String shareCode) {
    state = shareCode;
    ref.read(activeClassroomStorageProvider).write(shareCode);
  }

  void forget(String shareCode) {
    if (state != shareCode) return;
    state = null;
    ref.read(activeClassroomStorageProvider).clear();
  }

  void clear() {
    state = null;
    ref.read(activeClassroomStorageProvider).clear();
  }
}

final activeClassroomShareCodeProvider =
    NotifierProvider<ActiveClassroomController, String?>(
      ActiveClassroomController.new,
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
    FutureProvider.family<List<SavedClassroomSummary>, String>((
      ref,
      ownerId,
    ) async {
      final classrooms = await ref
          .watch(classroomRepositoryProvider)
          .getMyClassrooms();
      if (classrooms.isNotEmpty) {
        ref
            .read(activeClassroomShareCodeProvider.notifier)
            .remember(classrooms.first.shareCode);
      }
      return classrooms;
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
    if (result.value case final classroom?) {
      ref
          .read(activeClassroomShareCodeProvider.notifier)
          .remember(classroom.shareCode);
      ref.invalidate(savedClassroomsProvider);
    }
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
    if (result.hasValue) {
      ref.read(activeClassroomShareCodeProvider.notifier).forget(shareCode);
      ref.invalidate(savedClassroomsProvider);
    }
    return result.hasValue;
  }
}

final deleteClassroomControllerProvider =
    NotifierProvider<DeleteClassroomController, AsyncValue<void>?>(
      DeleteClassroomController.new,
    );
