/// App-wide constants
abstract class AppConstants {
  /// App name
  static const String appName = 'SLAP';

  /// App description
  static const String appDescription =
      'The Big Board - WhatsApp for Sticky Notes';

  /// Default sticky note colors (hex without #)
  static const List<String> stickyNoteColors = [
    'FFFFE0', // Light Yellow
    'FFB6C1', // Light Pink
    '90EE90', // Light Green
    'ADD8E6', // Light Blue
    'DDA0DD', // Plum
    'FFDAB9', // Peach Puff
    'E6E6FA', // Lavender
    'F0E68C', // Khaki
  ];

  /// Default sticky note color
  static const String defaultStickyColor = 'FFFFE0';

  /// Board member roles
  static const String roleAdmin = 'admin';
  static const String roleMember = 'member';
}
