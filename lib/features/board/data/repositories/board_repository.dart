import 'dart:async';
import 'package:slapp/features/board/data/models/board_model.dart';
import 'package:slapp/main.dart';

/// Repository for board-related database operations
class BoardRepository {
  /// Fetch all boards the current user is a member of
  Future<List<Board>> getBoards() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await supabase
        .from('boards')
        .select('''
          *,
          member_count:board_members(count)
        ''')
        .order('created_at', ascending: false);

    return (response as List).map((json) {
      // Extract member count from nested count query
      final memberCount = json['member_count']?[0]?['count'] ?? 1;
      return Board.fromJson({
        ...json,
        'member_count': memberCount,
      });
    }).toList();
  }

  /// Get a single board by ID
  Future<Board?> getBoard(String boardId) async {
    final response = await supabase
        .from('boards')
        .select()
        .eq('id', boardId)
        .maybeSingle();

    if (response == null) return null;
    return Board.fromJson(response);
  }

  /// Create a new board using SECURITY DEFINER function
  Future<Board> createBoard(String name) async {
    final userId = supabase.auth.currentUser?.id;
    print('[BoardRepository] createBoard called, userId: $userId');
    
    if (userId == null) {
      print('[BoardRepository] ERROR: User not authenticated');
      throw Exception('User not authenticated');
    }

    try {
      // Use RPC function to create board with member in single transaction
      final response = await supabase
          .rpc('create_board_with_member', params: {'board_name': name});
      
      print('[BoardRepository] Board created: ${response['id']}');
      return Board.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('[BoardRepository] ERROR creating board: $e');
      rethrow;
    }
  }

  /// Update a board
  Future<void> updateBoard(String boardId, {String? name}) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;

    if (updates.isNotEmpty) {
      await supabase.from('boards').update(updates).eq('id', boardId);
    }
  }

  /// Delete a board
  Future<void> deleteBoard(String boardId) async {
    await supabase.from('boards').delete().eq('id', boardId);
  }

  /// Invite a user to a board by phone number
  Future<void> inviteMember(String boardId, String phoneNumber) async {
    // First, find the user by phone number
    final profileResponse = await supabase
        .from('profiles')
        .select('id')
        .eq('phone_number', phoneNumber)
        .maybeSingle();

    if (profileResponse == null) {
      throw Exception('User with phone number $phoneNumber not found');
    }

    final userId = profileResponse['id'] as String;

    // Add them to the board
    await supabase.from('board_members').insert({
      'board_id': boardId,
      'user_id': userId,
      'role': 'member',
    });
  }

  /// Get board members
  Future<List<Map<String, dynamic>>> getBoardMembers(String boardId) async {
    final response = await supabase
        .from('board_members')
        .select('''
          role,
          profiles:user_id (
            id,
            username,
            phone_number,
            avatar_url
          )
        ''')
        .eq('board_id', boardId);

    return List<Map<String, dynamic>>.from(response);
  }
}
