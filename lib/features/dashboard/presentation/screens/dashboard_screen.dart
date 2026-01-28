import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:slapp/core/theme/slap_colors.dart';
import 'package:slapp/core/widgets/slap_logo.dart';
import 'package:slapp/core/widgets/welcome_dialog.dart';
import 'package:slapp/features/auth/application/auth_providers.dart';
import 'package:slapp/features/board/application/board_providers.dart';
import 'package:slapp/features/board/data/models/board_model.dart';
import 'package:slapp/features/profile/application/profile_providers.dart';

/// Dashboard screen showing list of boards with branded UI
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  bool _hasShownWelcome = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _showWelcomeIfNeeded() async {
    if (_hasShownWelcome) return;

    final isFirst = await ref.read(isFirstLoginProvider.future);
    if (isFirst && mounted) {
      _hasShownWelcome = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => WelcomeDialog(
          onComplete: () => Navigator.pop(context),
        ),
      );
    }
  }

  void _createBoard() {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: SlapColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.dashboard_customize,
                  color: SlapColors.primary),
            ),
            const SizedBox(width: 12),
            const Text('New Board'),
          ],
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a board name';
              }
              return null;
            },
            decoration: InputDecoration(
              labelText: 'Board Name',
              hintText: 'e.g., Project Ideas',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
            ),
            onFieldSubmitted: (_) =>
                _submitCreateBoard(formKey, controller, dialogContext),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                _submitCreateBoard(formKey, controller, dialogContext),
            style: FilledButton.styleFrom(
              backgroundColor: SlapColors.primary,
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitCreateBoard(
    GlobalKey<FormState> formKey,
    TextEditingController controller,
    BuildContext dialogContext,
  ) async {
    if (!formKey.currentState!.validate()) return;

    final name = controller.text.trim();
    Navigator.of(dialogContext).pop();

    try {
      final board =
          await ref.read(boardControllerProvider.notifier).createBoard(name);

      if (board != null && mounted) {
        context.go('/board/${board.id}');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create board'),
            backgroundColor: SlapColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: SlapColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showProfile() {
    context.go('/profile');
  }

  Widget _buildProfileButton() {
    final profileAsync = ref.watch(profileControllerProvider);

    return IconButton(
      onPressed: _showProfile,
      icon: profileAsync.when(
        loading: () => CircleAvatar(
          radius: 20,
          backgroundColor: SlapColors.primary.withOpacity(0.1),
          child: const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (_, __) => CircleAvatar(
          radius: 20,
          backgroundColor: SlapColors.primary.withOpacity(0.1),
          child: const Icon(Icons.person, color: SlapColors.primary),
        ),
        data: (profile) {
          final avatar = profile?.avatarUrl;
          if (avatar != null && avatar.isNotEmpty) {
            return CircleAvatar(
              radius: 20,
              backgroundColor: SlapColors.primary.withOpacity(0.1),
              child: Text(
                avatar,
                style: const TextStyle(fontSize: 24),
              ),
            );
          }
          return CircleAvatar(
            radius: 20,
            backgroundColor: SlapColors.primary.withOpacity(0.1),
            child: const Icon(Icons.person, color: SlapColors.primary),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check for first login to show welcome
    WidgetsBinding.instance.addPostFrameCallback((_) => _showWelcomeIfNeeded());

    final boardsAsync = ref.watch(boardsProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Custom app bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const SlapLogo(size: 40),
                    const Spacer(),
                    _buildProfileButton(),
                  ],
                ),
              ),
            ),

            // Welcome message
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Boards',
                      style: GoogleFonts.fredoka(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap a board to start collaborating',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Boards list
            boardsAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text('Failed to load boards',
                          style: TextStyle(color: Colors.grey.shade600)),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => ref.invalidate(boardsProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (boards) {
                if (boards.isEmpty) {
                  return SliverFillRemaining(
                    child: _buildEmptyState(),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.1,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _BoardCard(
                        board: boards[index],
                        index: index,
                        animation: _animController,
                      ),
                      childCount: boards.length,
                    ),
                  ),
                );
              },
            ),

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createBoard,
        backgroundColor: SlapColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Board'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated sticky notes
            Stack(
              alignment: Alignment.center,
              children: [
                Transform.rotate(
                  angle: -0.1,
                  child: _buildMiniNote(SlapColors.noteColors[0]),
                ),
                Transform.rotate(
                  angle: 0.05,
                  child: _buildMiniNote(SlapColors.noteColors[1]),
                ),
                Transform.rotate(
                  angle: 0.15,
                  child: _buildMiniNote(SlapColors.noteColors[2]),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'No boards yet!',
              style: GoogleFonts.fredoka(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first board and start\nSLAPPing ideas together',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _createBoard,
              icon: const Icon(Icons.add),
              label: const Text('Create First Board'),
              style: FilledButton.styleFrom(
                backgroundColor: SlapColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniNote(Color color) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(2, 2),
          ),
        ],
      ),
    );
  }
}

/// Board card widget with staggered animation
class _BoardCard extends StatelessWidget {
  final Board board;
  final int index;
  final AnimationController animation;

  const _BoardCard({
    required this.board,
    required this.index,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final delay = index * 0.1;
    final slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Interval(delay, delay + 0.5, curve: Curves.easeOut),
    ));

    final fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: animation,
        curve: Interval(delay, delay + 0.5, curve: Curves.easeOut),
      ),
    );

    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: GestureDetector(
          onTap: () => context.go('/board/${board.id}'),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  SlapColors.noteColors[index % SlapColors.noteColors.length],
                  SlapColors.noteColors[index % SlapColors.noteColors.length]
                      .withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Corner fold effect
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          Colors.grey.shade300,
                          SlapColors
                              .noteColors[index % SlapColors.noteColors.length],
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                      ),
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.dashboard_rounded,
                        size: 32,
                        color: Colors.black54,
                      ),
                      const Spacer(),
                      Text(
                        board.name,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.people,
                              size: 14, color: Colors.black45),
                          const SizedBox(width: 4),
                          Text(
                            '${board.memberCount} member${board.memberCount != 1 ? 's' : ''}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
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
