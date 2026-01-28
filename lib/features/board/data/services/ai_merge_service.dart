import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:slapp/core/env/env.dart';

/// Service for AI-powered slap merging using Supabase Edge Function
class AiMergeService {
  /// Merge two ideas using AI via Supabase Edge Function
  Future<String> mergeIdeas(String idea1, String idea2) async {
    try {
      // Call Supabase Edge Function to avoid CORS issues
      final response = await http.post(
        Uri.parse('${Env.supabaseUrl}/functions/v1/merge-ideas'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${Env.supabaseAnonKey}',
        },
        body: jsonEncode({
          'idea1': idea1,
          'idea2': idea2,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['merged'] as String? ?? _simpleMerge(idea1, idea2);
      } else {
        // Fallback on API error
        debugPrint(
            '[AiMergeService] Edge function error: ${response.statusCode} - ${response.body}');
        return _simpleMerge(idea1, idea2);
      }
    } catch (e) {
      // Fallback on any error
      debugPrint('[AiMergeService] Error: $e');
      return _simpleMerge(idea1, idea2);
    }
  }

  /// Simple fallback merge without AI
  /// Creates a more synthesized-looking output
  String _simpleMerge(String idea1, String idea2) {
    if (idea1.isEmpty && idea2.isEmpty) {
      return 'Combined idea';
    }
    if (idea1.isEmpty) return idea2;
    if (idea2.isEmpty) return idea1;

    // Create a more thoughtful combination
    // Remove common filler words and combine meaningfully
    final clean1 = idea1.trim();
    final clean2 = idea2.trim();

    // Check if ideas are short (single words or phrases)
    if (clean1.split(' ').length <= 3 && clean2.split(' ').length <= 3) {
      return '💡 Combine "$clean1" with "$clean2" - explore how these concepts work together';
    }

    // For longer ideas, create a synthesis prompt
    return '✨ Synthesis: $clean1\n\n↔️ Connected with: $clean2\n\n💭 Consider how these ideas reinforce or complement each other.';
  }
}
