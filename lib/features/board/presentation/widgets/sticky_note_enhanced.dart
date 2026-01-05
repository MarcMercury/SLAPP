import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:slapp/core/theme/slap_colors.dart';
import 'package:slapp/features/board/data/models/slap_model.dart';

/// Enhanced sticky note widget with drag, edit, and color support
class StickyNoteEnhanced extends StatefulWidget {
  final Slap slap;
  final VoidCallback onDragStart;
  final Function(Offset) onDragUpdate;
  final Function(Offset) onDragEnd;
  final Function(String) onContentChanged;
  final VoidCallback onColorTap;
  final VoidCallback onDelete;
  final VoidCallback onMicTap;

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

    // Build options menu - separate from gesture handling
    Widget buildOptionsMenu() {
      return Positioned(
        top: -50,
        left: 0,
        right: 0,
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildOptionButton(
                    icon: Icons.edit,
                    color: Colors.black54,
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
                    color: Colors.black54,
                    label: 'Color',
                    onTap: () {
                      setState(() => _showOptions = false);
                      widget.onColorTap();
                    },
                  ),
                  _buildOptionButton(
                    icon: Icons.delete,
                    color: SlapColors.error,
                    label: 'Delete',
                    onTap: () {
                      setState(() => _showOptions = false);
                      widget.onDelete();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Main widget structure with proper gesture isolation
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
            _startPosition = Offset(widget.slap.positionX, widget.slap.positionY);
            _currentPosition = details.globalPosition;
            widget.onDragStart();
            _animController.forward();
          },
          onPanUpdate: (details) {
            if (_isEditing) return;
            final delta = details.globalPosition - _currentPosition;
            _currentPosition = details.globalPosition;
            final newPosition = _startPosition + delta;
            _startPosition = newPosition;
            widget.onDragUpdate(details.globalPosition);
          },
          onPanEnd: (details) {
            if (_isEditing) return;
            widget.onDragEnd(_startPosition);
            _animController.reverse();
          },
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: buildMainNote(),
          ),
        ),
        
        // Options menu - OUTSIDE of GestureDetector so taps work!
        if (_showOptions) buildOptionsMenu(),
      ],
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w500,
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
