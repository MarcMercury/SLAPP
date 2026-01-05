import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:slapp/features/board/data/models/slap_model.dart';
import 'package:slapp/features/board/data/repositories/slap_repository.dart';
import 'package:slapp/features/board/data/services/ai_merge_service.dart';

part 'slap_providers.g.dart';

/// Repository provider
@riverpod
SlapRepository slapRepository(SlapRepositoryRef ref) {
  return SlapRepository();
}

/// AI merge service provider
@riverpod
AiMergeService aiMergeService(AiMergeServiceRef ref) {
  return AiMergeService();
}

/// Stream provider for realtime slaps on a board
@riverpod
Stream<List<Slap>> slapsStream(SlapsStreamRef ref, String boardId) {
  final repository = ref.watch(slapRepositoryProvider);
  return repository.watchSlaps(boardId);
}

/// Controller for slap operations
@riverpod
class SlapController extends _$SlapController {
  @override
  FutureOr<void> build() {}

  /// Create a new slap
  Future<Slap?> createSlap({
    required String boardId,
    required double x,
    required double y,
    String content = '',
    String color = 'FFFFE0',
  }) async {
    try {
      final repository = ref.read(slapRepositoryProvider);
      return await repository.createSlap(
        boardId: boardId,
        content: content,
        positionX: x,
        positionY: y,
        color: color,
      );
    } catch (e) {
      return null;
    }
  }

  /// Update slap position
  Future<void> updatePosition(String slapId, double x, double y) async {
    try {
      final repository = ref.read(slapRepositoryProvider);
      await repository.updatePosition(slapId, x, y);
    } catch (e) {
      // Handle error silently for smooth UX
    }
  }

  /// Update slap content
  Future<void> updateContent(String slapId, String content) async {
    try {
      final repository = ref.read(slapRepositoryProvider);
      await repository.updateContent(slapId, content);
    } catch (e) {
      // Handle error silently
    }
  }

  /// Update slap color
  Future<void> updateColor(String slapId, String color) async {
    try {
      final repository = ref.read(slapRepositoryProvider);
      await repository.updateColor(slapId, color);
    } catch (e) {
      // Handle error silently
    }
  }

  /// Delete a slap
  Future<void> deleteSlap(String slapId) async {
    try {
      final repository = ref.read(slapRepositoryProvider);
      await repository.deleteSlap(slapId);
    } catch (e) {
      // Handle error silently
    }
  }

  /// Merge two slaps using AI
  Future<Slap?> mergeSlaps(Slap slap1, Slap slap2) async {
    try {
      final repository = ref.read(slapRepositoryProvider);
      final aiService = ref.read(aiMergeServiceProvider);

      // Set both slaps to processing
      await Future.wait([
        repository.setProcessing(slap1.id, true),
        repository.setProcessing(slap2.id, true),
      ]);

      // Get AI merged content
      final mergedContent = await aiService.mergeIdeas(
        slap1.content,
        slap2.content,
      );

      // Create merged slap and delete originals
      return await repository.mergeSlaps(
        slap1: slap1,
        slap2: slap2,
        mergedContent: mergedContent,
      );
    } catch (e) {
      // Reset processing state on error
      final repository = ref.read(slapRepositoryProvider);
      await Future.wait([
        repository.setProcessing(slap1.id, false),
        repository.setProcessing(slap2.id, false),
      ]);
      return null;
    }
  }
}
