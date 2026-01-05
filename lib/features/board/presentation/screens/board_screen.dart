import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:slapp/core/theme/slap_colors.dart';
import 'package:slapp/features/board/application/board_providers.dart';
import 'package:slapp/features/board/application/slap_providers.dart';
import 'package:slapp/features/board/data/models/slap_model.dart';
import 'package:slapp/features/board/presentation/widgets/board_members_sheet.dart';
import 'package:slapp/features/board/presentation/widgets/sticky_note_enhanced.dart';

/// The main board screen - an infinite canvas with sticky notes
class BoardScreen extends ConsumerStatefulWidget {
  final String boardId;

  const BoardScreen({super.key, required this.boardId});

  @override
  ConsumerState<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends ConsumerState<BoardScreen>
    with TickerProviderStateMixin {
  final TransformationController _transformController = TransformationController();
  final GlobalKey _boardKey = GlobalKey();
  
  // Drag and drop tracking for SLAP merge
  Slap? _draggingSlap;
  Offset? _dragPosition; // In board-local coordinates
  Offset? _dragStartOffset; // Offset from note origin to touch point
  Slap? _mergeTarget;
  
  // Animation for merge effect
  late AnimationController _mergeAnimController;
  late Animation<double> _mergeAnimation;
  bool _isMerging = false;

  @override
  void initState() {
    super.initState();
    _mergeAnimController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _mergeAnimation = CurvedAnimation(
      parent: _mergeAnimController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _transformController.dispose();
    _mergeAnimController.dispose();
    super.dispose();
  }

  // Board constants
  static const double _boardWidth = 10000;
  static const double _boardHeight = 10000;
  static const double _noteWidth = 200;
  static const double _noteHeight = 150;
  static const double _padding = 20;

  /// Zoom in by 20%
  void _zoomIn() {
    final currentScale = _transformController.value.getMaxScaleOnAxis();
    final newScale = (currentScale * 1.2).clamp(0.1, 4.0);
    _animateZoom(newScale);
  }

  /// Zoom out by 20%
  void _zoomOut() {
    final currentScale = _transformController.value.getMaxScaleOnAxis();
    final newScale = (currentScale * 0.8).clamp(0.1, 4.0);
    _animateZoom(newScale);
  }

  /// Animate zoom to target scale
  void _animateZoom(double targetScale) {
    final currentMatrix = _transformController.value;
    final currentScale = currentMatrix.getMaxScaleOnAxis();
    
    // Scale from center of viewport
    final viewportCenter = Offset(
      MediaQuery.of(context).size.width / 2,
      MediaQuery.of(context).size.height / 2,
    );
    
    final scaleChange = targetScale / currentScale;
    final newMatrix = currentMatrix.clone()
      ..translate(viewportCenter.dx, viewportCenter.dy)
      ..scale(scaleChange)
      ..translate(-viewportCenter.dx, -viewportCenter.dy);
    
    _transformController.value = newMatrix;
  }

  /// Fit view to show all notes or center on board
  void _fitToView() {
    // Reset to show the initial area of the board
    _transformController.value = Matrix4.identity()
      ..translate(-100.0, -100.0); // Start with some padding
  }

  /// Constrain position to keep note within board bounds
  Offset _constrainPosition(double x, double y) {
    return Offset(
      x.clamp(_padding, _boardWidth - _noteWidth - _padding),
      y.clamp(_padding, _boardHeight - _noteHeight - _padding),
    );
  }

  void _addSlap(Offset position) async {
    HapticFeedback.lightImpact();
    // Constrain position to board bounds
    final constrained = _constrainPosition(position.dx, position.dy);
    await ref.read(slapControllerProvider.notifier).createSlap(
      boardId: widget.boardId,
      x: constrained.dx,
      y: constrained.dy,
    );
  }

  void _handleDragStart(Slap slap, Offset globalPosition) {
    // Convert global position to board-local coordinates
    final localPos = _globalToLocal(globalPosition);
    // Calculate offset from note's top-left corner to touch point
    final offsetFromNote = Offset(
      localPos.dx - slap.positionX,
      localPos.dy - slap.positionY,
    );
    setState(() {
      _draggingSlap = slap;
      _dragStartOffset = offsetFromNote;
      _dragPosition = Offset(slap.positionX, slap.positionY);
    });
    HapticFeedback.selectionClick();
  }

  /// Convert global screen coordinates to board-local coordinates
  Offset _globalToLocal(Offset globalPosition) {
    // Get the RenderBox for the board
    final RenderBox? box = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return globalPosition;
    
    // Convert global to widget-local
    final localPoint = box.globalToLocal(globalPosition);
    
    // Apply inverse of transform to get board coordinates
    final matrix = _transformController.value;
    final inverted = Matrix4.inverted(matrix);
    final transformed = MatrixUtils.transformPoint(inverted, localPoint);
    
    return transformed;
  }

  void _handleDragUpdate(Offset globalPosition, List<Slap> allSlaps) {
    // Convert global position to board-local coordinates
    final localPos = _globalToLocal(globalPosition);
    // Calculate note position by subtracting the initial offset
    final notePos = Offset(
      localPos.dx - (_dragStartOffset?.dx ?? 0),
      localPos.dy - (_dragStartOffset?.dy ?? 0),
    );
    setState(() {
      _dragPosition = notePos;
      // Check for potential merge target using the center of the note
      final centerPos = Offset(notePos.dx + 100, notePos.dy + 75);
      _mergeTarget = _findMergeTarget(centerPos, allSlaps);
    });
  }

  void _handleDragEnd(Slap slap, List<Slap> allSlaps) async {
    final finalPosition = _dragPosition ?? Offset(slap.positionX, slap.positionY);
    
    if (_mergeTarget != null && _mergeTarget!.id != slap.id) {
      // Perform SLAP merge!
      await _performMerge(slap, _mergeTarget!);
    } else {
      // Constrain position to board bounds
      final constrained = _constrainPosition(finalPosition.dx, finalPosition.dy);
      await ref.read(slapControllerProvider.notifier).updatePosition(
        slap.id,
        constrained.dx,
        constrained.dy,
      );
    }

    setState(() {
      _draggingSlap = null;
      _dragPosition = null;
      _dragStartOffset = null;
      _mergeTarget = null;
    });
  }

  Slap? _findMergeTarget(Offset position, List<Slap> slaps) {
    const noteWidth = 200.0;
    const noteHeight = 150.0;
    const overlapThreshold = 50.0; // pixels overlap needed

    for (final slap in slaps) {
      if (slap.id == _draggingSlap?.id) continue;
      if (slap.isProcessing) continue;

      // Check if position is within this slap's bounds
      if (position.dx >= slap.positionX - overlapThreshold &&
          position.dx <= slap.positionX + noteWidth + overlapThreshold &&
          position.dy >= slap.positionY - overlapThreshold &&
          position.dy <= slap.positionY + noteHeight + overlapThreshold) {
        return slap;
      }
    }
    return null;
  }

  Future<void> _performMerge(Slap source, Slap target) async {
    setState(() => _isMerging = true);
    HapticFeedback.heavyImpact();
    
    // Show merge animation
    _mergeAnimController.forward(from: 0);
    
    // Perform the AI merge
    final mergedSlap = await ref.read(slapControllerProvider.notifier).mergeSlaps(
      source,
      target,
    );

    // Force refresh the slaps stream to remove deleted slaps
    ref.invalidate(slapsStreamProvider(widget.boardId));

    if (mergedSlap != null && mounted) {
      // Show success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(child: Text('Ideas merged with AI! ✨')),
            ],
          ),
          backgroundColor: SlapColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }

    setState(() => _isMerging = false);
  }

  void _showBoardOptions(String boardName) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _BoardOptionsSheet(
        boardId: widget.boardId,
        boardName: boardName,
        onInvite: () {
          Navigator.pop(context);
          _showInviteDialog();
        },
        onViewMembers: () {
          Navigator.pop(context);
          showBoardMembersSheet(
            context,
            boardId: widget.boardId,
            boardName: boardName,
          );
        },
        onDelete: () {
          Navigator.pop(context);
          _confirmDeleteBoard();
        },
      ),
    );
  }

  void _confirmDeleteBoard() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: SlapColors.error),
            SizedBox(width: 12),
            Text('Delete Board'),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this board? All slaps will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: SlapColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(boardControllerProvider.notifier).deleteBoard(widget.boardId);
      if (mounted) {
        context.go('/');
      }
    }
  }

  void _showInviteDialog() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Invite Member'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Phone Number',
            hintText: '+1 (555) 123-4567',
            prefixIcon: const Icon(Icons.phone),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final phone = controller.text.trim();
              if (phone.isNotEmpty) {
                Navigator.pop(context);
                await ref.read(boardControllerProvider.notifier).inviteMember(
                  widget.boardId,
                  phone,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Invitation sent to $phone'),
                      backgroundColor: SlapColors.success,
                    ),
                  );
                }
              }
            },
            child: const Text('Invite'),
          ),
        ],
      ),
    );
  }

  void _showColorPicker(Slap slap) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose Color',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: SlapColors.noteColors.asMap().entries.map((entry) {
                final color = entry.value;
                final hexColor = SlapColors.noteColorHex[entry.key];
                final isSelected = slap.color == hexColor;
                
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    ref.read(slapControllerProvider.notifier).updateColor(
                      slap.id,
                      hexColor,
                    );
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: SlapColors.primary, width: 3)
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: SlapColors.primary)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showVoiceRecorder(Slap slap) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _VoiceRecorderSheet(
        slap: slap,
        onTextRecorded: (text) {
          // Append recorded text to existing content
          final newContent = slap.content.isEmpty 
              ? text 
              : '${slap.content}\n$text';
          ref.read(slapControllerProvider.notifier).updateContent(
            slap.id,
            newContent,
          );
        },
      ),
    );
  }

  Future<void> _separateSlap(Slap slap) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Separate Notes?'),
        content: const Text(
          'This will split this merged note back into its original separate notes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: SlapColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Separate'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    HapticFeedback.mediumImpact();

    final separatedSlaps = await ref
        .read(slapControllerProvider.notifier)
        .separateSlap(slap);

    // Force refresh
    ref.invalidate(slapsStreamProvider(widget.boardId));

    if (separatedSlaps != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.call_split, color: Colors.white),
              const SizedBox(width: 12),
              Text('Split into ${separatedSlaps.length} notes'),
            ],
          ),
          backgroundColor: SlapColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final boardAsync = ref.watch(boardProvider(widget.boardId));
    final slapsStream = ref.watch(slapsStreamProvider(widget.boardId));
    
    // Get board name for options sheet
    final boardName = boardAsync.valueOrNull?.name ?? 'Board';

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: boardAsync.when(
          data: (board) => Text(
            board?.name ?? 'Board',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('Board'),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.people_outline),
            onPressed: () => _showBoardOptions(boardName),
            tooltip: 'Board Members',
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showBoardOptions(boardName),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main canvas
          slapsStream.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('Error loading slaps: $err'),
                  TextButton(
                    onPressed: () => ref.invalidate(slapsStreamProvider(widget.boardId)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (slaps) => Container(
              key: _boardKey,
              child: InteractiveViewer(
                transformationController: _transformController,
                boundaryMargin: const EdgeInsets.all(double.infinity),
                minScale: 0.1,
                maxScale: 4.0,
                constrained: false,
                child: GestureDetector(
                  // Only create slap if double-tapping empty area (not on a note)
                  onDoubleTap: () {},
                  onDoubleTapDown: (details) {
                    // Check if tap is on an existing slap
                    final pos = details.localPosition;
                    final onSlap = slaps.any((slap) {
                      final slapRect = Rect.fromLTWH(
                        slap.positionX,
                        slap.positionY,
                        200, // note width
                        150, // note min height
                      );
                      return slapRect.contains(pos);
                    });
                    // Only create new slap if not tapping on existing one
                    if (!onSlap) {
                      _addSlap(pos);
                    }
                  },
                  child: Container(
                  // Large board: ~10ft x 10ft equivalent for ample space
                  width: _boardWidth,
                  height: _boardHeight,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                  ),
                  child: CustomPaint(
                    painter: _GridPainter(
                      isDark: Theme.of(context).brightness == Brightness.dark,
                    ),
                    child: Stack(
                      children: [
                        // Render all slaps
                        ...slaps.map((slap) {
                          final isTarget = _mergeTarget?.id == slap.id;
                          final isDragging = _draggingSlap?.id == slap.id;
                          
                          return Positioned(
                            left: slap.positionX,
                            top: slap.positionY,
                            child: AnimatedScale(
                              scale: isTarget ? 1.1 : 1.0,
                              duration: const Duration(milliseconds: 150),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                decoration: isTarget
                                    ? BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color: SlapColors.primary.withOpacity(0.5),
                                            blurRadius: 20,
                                            spreadRadius: 5,
                                          ),
                                        ],
                                      )
                                    : null,
                                child: Opacity(
                                  opacity: isDragging ? 0.5 : 1.0,
                                  child: StickyNoteEnhanced(
                                    slap: slap,
                                    onDragStart: (globalPos) => _handleDragStart(slap, globalPos),
                                    onDragUpdate: (pos) => _handleDragUpdate(pos, slaps),
                                    onDragEnd: () => _handleDragEnd(slap, slaps),
                                    onContentChanged: (content) {
                                      ref.read(slapControllerProvider.notifier)
                                          .updateContent(slap.id, content);
                                    },
                                    onColorTap: () => _showColorPicker(slap),
                                    onMicTap: () => _showVoiceRecorder(slap),
                                    onSeparateTap: slap.isMerged ? () => _separateSlap(slap) : null,
                                    onDelete: () {
                                      ref.read(slapControllerProvider.notifier)
                                          .deleteSlap(slap.id);
                                    },
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                        
                        // Drag indicator (follows the note position)
                        if (_draggingSlap != null && _dragPosition != null)
                          Positioned(
                            left: _dragPosition!.dx,
                            top: _dragPosition!.dy,
                            child: IgnorePointer(
                              child: Container(
                                width: 200,
                                height: 150,
                                decoration: BoxDecoration(
                                  color: SlapColors.fromHex(_draggingSlap!.color)
                                      .withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _mergeTarget != null
                                        ? SlapColors.primary
                                        : Colors.transparent,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: _mergeTarget != null
                                      ? Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.merge,
                                              size: 32,
                                              color: SlapColors.primary,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'SLAP!',
                                              style: GoogleFonts.fredoka(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: SlapColors.primary,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Text(
                                          _draggingSlap!.content.isEmpty
                                              ? '...'
                                              : _draggingSlap!.content,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.black54,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ), // GestureDetector
            ), // InteractiveViewer
          ), // Container with _boardKey
          ), // slapsStream.when

          // Loading overlay during merge
          if (_isMerging)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: SlapColors.primary),
                      const SizedBox(height: 16),
                      Text(
                        'Merging ideas with AI...',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Help tooltip
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Double-tap to add • Drag to merge (SLAP!)',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Zoom controls
          FloatingActionButton.small(
            heroTag: 'zoom_in',
            onPressed: _zoomIn,
            backgroundColor: Colors.white,
            foregroundColor: SlapColors.primary,
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'zoom_out',
            onPressed: _zoomOut,
            backgroundColor: Colors.white,
            foregroundColor: SlapColors.primary,
            child: const Icon(Icons.remove),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'fit_view',
            onPressed: _fitToView,
            backgroundColor: Colors.white,
            foregroundColor: SlapColors.primary,
            child: const Icon(Icons.fit_screen),
          ),
          const SizedBox(height: 16),
          // Add note button
          FloatingActionButton(
            heroTag: 'add_note',
            onPressed: () {
              final matrix = _transformController.value;
              final offset = Offset(
                -matrix.getTranslation().x / matrix.getMaxScaleOnAxis() + 200,
                -matrix.getTranslation().y / matrix.getMaxScaleOnAxis() + 200,
              );
              _addSlap(offset);
            },
            backgroundColor: SlapColors.primary,
            foregroundColor: Colors.white,
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

/// Grid background painter
class _GridPainter extends CustomPainter {
  final bool isDark;
  
  _GridPainter({this.isDark = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark ? Colors.grey.shade800 : Colors.grey.shade200
      ..strokeWidth = 1;

    const gridSize = 40.0;

    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Board options bottom sheet
class _BoardOptionsSheet extends StatelessWidget {
  final String boardId;
  final String boardName;
  final VoidCallback onInvite;
  final VoidCallback onViewMembers;
  final VoidCallback onDelete;

  const _BoardOptionsSheet({
    required this.boardId,
    required this.boardName,
    required this.onInvite,
    required this.onViewMembers,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFE3F2FD),
              child: Icon(Icons.person_add, color: Colors.blue),
            ),
            title: const Text('Invite Members'),
            subtitle: const Text('Share via phone number'),
            onTap: onInvite,
          ),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFE8F5E9),
              child: Icon(Icons.groups, color: Colors.green),
            ),
            title: const Text('View Members'),
            subtitle: const Text('See who\'s on this board'),
            onTap: onViewMembers,
          ),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFFCE4EC),
              child: Icon(Icons.delete_outline, color: Colors.red),
            ),
            title: const Text('Delete Board'),
            subtitle: const Text('Remove this board permanently'),
            onTap: onDelete,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Voice recorder bottom sheet for speech-to-text
class _VoiceRecorderSheet extends StatefulWidget {
  final Slap slap;
  final Function(String) onTextRecorded;

  const _VoiceRecorderSheet({
    required this.slap,
    required this.onTextRecorded,
  });

  @override
  State<_VoiceRecorderSheet> createState() => _VoiceRecorderSheetState();
}

class _VoiceRecorderSheetState extends State<_VoiceRecorderSheet> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _isInitialized = false;
  String _recognizedText = '';
  String _errorMessage = '';
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
  }

  Future<void> _initializeSpeech() async {
    setState(() {
      _statusMessage = 'Initializing speech recognition...';
    });
    
    try {
      _isInitialized = await _speech.initialize(
        onStatus: (status) {
          print('[Speech] Status: $status');
          if (mounted) {
            setState(() {
              _statusMessage = 'Status: $status';
              if (status == 'done' || status == 'notListening') {
                _isListening = false;
              }
            });
          }
        },
        onError: (error) {
          print('[Speech] Error: ${error.errorMsg}');
          if (mounted) {
            setState(() {
              _errorMessage = 'Error: ${error.errorMsg}';
              _isListening = false;
            });
          }
        },
        debugLogging: true, // Enable debug logging
      );
      
      print('[Speech] Initialized: $_isInitialized');
      print('[Speech] Has permission: ${_speech.hasPermission}');
      
      if (mounted) {
        setState(() {
          if (_isInitialized) {
            _statusMessage = 'Ready! Tap the mic to start.';
          } else {
            _errorMessage = 'Speech recognition not available on this device/browser';
          }
        });
      }
    } catch (e) {
      print('[Speech] Init exception: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not initialize: $e';
        });
      }
    }
  }

  Future<void> _startListening() async {
    if (!_isInitialized) {
      setState(() {
        _errorMessage = 'Speech recognition not available. Try using Chrome browser.';
      });
      return;
    }

    setState(() {
      _recognizedText = '';
      _errorMessage = '';
      _statusMessage = 'Starting...';
      _isListening = true; // Set this early for UI feedback
    });

    try {
      // Check available locales
      final locales = await _speech.locales();
      print('[Speech] Available locales: ${locales.map((l) => l.localeId).toList()}');
      
      // Find an English locale or use the system default
      String? localeId;
      for (final locale in locales) {
        if (locale.localeId.startsWith('en')) {
          localeId = locale.localeId;
          break;
        }
      }
      localeId ??= locales.isNotEmpty ? locales.first.localeId : null;
      
      print('[Speech] Using locale: $localeId');
      print('[Speech] isListening before: ${_speech.isListening}');
      
      await _speech.listen(
        onResult: (result) {
          print('[Speech] Result: ${result.recognizedWords} (final: ${result.finalResult})');
          if (mounted) {
            setState(() {
              _recognizedText = result.recognizedWords;
              _statusMessage = result.finalResult ? 'Done!' : 'Listening...';
            });
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
        localeId: localeId,
        onSoundLevelChange: (level) {
          // This shows us the mic is working
          print('[Speech] Sound level: $level');
        },
      );
      
      // Small delay to let speech recognition actually start
      await Future.delayed(const Duration(milliseconds: 100));
      
      print('[Speech] isListening after: ${_speech.isListening}');
      print('[Speech] isAvailable: ${_speech.isAvailable}');
      
      if (!_speech.isListening && mounted) {
        setState(() {
          _errorMessage = 'Speech recognition failed to start. Make sure microphone permissions are granted.';
          _isListening = false;
        });
      } else if (mounted) {
        setState(() {
          _statusMessage = 'Listening... Speak now!';
        });
      }
    } catch (e) {
      print('[Speech] Listen exception: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to start: $e';
          _isListening = false;
        });
      }
    }
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }

  void _saveText() {
    if (_recognizedText.isNotEmpty) {
      widget.onTextRecorded(_recognizedText);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added: "$_recognizedText"'),
          backgroundColor: SlapColors.success,
        ),
      );
    }
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Voice Recording',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isInitialized 
                ? 'Tap the microphone to start speaking'
                : 'Initializing...',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          if (!_isInitialized && _errorMessage.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '(Works best in Chrome or Edge)',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade400,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          const SizedBox(height: 24),
          
          // Microphone button
          GestureDetector(
            onTap: _isListening ? _stopListening : _startListening,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: _isListening ? 100 : 80,
              height: _isListening ? 100 : 80,
              decoration: BoxDecoration(
                color: _isListening ? Colors.red : SlapColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (_isListening ? Colors.red : SlapColors.primary)
                        .withOpacity(0.4),
                    blurRadius: _isListening ? 20 : 10,
                    spreadRadius: _isListening ? 5 : 0,
                  ),
                ],
              ),
              child: Icon(
                _isListening ? Icons.stop : Icons.mic,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Status message
          if (_statusMessage.isNotEmpty && !_isListening)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _statusMessage,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          
          if (_isListening)
            Text(
              _statusMessage.isNotEmpty ? _statusMessage : 'Listening...',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          
          if (_errorMessage.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage,
                      style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          if (_recognizedText.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recognized Text:',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _recognizedText,
                    style: GoogleFonts.poppins(fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() => _recognizedText = '');
                    },
                    child: const Text('Clear'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveText,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SlapColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Add to Note'),
                  ),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
