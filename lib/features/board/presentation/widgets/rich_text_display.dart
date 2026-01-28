import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Widget to display rich text content with markdown-like formatting
///
/// Supports:
/// - **bold** for bold text
/// - *italic* for italic text
/// - __underline__ for underlined text
/// - Lines starting with "• " are bullet points
class RichTextDisplay extends StatelessWidget {
  final String content;
  final TextStyle? baseStyle;
  final Color? textColor;

  const RichTextDisplay({
    super.key,
    required this.content,
    this.baseStyle,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    if (content.isEmpty) {
      return Text(
        'Double-tap to edit',
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: Colors.black38,
          fontStyle: FontStyle.italic,
          height: 1.4,
        ),
      );
    }

    final lines = content.split('\n');
    final List<Widget> lineWidgets = [];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final isBullet = line.startsWith('• ');
      final lineContent = isBullet ? line.substring(2) : line;

      if (isBullet) {
        lineWidgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• ',
                  style: _getBaseStyle(),
                ),
                Expanded(
                  child: _buildFormattedText(lineContent),
                ),
              ],
            ),
          ),
        );
      } else {
        lineWidgets.add(_buildFormattedText(line));
      }

      // Add spacing between lines except for the last one
      if (i < lines.length - 1) {
        lineWidgets.add(const SizedBox(height: 2));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: lineWidgets,
    );
  }

  TextStyle _getBaseStyle() {
    return baseStyle ??
        GoogleFonts.poppins(
          fontSize: 14,
          color: textColor ?? Colors.black87,
          height: 1.4,
        );
  }

  Widget _buildFormattedText(String text) {
    final spans = _parseFormattedText(text);
    return RichText(
      text: TextSpan(
        style: _getBaseStyle(),
        children: spans,
      ),
    );
  }

  List<TextSpan> _parseFormattedText(String text) {
    final List<TextSpan> spans = [];
    final baseStyle = _getBaseStyle();

    // Pattern order matters - check longer patterns first
    // Patterns: **bold**, *italic*, __underline__
    final RegExp formatPattern = RegExp(
      r'(\*\*[^*]+\*\*)|(__[^_]+__)|(\*[^*]+\*)',
    );

    int lastEnd = 0;
    final matches = formatPattern.allMatches(text);

    for (final match in matches) {
      // Add text before the match
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: baseStyle,
        ));
      }

      final matchedText = match.group(0)!;

      if (matchedText.startsWith('**') && matchedText.endsWith('**')) {
        // Bold
        spans.add(TextSpan(
          text: matchedText.substring(2, matchedText.length - 2),
          style: baseStyle.copyWith(fontWeight: FontWeight.bold),
        ));
      } else if (matchedText.startsWith('__') && matchedText.endsWith('__')) {
        // Underline
        spans.add(TextSpan(
          text: matchedText.substring(2, matchedText.length - 2),
          style: baseStyle.copyWith(decoration: TextDecoration.underline),
        ));
      } else if (matchedText.startsWith('*') && matchedText.endsWith('*')) {
        // Italic
        spans.add(TextSpan(
          text: matchedText.substring(1, matchedText.length - 1),
          style: baseStyle.copyWith(fontStyle: FontStyle.italic),
        ));
      }

      lastEnd = match.end;
    }

    // Add remaining text
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: baseStyle,
      ));
    }

    // If no spans were added, return the original text
    if (spans.isEmpty) {
      spans.add(TextSpan(text: text, style: baseStyle));
    }

    return spans;
  }
}
