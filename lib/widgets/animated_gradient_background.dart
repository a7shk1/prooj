import 'dart:math' as math;
import 'dart:ui' as ui; // 👈 مهم حتى نستخدم ImageFilter
import 'package:flutter/material.dart';

class AnimatedGradientBackground extends StatefulWidget {
  final Widget child;
  const AnimatedGradientBackground({super.key, required this.child});

  @override
  State<AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState
    extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final base1 = cs.primary.withOpacity(0.16);
    final base2 = cs.primary.withOpacity(0.10);
    final glow = cs.primary.withOpacity(0.20);

    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        final angle = t * 2 * math.pi;

        return Stack(
          fit: StackFit.expand,
          children: [
            // خلفية Radial متحركة
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(
                    math.cos(angle) * 0.2,
                    math.sin(angle) * 0.2,
                  ),
                  radius: 1.2,
                  colors: [base1, Colors.transparent],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),

            // خلفية Linear متدرجة
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF0E0E12),
                    const Color(0xFF0E0E12),
                    base2,
                    const Color(0xFF0E0E12),
                  ],
                  stops: [
                    0,
                    t * 0.2,
                    0.5 + 0.2 * math.sin(angle),
                    1,
                  ],
                ),
              ),
            ),

            // Sweep خفيف (glow)
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: SweepGradient(
                    center: Alignment.center,
                    startAngle: 0,
                    endAngle: 2 * math.pi,
                    colors: [
                      Colors.transparent,
                      glow.withOpacity(0.08),
                      Colors.transparent,
                    ],
                    stops: [
                      (t + 0.05) % 1.0,
                      (t + 0.1) % 1.0,
                      (t + 0.15) % 1.0,
                    ],
                  ),
                ),
              ),
            ),

            // Blur شفاف
            BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 0.0, sigmaY: 0.0),
              child: Container(color: Colors.transparent),
            ),

            // المحتوى
            widget.child,
          ],
        );
      },
    );
  }
}
