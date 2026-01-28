import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:slapp/core/theme/slap_colors.dart';

/// A simple rich text editor for sticky notes with basic formatting options
/// Supports: Bold, Italic, Underline, Bullet Lists
///
/// Uses markdown-like syntax for storage:
/// - **bold** for bold text
/// - *italic* for italic text
/// - __underline__ for underlined text
/// - Lines starting with "• " are bullet points
class RichTextNoteEditor extends StatefulWidget {
  final String initialContent;
  final FocusNode? focusNode;
  final Function(String) onContentChanged;
  final VoidCallback? onEditingComplete;

  const RichTextNoteEditor({
    super.key,
    required this.initialContent,
    this.focusNode,
    required this.onContentChanged,
    this.onEditingComplete,
  });

  @override
  State<RichTextNoteEditor> createState() => _RichTextNoteEditorState();
}

class _RichTextNoteEditorState extends State<RichTextNoteEditor> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isBold = false;
  bool _isItalic = false;
  bool _isUnderline = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialContent);
    _focusNode = widget.focusNode ?? FocusNode();
    _controller.addListener(_updateFormattingState);
  }

  @override
  void dispose() {
    _controller.removeListener(_updateFormattingState);
    _controller.dispose();
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _updateFormattingState() {
    // Check current selection for active formatting
    final selection = _controller.selection;
    if (selection.isValid && selection.start != selection.end) {
      final selectedText =
          _controller.text.substring(selection.start, selection.end);
      setState(() {
        _isBold = selectedText.contains('**');
        _isItalic = selectedText.contains('*') && !selectedText.contains('**');
        _isUnderline = selectedText.contains('__');
      });
    }
  }

  void _applyFormatting(String prefix, String suffix) {
    final selection = _controller.selection;
    final text = _controller.text;

    if (selection.isValid && selection.start != selection.end) {
      // Text is selected - wrap it
      final selectedText = text.substring(selection.start, selection.end);

      // Check if already formatted - if so, remove formatting
      if (selectedText.startsWith(prefix) && selectedText.endsWith(suffix)) {
        final unformatted = selectedText.substring(
            prefix.length, selectedText.length - suffix.length);
        final newText =
            text.replaceRange(selection.start, selection.end, unformatted);
        _controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(
              offset: selection.start + unformatted.length),
        );
      } else {
        final formatted = '$prefix$selectedText$suffix';
        final newText =
            text.replaceRange(selection.start, selection.end, formatted);
        _controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(
              offset: selection.start + formatted.length),
        );
      }
    } else {
      // No selection - insert placeholder
      final cursorPos = selection.baseOffset.clamp(0, text.length);
      final placeholder = '${prefix}text$suffix';
      final newText = text.substring(0, cursorPos) +
          placeholder +
          text.substring(cursorPos);
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection(
          baseOffset: cursorPos + prefix.length,
          extentOffset: cursorPos + prefix.length + 4, // Select "text"
        ),
      );
    }

    HapticFeedback.selectionClick();
    widget.onContentChanged(_controller.text);

    // Ensure focus is restored after the frame is built
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  void _toggleBold() => _applyFormatting('**', '**');
  void _toggleItalic() => _applyFormatting('*', '*');
  void _toggleUnderline() => _applyFormatting('__', '__');

  void _toggleBullet() {
    final selection = _controller.selection;
    final text = _controller.text;
    final cursorPos = selection.baseOffset.clamp(0, text.length);

    // Find the start of the current line
    int lineStart = cursorPos;
    while (lineStart > 0 && text[lineStart - 1] != '\n') {
      lineStart--;
    }

    // Check if line already starts with bullet
    final linePrefix =
        text.substring(lineStart, (lineStart + 2).clamp(0, text.length));

    if (linePrefix.startsWith('• ')) {
      // Remove bullet
      final newText = text.replaceRange(lineStart, lineStart + 2, '');
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
            offset: (cursorPos - 2).clamp(0, newText.length)),
      );
    } else {
      // Add bullet
      final newText = text.replaceRange(lineStart, lineStart, '• ');
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: cursorPos + 2),
      );
    }

    HapticFeedback.selectionClick();
    widget.onContentChanged(_controller.text);

    // Ensure focus is restored after the frame is built
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Formatting toolbar with Done button
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _FormatButton(
                      icon: Icons.format_bold,
                      isActive: _isBold,
                      onTap: _toggleBold,
                      tooltip: 'Bold',
                    ),
                    _FormatButton(
                      icon: Icons.format_italic,
                      isActive: _isItalic,
                      onTap: _toggleItalic,
                      tooltip: 'Italic',
                    ),
                    _FormatButton(
                      icon: Icons.format_underlined,
                      isActive: _isUnderline,
                      onTap: _toggleUnderline,
                      tooltip: 'Underline',
                    ),
                    Container(
                      width: 1,
                      height: 20,
                      color: Colors.black26,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    _FormatButton(
                      icon: Icons.format_list_bulleted,
                      isActive: false,
                      onTap: _toggleBullet,
                      tooltip: 'Bullet List',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Done button
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                widget.onEditingComplete?.call();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: SlapColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Done',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Text field
        Expanded(
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black87,
              height: 1.4,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Write your idea...',
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: widget.onContentChanged,
            onEditingComplete: widget.onEditingComplete,
            // Note: onTapOutside is handled at the parent level to avoid
            // exiting edit mode when tapping formatting buttons
          ),
        ),
      ],
    );
  }
}

class _FormatButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final String tooltip;

  const _FormatButton({
    required this.icon,
    required this.isActive,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isActive
                ? SlapColors.primary.withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isActive ? SlapColors.primary : Colors.black54,
          ),
        ),
      ),
    );
  }
}
