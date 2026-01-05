/// BoardMember model representing a member of a board
class BoardMember {
  final String odId;
  final String role; // 'admin' or 'member'
  final String? username;
  final String? phoneNumber;
  final String? avatarUrl;

  BoardMember({
    required this.odId,
    required this.role,
    this.username,
    this.phoneNumber,
    this.avatarUrl,
  });

  factory BoardMember.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    
    return BoardMember(
      odId: profile?['id'] as String? ?? '',
      role: json['role'] as String? ?? 'member',
      username: profile?['username'] as String?,
      phoneNumber: profile?['phone_number'] as String?,
      avatarUrl: profile?['avatar_url'] as String?,
    );
  }

  /// Get display name
  String get displayName => username ?? phoneNumber ?? 'Unknown User';

  /// Get initials for avatar
  String get initials {
    if (username != null && username!.isNotEmpty) {
      final parts = username!.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return username![0].toUpperCase();
    }
    if (phoneNumber != null && phoneNumber!.isNotEmpty) {
      return phoneNumber!.substring(phoneNumber!.length - 2);
    }
    return '?';
  }

  /// Check if this member is an admin
  bool get isAdmin => role == 'admin';
}
