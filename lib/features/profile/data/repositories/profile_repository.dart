import 'package:slapp/features/profile/data/models/profile_model.dart';
import 'package:slapp/main.dart';

/// Repository for profile-related database operations
class ProfileRepository {
  /// Get current user's profile
  Future<Profile?> getCurrentProfile() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return null;
    return Profile.fromJson(response);
  }

  /// Get a profile by user ID
  Future<Profile?> getProfile(String userId) async {
    final response = await supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

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

    final response = await supabase
        .from('profiles')
        .upsert(data)
        .select()
        .single();

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
}
