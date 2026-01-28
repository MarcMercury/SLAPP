import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:slapp/core/theme/slap_colors.dart';

/// A clean, mobile-friendly bottom sheet editor for sticky notes.
/// Provides a full-width text editing experience that sits above the keyboard.
class NoteEditorSheet extends StatefulWidget {
  final String initialContent;
  final Color noteColor;
  final Function(String) onSave;
  final VoidCallback? onCancel;

  const NoteEditorSheet({
    super.key,
    required this.initialContent,
    required this.noteColor,
    required this.onSave,
    this.onCancel,
  });

  @override
  State<NoteEditorSheet> createState() => _NoteEditorSheetState();

  /// Show the editor as a modal bottom sheet
  static Future<String?> show({
    required BuildContext context,
    required String initialContent,
    required Color noteColor,
  }) async {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NoteEditorSheet(
        initialContent: initialContent,
        noteColor: noteColor,
        onSave: (content) => Navigator.of(context).pop(content),
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }
}

class _NoteEditorSheetState extends State<NoteEditorSheet> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _hasChanges = false;

  // Formatting state
  bool _isBold = false;
  bool _isItalic = false;
  bool _isUnderline = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialContent);
    _focusNode = FocusNode();
    _controller.addListener(_onTextChanged);

    // Auto-focus after the sheet is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasChanges = _controller.text != widget.initialContent;
    if (hasChanges != _hasChanges) {
      setState(() => _hasChanges = hasChanges);
    }
    _updateFormattingState();
  }

  void _updateFormattingState() {
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
      final selectedText = text.substring(selection.start, selection.end);

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
      final cursorPos = selection.baseOffset.clamp(0, text.length);
      final placeholder = '${prefix}text$suffix';
      final newText = text.substring(0, cursorPos) +
          placeholder +
          text.substring(cursorPos);
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection(
          baseOffset: cursorPos + prefix.length,
          extentOffset: cursorPos + prefix.length + 4,
        ),
      );
    }

    HapticFeedback.selectionClick();
  }

  void _toggleBullet() {
    final selection = _controller.selection;
    final text = _controller.text;
    final cursorPos = selection.baseOffset.clamp(0, text.length);

    int lineStart = cursorPos;
    while (lineStart > 0 && text[lineStart - 1] != '\n') {
      lineStart--;
    }

    final linePrefix =
        text.substring(lineStart, (lineStart + 2).clamp(0, text.length));

    if (linePrefix.startsWith('• ')) {
      final newText = text.replaceRange(lineStart, lineStart + 2, '');
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
            offset: (cursorPos - 2).clamp(0, newText.length)),
      );
    } else {
      final newText = text.replaceRange(lineStart, lineStart, '• ');
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: cursorPos + 2),
      );
    }

    HapticFeedback.selectionClick();
  }

  void _handleSave() {
    HapticFeedback.lightImpact();
    widget.onSave(_controller.text);
  }

  void _handleCancel() {
    if (_hasChanges) {
      // Show confirmation dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discard changes?'),
          content:
              const Text('You have unsaved changes. Are you sure you want to discard them?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Keep editing'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onCancel?.call();
              },
              style: TextButton.styleFrom(foregroundColor: SlapColors.error),
              child: const Text('Discard'),
            ),
          ],
        ),
      );
    } else {
      widget.onCancel?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      // Take up to 70% of screen, but adjust for keyboard
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.7,
        minHeight: 200,
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        color: widget.noteColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header with Cancel and Save buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _handleCancel,
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  'Edit Note',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                TextButton(
                  onPressed: _handleSave,
                  child: Text(
                    'Save',
                    style: GoogleFonts.poppins(
                      color: SlapColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Formatting toolbar
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _FormatButton(
                  icon: Icons.format_bold,
                  isActive: _isBold,
                  onTap: () => _applyFormatting('**', '**'),
                  tooltip: 'Bold',
                ),
                _FormatButton(
                  icon: Icons.format_italic,
                  isActive: _isItalic,
                  onTap: () => _applyFormatting('*', '*'),
                  tooltip: 'Italic',
                ),
                _FormatButton(
                  icon: Icons.format_underlined,
                  isActive: _isUnderline,
                  onTap: () => _applyFormatting('__', '__'),
                  tooltip: 'Underline',
                ),
                Container(
                  width: 1,
                  height: 24,
                  color: Colors.black26,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
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

          const SizedBox(height: 12),

          // Text input area - this expands and scrolls
          Flexible(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.black.withOpacity(0.1),
                ),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                maxLines: null,
                minLines: 3,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.black87,
                  height: 1.5,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Write your idea...',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.black38,
                  ),
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
        ],
      ),
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
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isActive
                ? SlapColors.primary.withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 22,
            color: isActive ? SlapColors.primary : Colors.black54,
          ),
        ),
      ),
    );
  }
}
