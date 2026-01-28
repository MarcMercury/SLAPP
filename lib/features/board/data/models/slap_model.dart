/// Slap model representing a sticky note on the board
class Slap {
  final String id;
  final String boardId;
  final String userId;
  final String content;
  final double positionX;
  final double positionY;
  final String color;
  final bool isProcessing;
  final DateTime createdAt;
  final List<Map<String, dynamic>>?
      mergedFrom; // Stores original notes data for separation

  Slap({
    required this.id,
    required this.boardId,
    required this.userId,
    required this.content,
    required this.positionX,
    required this.positionY,
    this.color = 'FFFFE0',
    this.isProcessing = false,
    required this.createdAt,
    this.mergedFrom,
  });

  /// Check if this note was created from a merge
  bool get isMerged => mergedFrom != null && mergedFrom!.isNotEmpty;

  factory Slap.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>>? mergedFrom;
    if (json['merged_from'] != null) {
      mergedFrom = (json['merged_from'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }

    return Slap(
      id: json['id'] as String,
      boardId: json['board_id'] as String,
      userId: json['user_id'] as String? ?? '',
      content: json['content'] as String? ?? '',
      positionX: (json['position_x'] as num?)?.toDouble() ?? 0.0,
      positionY: (json['position_y'] as num?)?.toDouble() ?? 0.0,
      color: json['color'] as String? ?? 'FFFFE0',
      isProcessing: json['is_processing'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      mergedFrom: mergedFrom,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'board_id': boardId,
      'user_id': userId,
      'content': content,
      'position_x': positionX,
      'position_y': positionY,
      'color': color,
      'is_processing': isProcessing,
      'created_at': createdAt.toIso8601String(),
      'merged_from': mergedFrom,
    };
  }

  /// For insert operations (without id and created_at)
  Map<String, dynamic> toInsertJson() {
    return {
      'board_id': boardId,
      'user_id': userId,
      'content': content,
      'position_x': positionX,
      'position_y': positionY,
      'color': color,
      'is_processing': isProcessing,
      'merged_from': mergedFrom,
    };
  }

  Slap copyWith({
    String? id,
    String? boardId,
    String? userId,
    String? content,
    double? positionX,
    double? positionY,
    String? color,
    bool? isProcessing,
    DateTime? createdAt,
    List<Map<String, dynamic>>? mergedFrom,
  }) {
    return Slap(
      id: id ?? this.id,
      boardId: boardId ?? this.boardId,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
      color: color ?? this.color,
      isProcessing: isProcessing ?? this.isProcessing,
      createdAt: createdAt ?? this.createdAt,
      mergedFrom: mergedFrom ?? this.mergedFrom,
    );
  }

  /// Check if this slap overlaps with another (for SLAP merging)
  bool overlapssWith(Slap other) {
    const noteWidth = 200.0;
    const noteHeight = 150.0;
    const overlapThreshold = 0.5; // 50% overlap required

    final thisRight = positionX + noteWidth;
    final thisBottom = positionY + noteHeight;
    final otherRight = other.positionX + noteWidth;
    final otherBottom = other.positionY + noteHeight;

    // Calculate overlap area
    final overlapX = (thisRight.clamp(other.positionX, otherRight) -
            positionX.clamp(other.positionX, otherRight))
        .clamp(0.0, noteWidth);
    final overlapY = (thisBottom.clamp(other.positionY, otherBottom) -
            positionY.clamp(other.positionY, otherBottom))
        .clamp(0.0, noteHeight);

    final overlapArea = overlapX * overlapY;
    const thisArea = noteWidth * noteHeight;

    return overlapArea / thisArea >= overlapThreshold;
  }
}
