import 'package:slapp/features/profile/data/models/profile_model.dart';
import 'package:slapp/main.dart';

/// Repository for profile-related database operations
class ProfileRepository {
  /// Get current user's profile
  Future<Profile?> getCurrentProfile() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final response =
        await supabase.from('profiles').select().eq('id', userId).maybeSingle();

    if (response == null) return null;
    return Profile.fromJson(response);
  }

  /// Get a profile by user ID
  Future<Profile?> getProfile(String userId) async {
    final response =
        await supabase.from('profiles').select().eq('id', userId).maybeSingle();

    if (response == null) return null;
    return Profile.fromJson(response);
  }

  /// Create or update the current user's profile
  Future<Profile> upsertProfile({
    String? username,
    String? avatarUrl,
  }) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final phoneNumber = supabase.auth.currentUser?.phone;

    final data = {
      'id': userId,
      'phone_number': phoneNumber,
      'username': username,
      'avatar_url': avatarUrl,
      'updated_at': DateTime.now().toIso8601String(),
    };

    final response =
        await supabase.from('profiles').upsert(data).select().single();

    return Profile.fromJson(response);
  }

  /// Update username only
  Future<void> updateUsername(String username) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await supabase.from('profiles').update({
      'username': username,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  /// Update avatar URL
  Future<void> updateAvatar(String avatarUrl) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await supabase.from('profiles').update({
      'avatar_url': avatarUrl,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  /// Search profiles by phone number (for inviting to boards)
  Future<List<Profile>> searchByPhone(String phoneNumber) async {
    final response = await supabase
        .from('profiles')
        .select()
        .ilike('phone_number', '%$phoneNumber%')
        .limit(10);

    return (response as List).map((json) => Profile.fromJson(json)).toList();
  }

  /// Get user activity stats (boards, slaps, merges)
  Future<Map<String, int>> getUserActivityStats() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return {'boards': 0, 'slaps': 0, 'merges': 0};

    try {
      // Get board count - boards where user is creator
      final boardsResponse =
          await supabase.from('boards').select('id').eq('created_by', userId);
      final boardCount = (boardsResponse as List).length;

      // Get slaps count - all slaps created by user
      final slapsResponse =
          await supabase.from('slaps').select('id').eq('user_id', userId);
      final slapCount = (slapsResponse as List).length;

      // Get merge count - slaps with merged_from not null
      final mergesResponse = await supabase
          .from('slaps')
          .select('id')
          .eq('user_id', userId)
          .not('merged_from', 'is', null);
      final mergeCount = (mergesResponse as List).length;

      return {
        'boards': boardCount,
        'slaps': slapCount,
        'merges': mergeCount,
      };
    } catch (e) {
      return {'boards': 0, 'slaps': 0, 'merges': 0};
    }
  }
}
