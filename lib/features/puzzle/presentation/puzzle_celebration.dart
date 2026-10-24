import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A finite, decorative celebration. Restored results remain quiet, and the
/// platform's reduced-motion preference is respected even while visible.
class PuzzleCelebration extends StatefulWidget {
  const PuzzleCelebration({
    required this.child,
    this.celebrate = true,
    super.key,
  });

  final Widget child;
  final bool celebrate;

  @override
  State<PuzzleCelebration> createState() => _PuzzleCelebrationState();
}

class _PuzzleCelebrationState extends State<PuzzleCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) || !widget.celebrate) {
      _controller.value = 1;
      _started = true;
    } else if (!_started) {
      _started = true;
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final entrance = Curves.easeOutCubic.transform(
          (_controller.value * 6).clamp(0.0, 1.0),
        );
        return Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: Transform.translate(
                offset: Offset(0, 18 * (1 - entrance)),
                child: Transform.scale(
                  scale: 0.94 + 0.06 * entrance,
                  child: Opacity(opacity: entrance, child: child),
                ),
              ),
            ),
            if (_controller.value < 1)
              Positioned.fill(
                child: IgnorePointer(
                  child: ExcludeSemantics(
                    child: CustomPaint(
                      key: const ValueKey('completion-confetti'),
                      painter: _ConfettiPainter(
                        progress: _controller.value,
                        colors: [
                          colors.primary,
                          colors.tertiary,
                          const Color(0xFFFFC857),
                          const Color(0xFF56C7B7),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class PuzzleCompletionTitle extends StatelessWidget {
  const PuzzleCompletionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [colors.primaryContainer, colors.tertiaryContainer],
              ),
            ),
            child: Icon(
              Icons.emoji_events_rounded,
              size: 42,
              color: colors.onPrimaryContainer,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(title, textAlign: TextAlign.center),
      ],
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.progress, required this.colors});

  final double progress;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);
    final fade = ((1 - progress) * 3).clamp(0.0, 1.0);
    final paint = Paint();
    for (var i = 0; i < 64; i++) {
      final side = i.isEven ? -1.0 : 1.0;
      final speed = 0.15 + random.nextDouble() * 0.5;
      final lift = 0.18 + random.nextDouble() * 0.32;
      final width = 4 + random.nextDouble() * 5;
      final spin = (random.nextDouble() - 0.5) * 14;
      final x = size.width *
          (0.5 + side * speed * progress);
      final y = size.height *
          (0.40 - lift * 4 * progress + 1.5 * progress * progress);
      paint.color = colors[i % colors.length].withValues(alpha: fade);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(spin * progress);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: width, height: width * 0.5),
          const Radius.circular(1),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.colors != colors;
}
