/// Board model representing a collaborative whiteboard
class Board {
  final String id;
  final String name;
  final String createdBy;
  final DateTime createdAt;
  final int memberCount;

  Board({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.createdAt,
    this.memberCount = 1,
  });

  factory Board.fromJson(Map<String, dynamic> json) {
    return Board(
      id: json['id'] as String,
      name: json['name'] as String,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      memberCount: json['member_count'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Board copyWith({
    String? id,
    String? name,
    String? createdBy,
    DateTime? createdAt,
    int? memberCount,
  }) {
    return Board(
      id: id ?? this.id,
      name: name ?? this.name,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      memberCount: memberCount ?? this.memberCount,
    );
  }
}
