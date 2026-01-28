import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:slapp/features/profile/data/models/profile_model.dart';
import 'package:slapp/features/profile/data/repositories/profile_repository.dart';

part 'profile_providers.g.dart';

/// Provider for ProfileRepository
@riverpod
ProfileRepository profileRepository(Ref ref) {
  return ProfileRepository();
}

/// Provider for current user's profile
@riverpod
Future<Profile?> currentProfile(Ref ref) async {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getCurrentProfile();
}

/// Provider for user activity stats
@riverpod
Future<Map<String, int>> userActivityStats(Ref ref) async {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getUserActivityStats();
}

/// Controller for profile operations
@riverpod
class ProfileController extends _$ProfileController {
  @override
  FutureOr<Profile?> build() async {
    return ref.watch(profileRepositoryProvider).getCurrentProfile();
  }

  /// Update the user's username
  Future<void> updateUsername(String username) async {
    state = const AsyncLoading();
    try {
      await ref.read(profileRepositoryProvider).updateUsername(username);
      ref.invalidateSelf();
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  /// Update the user's avatar
  Future<void> updateAvatar(String avatarUrl) async {
    state = const AsyncLoading();
    try {
      await ref.read(profileRepositoryProvider).updateAvatar(avatarUrl);
      ref.invalidateSelf();
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  /// Create or update the full profile
  Future<Profile?> upsertProfile({
    String? username,
    String? avatarUrl,
  }) async {
    state = const AsyncLoading();
    try {
      final profile = await ref.read(profileRepositoryProvider).upsertProfile(
            username: username,
            avatarUrl: avatarUrl,
          );
      state = AsyncData(profile);
      return profile;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return null;
    }
  }
}
