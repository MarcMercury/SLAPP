import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
  
  // Drag and drop tracking for SLAP merge
  Slap? _draggingSlap;
  Offset? _dragPosition;
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

  void _addSlap(Offset position) async {
    HapticFeedback.lightImpact();
    await ref.read(slapControllerProvider.notifier).createSlap(
      boardId: widget.boardId,
      x: position.dx,
      y: position.dy,
    );
  }

  void _handleDragStart(Slap slap) {
    setState(() {
      _draggingSlap = slap;
    });
    HapticFeedback.selectionClick();
  }

  void _handleDragUpdate(Offset position, List<Slap> allSlaps) {
    setState(() {
      _dragPosition = position;
      // Check for potential merge target
      _mergeTarget = _findMergeTarget(position, allSlaps);
    });
  }

  void _handleDragEnd(Slap slap, Offset newPosition, List<Slap> allSlaps) async {
    if (_mergeTarget != null && _mergeTarget!.id != slap.id) {
      // Perform SLAP merge!
      await _performMerge(slap, _mergeTarget!);
    } else {
      // Just update position
      await ref.read(slapControllerProvider.notifier).updatePosition(
        slap.id,
        newPosition.dx,
        newPosition.dy,
      );
    }

    setState(() {
      _draggingSlap = null;
      _dragPosition = null;
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
            data: (slaps) => InteractiveViewer(
              transformationController: _transformController,
              boundaryMargin: const EdgeInsets.all(double.infinity),
              minScale: 0.1,
              maxScale: 4.0,
              child: GestureDetector(
                onDoubleTapDown: (details) => _addSlap(details.localPosition),
                child: Container(
                  width: 5000,
                  height: 5000,
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
                                    onDragStart: () => _handleDragStart(slap),
                                    onDragUpdate: (pos) => _handleDragUpdate(pos, slaps),
                                    onDragEnd: (pos) => _handleDragEnd(slap, pos, slaps),
                                    onContentChanged: (content) {
                                      ref.read(slapControllerProvider.notifier)
                                          .updateContent(slap.id, content);
                                    },
                                    onColorTap: () => _showColorPicker(slap),
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
                        
                        // Drag indicator
                        if (_draggingSlap != null && _dragPosition != null)
                          Positioned(
                            left: _dragPosition!.dx - 100,
                            top: _dragPosition!.dy - 75,
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
              ),
            ),
          ),

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
      floatingActionButton: FloatingActionButton(
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
