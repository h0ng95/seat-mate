import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../classroom/application/classroom_providers.dart';
import '../domain/signed_in_user.dart';

final authUserProvider = StreamProvider<SignedInUser?>((ref) async* {
  final config = ref.watch(appConfigProvider);
  if (!config.hasSupabase) {
    yield null;
    return;
  }

  final auth = Supabase.instance.client.auth;
  yield _mapUser(auth.currentUser);
  await for (final event in auth.onAuthStateChange) {
    yield _mapUser(event.session?.user);
  }
});

class AuthController extends Notifier<AsyncValue<void>?> {
  @override
  AsyncValue<void>? build() => null;

  Future<void> signInWithKakao({String redirectPath = '/create'}) async {
    if (state?.isLoading ?? false) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final config = ref.read(appConfigProvider);
      final baseUrl = config.baseUrl.replaceFirst(RegExp(r'/$'), '');
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.kakao,
        redirectTo: '$baseUrl$redirectPath',
        scopes: 'profile_nickname',
      );
    });
  }

  Future<void> signOut() async {
    if (state?.isLoading ?? false) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => Supabase.instance.client.auth.signOut(),
    );
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AsyncValue<void>?>(AuthController.new);

SignedInUser? _mapUser(User? user) {
  if (user == null) return null;
  final metadata = user.userMetadata ?? const <String, dynamic>{};
  final displayName = _firstText(metadata, const [
    'user_name',
    'name',
    'nickname',
    'preferred_username',
  ]);
  final avatarUrl = _firstText(metadata, const [
    'avatar_url',
    'picture',
    'profile_image_url',
  ]);
  return SignedInUser(
    id: user.id,
    displayName: displayName ?? '카카오 사용자',
    avatarUrl: avatarUrl,
  );
}

String? _firstText(Map<String, dynamic> metadata, List<String> keys) {
  for (final key in keys) {
    final value = metadata[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
  }
  return null;
}
