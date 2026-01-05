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
    await supabase.from('slaps').delete().eq('id', slapId);
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

    // Delete both original slaps
    await Future.wait([
      deleteSlap(slap1.id),
      deleteSlap(slap2.id),
    ]);

    // Create new merged slap
    final response = await supabase
        .from('slaps')
        .insert({
          'board_id': slap1.boardId,
          'user_id': userId,
          'content': mergedContent,
          'position_x': centerX,
          'position_y': centerY,
          'color': 'FFD166', // Use accent color for merged slaps
        })
        .select()
        .single();

    return Slap.fromJson(response);
  }
}
