import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:slapp/core/theme/slap_colors.dart';

/// SLAP branded logo widget
class SlapLogo extends StatelessWidget {
  final double size;
  final bool showTagline;

  const SlapLogo({
    super.key,
    this.size = 48,
    this.showTagline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo with hand slap icon
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Hand icon representing "slap"
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: SlapColors.primary,
                borderRadius: BorderRadius.circular(size * 0.2),
                boxShadow: [
                  BoxShadow(
                    color: SlapColors.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.back_hand,
                color: Colors.white,
                size: size * 0.6,
              ),
            ),
            SizedBox(width: size * 0.25),
            // SLAP text
            Text(
              'SLAP',
              style: GoogleFonts.fredoka(
                fontSize: size * 0.9,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : SlapColors.secondary,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        if (showTagline) ...[
          const SizedBox(height: 8),
          Text(
            'Ideas that stick together',
            style: GoogleFonts.poppins(
              fontSize: size * 0.28,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}

/// Animated SLAP logo for splash/loading screens
class AnimatedSlapLogo extends StatefulWidget {
  final double size;

  const AnimatedSlapLogo({super.key, this.size = 80});

  @override
  State<AnimatedSlapLogo> createState() => _AnimatedSlapLogoState();
}

class _AnimatedSlapLogoState extends State<AnimatedSlapLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _rotationAnimation = Tween<double>(begin: -0.1, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: SlapLogo(size: widget.size, showTagline: true),
          ),
        );
      },
    );
  }
}
