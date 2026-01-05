/// Profile model representing a user profile
class Profile {
  final String id;
  final String? phoneNumber;
  final String? username;
  final String? avatarUrl;
  final DateTime? updatedAt;

  Profile({
    required this.id,
    this.phoneNumber,
    this.username,
    this.avatarUrl,
    this.updatedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      phoneNumber: json['phone_number'] as String?,
      username: json['username'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone_number': phoneNumber,
      'username': username,
      'avatar_url': avatarUrl,
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Profile copyWith({
    String? id,
    String? phoneNumber,
    String? username,
    String? avatarUrl,
    DateTime? updatedAt,
  }) {
    return Profile(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get display name - username or phone number
  String get displayName => username ?? phoneNumber ?? 'User';

  /// Get initials for avatar
  String get initials {
    if (username != null && username!.isNotEmpty) {
      final parts = username!.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return username![0].toUpperCase();
    }
    return '?';
  }
}
