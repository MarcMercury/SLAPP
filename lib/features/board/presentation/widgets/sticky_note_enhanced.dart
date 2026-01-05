import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:slapp/core/theme/slap_colors.dart';
import 'package:slapp/features/board/data/models/slap_model.dart';

/// Enhanced sticky note widget with drag, edit, and color support
class StickyNoteEnhanced extends StatefulWidget {
  final Slap slap;
  final Function(Offset) onDragStart; // Pass global position
  final Function(Offset) onDragUpdate;
  final VoidCallback onDragEnd; // No position needed - parent tracks it
  final Function(String) onContentChanged;
  final VoidCallback onColorTap;
  final VoidCallback onDelete;
  final VoidCallback onMicTap;
  final VoidCallback? onSeparateTap; // Optional - only shown for merged notes

  const StickyNoteEnhanced({
    super.key,
    required this.slap,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onContentChanged,
    required this.onColorTap,
    required this.onDelete,
    required this.onMicTap,
    this.onSeparateTap,
  });

  @override
  State<StickyNoteEnhanced> createState() => _StickyNoteEnhancedState();
}

class _StickyNoteEnhancedState extends State<StickyNoteEnhanced>
    with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isEditing = false;
  bool _showOptions = false;
  Offset _startPosition = Offset.zero;
  Offset _currentPosition = Offset.zero;

  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.slap.content);
    _focusNode = FocusNode();
    
    _animController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(StickyNoteEnhanced oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slap.content != widget.slap.content && !_isEditing) {
      _controller.text = widget.slap.content;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
      _showOptions = false;
    });
    _focusNode.requestFocus();
    HapticFeedback.selectionClick();
  }

  void _finishEditing() {
    if (_controller.text != widget.slap.content) {
      widget.onContentChanged(_controller.text);
    }
    setState(() => _isEditing = false);
  }

  void _toggleOptions() {
    setState(() => _showOptions = !_showOptions);
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final noteColor = SlapColors.fromHex(widget.slap.color);
    
    // Build the main note that can be dragged
    Widget buildMainNote() {
      return Container(
        width: 200,
        constraints: const BoxConstraints(minHeight: 150),
        decoration: BoxDecoration(
          color: noteColor,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(widget.slap.isProcessing ? 0.1 : 0.2),
              blurRadius: widget.slap.isProcessing ? 4 : 8,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Corner fold effect
            Positioned(
              top: 0,
              right: 0,
              child: CustomPaint(
                size: const Size(24, 24),
                painter: _FoldPainter(noteColor),
              ),
            ),
            
            // Processing indicator
            if (widget.slap.isProcessing)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: SlapColors.primary,
                    ),
                  ),
                ),
              ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: _isEditing
                  ? TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      maxLines: null,
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
                      onEditingComplete: _finishEditing,
                      onTapOutside: (_) => _finishEditing(),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.slap.content.isEmpty
                              ? 'Double-tap to edit'
                              : widget.slap.content,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: widget.slap.content.isEmpty
                                ? Colors.black38
                                : Colors.black87,
                            fontStyle: widget.slap.content.isEmpty
                                ? FontStyle.italic
                                : FontStyle.normal,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      );
    }

    // Main widget structure with proper gesture isolation
    // When options are shown, we need a larger hit test area
    if (_showOptions) {
      return SizedBox(
        width: 320, // 200 + 60 on each side
        height: 220, // 150 + 70 for menu
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Tap anywhere else to close - MUST be first (behind everything)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _showOptions = false),
              ),
            ),
            
            // The draggable/tappable note - positioned to account for menu space
            Positioned(
              top: 70, // Space for menu above
              left: 60, // Space on left
              child: IgnorePointer(
                ignoring: true,
                child: buildMainNote(),
              ),
            ),
            
            // Options menu - rendered on top, positioned at top center
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Center(
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildOptionButton(
                          icon: Icons.edit,
                          color: Colors.black87,
                          label: 'Edit',
                          onTap: () {
                            setState(() => _showOptions = false);
                            _startEditing();
                          },
                        ),
                        _buildOptionButton(
                          icon: Icons.mic,
                          color: SlapColors.primary,
                          label: 'Voice',
                          onTap: () {
                            setState(() => _showOptions = false);
                            widget.onMicTap();
                          },
                        ),
                        _buildOptionButton(
                          icon: Icons.palette,
                          color: Colors.orange,
                          label: 'Color',
                          onTap: () {
                            setState(() => _showOptions = false);
                            widget.onColorTap();
                          },
                        ),
                        // Show Separate button only for merged notes
                        if (widget.slap.isMerged && widget.onSeparateTap != null)
                          _buildOptionButton(
                            icon: Icons.call_split,
                            color: Colors.blue,
                            label: 'Split',
                            onTap: () {
                              setState(() => _showOptions = false);
                              widget.onSeparateTap!();
                            },
                          ),
                        _buildOptionButton(
                          icon: Icons.delete,
                          color: SlapColors.error,
                          label: 'Delete',
                          onTap: () {
                            print('[StickyNote] Delete button tapped for slap: ${widget.slap.id}');
                            setState(() => _showOptions = false);
                            widget.onDelete();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    // Normal state without options
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // The draggable/tappable note
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onLongPress: _toggleOptions,
          onDoubleTap: () {
            _startEditing();
          },
          onPanStart: (details) {
            if (_isEditing) return;
            // Pass global position to parent for coordinate conversion
            widget.onDragStart(details.globalPosition);
            _animController.forward();
          },
          onPanUpdate: (details) {
            if (_isEditing) return;
            // Pass global position to parent for coordinate conversion
            widget.onDragUpdate(details.globalPosition);
          },
          onPanEnd: (details) {
            if (_isEditing) return;
            // Parent tracks position, just notify drag ended
            widget.onDragEnd();
            _animController.reverse();
          },
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: buildMainNote(),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    // Use InkWell for proper tap handling
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for the corner fold effect
class _FoldPainter extends CustomPainter {
  final Color noteColor;

  _FoldPainter(this.noteColor);

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(0, 0)
      ..lineTo(size.width, size.height)
      ..close();

    final paint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);

    // Draw shadow under fold
    final shadowPath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    canvas.drawPath(shadowPath, shadowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
