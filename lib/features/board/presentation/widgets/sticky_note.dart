import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:slapp/core/theme/slap_colors.dart';
import 'package:slapp/features/board/data/models/slap_model.dart';

/// Sticky note widget with drag, edit, and SLAP merge support
class StickyNote extends StatefulWidget {
  final Slap slap;
  final bool isHighlighted;
  final bool isDragging;
  final VoidCallback onDragStart;
  final Function(Offset) onDragUpdate;
  final Function(Offset) onDragEnd;
  final Function(String) onContentChanged;
  final VoidCallback onLongPress;

  const StickyNote({
    super.key,
    required this.slap,
    this.isHighlighted = false,
    this.isDragging = false,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onContentChanged,
    required this.onLongPress,
  });

  @override
  State<StickyNote> createState() => _StickyNoteState();
}

class _StickyNoteState extends State<StickyNote>
    with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isEditing = false;
  Offset _startPosition = Offset.zero;
  Offset _currentGlobalPosition = Offset.zero;

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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(StickyNote oldWidget) {
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
    setState(() => _isEditing = true);
    _focusNode.requestFocus();
    HapticFeedback.selectionClick();
  }

  void _finishEditing() {
    if (_controller.text != widget.slap.content) {
      widget.onContentChanged(_controller.text);
    }
    setState(() => _isEditing = false);
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final noteColor = SlapColors.fromHex(widget.slap.color);
    
    return GestureDetector(
      onLongPress: () {
        HapticFeedback.mediumImpact();
        widget.onLongPress();
      },
      onDoubleTap: _startEditing,
      onPanStart: (details) {
        if (_isEditing) return;
        _startPosition = Offset(widget.slap.positionX, widget.slap.positionY);
        _currentGlobalPosition = details.globalPosition;
        widget.onDragStart();
        _animController.forward();
        HapticFeedback.lightImpact();
      },
      onPanUpdate: (details) {
        if (_isEditing) return;
        final delta = details.globalPosition - _currentGlobalPosition;
        _currentGlobalPosition = details.globalPosition;
        _startPosition = _startPosition + delta;
        widget.onDragUpdate(_startPosition);
      },
      onPanEnd: (details) {
        if (_isEditing) return;
        widget.onDragEnd(_startPosition);
        _animController.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            boxShadow: widget.isHighlighted
                ? [
                    BoxShadow(
                      color: SlapColors.accent.withOpacity(0.5),
                      blurRadius: 15,
                      spreadRadius: 3,
                    ),
                  ]
                : null,
          ),
          child: Container(
            width: 200,
            constraints: const BoxConstraints(minHeight: 150),
            decoration: BoxDecoration(
              color: noteColor,
              borderRadius: BorderRadius.circular(4),
              border: widget.isHighlighted
                  ? Border.all(color: SlapColors.accent, width: 2)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(widget.isDragging ? 0.3 : 0.2),
                  blurRadius: widget.isDragging ? 12 : 8,
                  offset: widget.isDragging 
                      ? const Offset(4, 4) 
                      : const Offset(2, 2),
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
                
                // Merge indicator badge
                if (widget.isHighlighted)
                  Positioned(
                    top: -8,
                    left: -8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: SlapColors.accent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: SlapColors.accent.withOpacity(0.4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        size: 16,
                        color: Colors.white,
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
                          mainAxisSize: MainAxisSize.min,
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
                
                // Drag hint icon
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Icon(
                    Icons.drag_indicator,
                    size: 16,
                    color: Colors.black.withOpacity(0.2),
                  ),
                ),
              ],
            ),
          ),
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
