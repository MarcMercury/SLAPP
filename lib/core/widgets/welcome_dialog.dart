import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:slapp/core/theme/slap_colors.dart';

/// Welcome dialog shown to new users
class WelcomeDialog extends StatefulWidget {
  final VoidCallback onComplete;

  const WelcomeDialog({super.key, required this.onComplete});

  @override
  State<WelcomeDialog> createState() => _WelcomeDialogState();
}

class _WelcomeDialogState extends State<WelcomeDialog> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_WelcomeStep> _steps = [
    _WelcomeStep(
      icon: Icons.sticky_note_2_outlined,
      title: 'Create Notes',
      description:
          'Tap anywhere on the board to create a sticky note. Add your ideas, thoughts, and inspirations.',
      color: SlapColors.noteColors[0],
    ),
    _WelcomeStep(
      icon: Icons.groups_outlined,
      title: 'Collaborate',
      description:
          'Invite your team by phone number. Everyone sees changes in real-time.',
      color: SlapColors.noteColors[2],
    ),
    _WelcomeStep(
      icon: Icons.back_hand,
      title: 'SLAP to Merge!',
      description:
          'Drag one note onto another to SLAP them together. Our AI will merge the ideas into something new!',
      color: SlapColors.primary,
      isHighlight: true,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 340,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Page indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_steps.length, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? SlapColors.primary
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),
            // Content
            SizedBox(
              height: 280,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _steps.length,
                itemBuilder: (context, index) {
                  final step = _steps[index];
                  return _buildStep(step);
                },
              ),
            ),
            const SizedBox(height: 24),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: widget.onComplete,
                  child: Text(
                    'Skip',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
                FilledButton(
                  onPressed: _nextPage,
                  style: FilledButton.styleFrom(
                    backgroundColor: SlapColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    _currentPage == _steps.length - 1 ? 'Get Started!' : 'Next',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(_WelcomeStep step) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Icon container
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: step.color.withOpacity(step.isHighlight ? 1.0 : 0.2),
            shape: BoxShape.circle,
            boxShadow: step.isHighlight
                ? [
                    BoxShadow(
                      color: step.color.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ]
                : null,
          ),
          child: Icon(
            step.icon,
            size: 48,
            color: step.isHighlight ? Colors.white : step.color,
          ),
        ),
        const SizedBox(height: 24),
        // Title
        Text(
          step.title,
          style: GoogleFonts.fredoka(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: step.isHighlight ? SlapColors.primary : null,
          ),
        ),
        const SizedBox(height: 12),
        // Description
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            step.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _WelcomeStep {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final bool isHighlight;

  _WelcomeStep({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    this.isHighlight = false,
  });
}

/// Show the welcome dialog
Future<void> showWelcomeDialog(BuildContext context) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => WelcomeDialog(
      onComplete: () => Navigator.of(context).pop(),
    ),
  );
}
