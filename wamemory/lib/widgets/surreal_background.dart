import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Layered teal/violet aurora mist behind glass UI.
class SurrealBackground extends StatefulWidget {
  const SurrealBackground({super.key, required this.child});

  final Widget child;

  @override
  State<SurrealBackground> createState() => _SurrealBackgroundState();
}

class _SurrealBackgroundState extends State<SurrealBackground>
    with SingleTickerProviderStateMixin {
  AnimationController? _ctrl;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce) {
      _ctrl?.stop();
      return;
    }
    _ctrl ??= AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    _ctrl = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final ctrl = _ctrl;
    return ColoredBox(
      color: AppColors.bg,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (reduce || ctrl == null)
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-0.6, -0.7),
                  radius: 1.1,
                  colors: [Color(0x3325D366), Colors.transparent],
                ),
              ),
            )
          else
            AnimatedBuilder(
              animation: ctrl,
              builder: (context, _) {
                final t = ctrl.value;
                return CustomPaint(
                  painter: _AuroraPainter(t),
                  child: const SizedBox.expand(),
                );
              },
            ),
          widget.child,
        ],
      ),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final soft = Paint()..blendMode = BlendMode.plus;

    void blob(Offset c, double r, Color color, double a) {
      soft.shader = RadialGradient(
        colors: [color.withValues(alpha: a), color.withValues(alpha: 0)],
      ).createShader(Rect.fromCircle(center: c, radius: r));
      canvas.drawCircle(c, r, soft);
    }

    final w = size.width;
    final h = size.height;
    blob(
      Offset(w * (0.15 + 0.05 * math.sin(t * math.pi)), h * 0.12),
      w * 0.55,
      AppColors.auroraTeal,
      0.18,
    );
    blob(
      Offset(w * (0.85 - 0.04 * math.cos(t * math.pi)), h * 0.22),
      w * 0.5,
      AppColors.auroraViolet,
      0.14,
    );
    blob(
      Offset(w * 0.5, h * (0.78 + 0.03 * math.sin(t * math.pi * 2))),
      w * 0.65,
      AppColors.accent,
      0.10,
    );
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter oldDelegate) => oldDelegate.t != t;
}

/// Frosted glass panel.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding,
    this.radius = 18,
    this.blur = 14,
    this.opacity = 0.55,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final double blur;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            color: AppColors.panel.withValues(alpha: opacity),
            border: Border.all(color: AppColors.glassBorder),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.glassHighlight,
                AppColors.glassFill,
              ],
            ),
          ),
          child: padding == null ? child : Padding(padding: padding!, child: child),
        ),
      ),
    );
  }
}
