import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:slapp/core/env/env.dart';

/// Service for AI-powered slap merging using OpenAI
class AiMergeService {
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';

  /// Merge two ideas using AI
  Future<String> mergeIdeas(String idea1, String idea2) async {
    final apiKey = Env.openaiApiKey;
    if (apiKey.isEmpty) {
      // Fallback to simple concatenation if no API key
      return _simpleMerge(idea1, idea2);
    }

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'system',
              'content': '''You are an idea synthesis assistant for a collaborative brainstorming app called SLAP. 
When users drag sticky notes on top of each other (a "SLAP"), you merge their ideas into something new and creative.

Rules:
- Create a single, concise merged idea (max 2-3 sentences)
- Combine the essence of both ideas creatively
- The result should feel like a natural evolution or synthesis
- Keep it actionable and inspiring
- Don't just concatenate - truly integrate the concepts'''
            },
            {
              'role': 'user',
              'content': '''SLAP! These two ideas have been combined:

Idea 1: "$idea1"

Idea 2: "$idea2"

Create a merged idea that synthesizes both:'''
            }
          ],
          'max_tokens': 150,
          'temperature': 0.8,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        return content.trim();
      } else {
        // Fallback on API error
        return _simpleMerge(idea1, idea2);
      }
    } catch (e) {
      // Fallback on any error
      return _simpleMerge(idea1, idea2);
    }
  }

  /// Simple fallback merge without AI
  String _simpleMerge(String idea1, String idea2) {
    if (idea1.isEmpty && idea2.isEmpty) {
      return 'Combined idea';
    }
    if (idea1.isEmpty) return idea2;
    if (idea2.isEmpty) return idea1;
    return '💡 $idea1 + $idea2';
  }
}
