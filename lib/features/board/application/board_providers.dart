import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:slapp/features/board/data/models/board_model.dart';
import 'package:slapp/features/board/data/repositories/board_repository.dart';

part 'board_providers.g.dart';

/// Repository provider
@riverpod
BoardRepository boardRepository(BoardRepositoryRef ref) {
  return BoardRepository();
}

/// Provider for fetching all boards
@riverpod
Future<List<Board>> boards(BoardsRef ref) async {
  final repository = ref.watch(boardRepositoryProvider);
  return repository.getBoards();
}

/// Provider for a single board
@riverpod
Future<Board?> board(BoardRef ref, String boardId) async {
  final repository = ref.watch(boardRepositoryProvider);
  return repository.getBoard(boardId);
}

/// Controller for board operations
@riverpod
class BoardController extends _$BoardController {
  @override
  FutureOr<void> build() {}

  /// Create a new board
  Future<Board?> createBoard(String name) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(boardRepositoryProvider);
      final board = await repository.createBoard(name);
      // Invalidate boards list to refresh
      ref.invalidate(boardsProvider);
      state = const AsyncData(null);
      return board;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  /// Delete a board
  Future<void> deleteBoard(String boardId) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(boardRepositoryProvider);
      await repository.deleteBoard(boardId);
      ref.invalidate(boardsProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Invite a member to a board
  Future<void> inviteMember(String boardId, String phoneNumber) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(boardRepositoryProvider);
      await repository.inviteMember(boardId, phoneNumber);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
