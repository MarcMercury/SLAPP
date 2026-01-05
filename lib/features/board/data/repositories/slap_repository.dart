import 'dart:async';
import 'package:slapp/features/board/data/models/slap_model.dart';
import 'package:slapp/main.dart';

/// Repository for slap (sticky note) database operations
class SlapRepository {
  /// Fetch all slaps for a board
  Future<List<Slap>> getSlaps(String boardId) async {
    final response = await supabase
        .from('slaps')
        .select()
        .eq('board_id', boardId)
        .order('created_at', ascending: true);

    return (response as List).map((json) => Slap.fromJson(json)).toList();
  }

  /// Create a new slap
  Future<Slap> createSlap({
    required String boardId,
    required String content,
    required double positionX,
    required double positionY,
    String color = 'FFFFE0',
  }) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await supabase
        .from('slaps')
        .insert({
          'board_id': boardId,
          'user_id': userId,
          'content': content,
          'position_x': positionX,
          'position_y': positionY,
          'color': color,
        })
        .select()
        .single();

    return Slap.fromJson(response);
  }

  /// Update a slap's position
  Future<void> updatePosition(String slapId, double x, double y) async {
    await supabase.from('slaps').update({
      'position_x': x,
      'position_y': y,
    }).eq('id', slapId);
  }

  /// Update a slap's content
  Future<void> updateContent(String slapId, String content) async {
    await supabase.from('slaps').update({
      'content': content,
    }).eq('id', slapId);
  }

  /// Update a slap's color
  Future<void> updateColor(String slapId, String color) async {
    await supabase.from('slaps').update({
      'color': color,
    }).eq('id', slapId);
  }

  /// Set processing state (for AI merging)
  Future<void> setProcessing(String slapId, bool isProcessing) async {
    await supabase.from('slaps').update({
      'is_processing': isProcessing,
    }).eq('id', slapId);
  }

  /// Delete a slap
  Future<void> deleteSlap(String slapId) async {
    print('[SlapRepository] deleteSlap called with id: $slapId');
    await supabase.from('slaps').delete().eq('id', slapId);
    print('[SlapRepository] deleteSlap completed');
  }

  /// Subscribe to realtime slap changes for a board
  Stream<List<Slap>> watchSlaps(String boardId) {
    return supabase
        .from('slaps')
        .stream(primaryKey: ['id'])
        .eq('board_id', boardId)
        .order('created_at')
        .map((data) => data.map((json) => Slap.fromJson(json)).toList());
  }

  /// Merge two slaps (delete both and create new with merged content)
  Future<Slap> mergeSlaps({
    required Slap slap1,
    required Slap slap2,
    required String mergedContent,
  }) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Calculate center position between the two slaps
    final centerX = (slap1.positionX + slap2.positionX) / 2;
    final centerY = (slap1.positionY + slap2.positionY) / 2;

    // Store original slap data for potential separation later
    final mergedFrom = [
      {
        'content': slap1.content,
        'color': slap1.color,
        'position_x': slap1.positionX,
        'position_y': slap1.positionY,
      },
      {
        'content': slap2.content,
        'color': slap2.color,
        'position_x': slap2.positionX,
        'position_y': slap2.positionY,
      },
    ];

    // Delete both original slaps
    await Future.wait([
      deleteSlap(slap1.id),
      deleteSlap(slap2.id),
    ]);

    // Create new merged slap with original data stored
    final response = await supabase
        .from('slaps')
        .insert({
          'board_id': slap1.boardId,
          'user_id': userId,
          'content': mergedContent,
          'position_x': centerX,
          'position_y': centerY,
          'color': 'FFD166', // Use accent color for merged slaps
          'merged_from': mergedFrom,
        })
        .select()
        .single();

    return Slap.fromJson(response);
  }

  /// Separate a merged slap back into its original notes
  Future<List<Slap>> separateSlap(Slap mergedSlap) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    if (mergedSlap.mergedFrom == null || mergedSlap.mergedFrom!.isEmpty) {
      throw Exception('This note was not merged and cannot be separated');
    }

    final separatedSlaps = <Slap>[];
    
    // Recreate original slaps with slight offset
    for (var i = 0; i < mergedSlap.mergedFrom!.length; i++) {
      final original = mergedSlap.mergedFrom![i];
      final offsetX = (i == 0) ? -30.0 : 30.0; // Offset left and right
      
      final response = await supabase
          .from('slaps')
          .insert({
            'board_id': mergedSlap.boardId,
            'user_id': userId,
            'content': original['content'] ?? '',
            'position_x': (original['position_x'] as num?)?.toDouble() ?? 
                          mergedSlap.positionX + offsetX,
            'position_y': (original['position_y'] as num?)?.toDouble() ?? 
                          mergedSlap.positionY,
            'color': original['color'] ?? 'FFFFE0',
          })
          .select()
          .single();
      
      separatedSlaps.add(Slap.fromJson(response));
    }

    // Delete the merged slap
    await deleteSlap(mergedSlap.id);

    return separatedSlaps;
  }
}
