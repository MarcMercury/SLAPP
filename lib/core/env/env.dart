import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration class
class Env {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  static String get googleProjectId => dotenv.env['GOOGLE_PROJECT_ID'] ?? '';
  static String get googleProjectNumber =>
      dotenv.env['GOOGLE_PROJECT_NUMBER'] ?? '';
  static String get openaiApiKey => dotenv.env['OPENAI_API_KEY'] ?? '';
}
