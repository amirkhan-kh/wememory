import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Flat WhatsApp dark scaffold wrapper (aurora removed — classic WA).
class SurrealBackground extends StatelessWidget {
  const SurrealBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    AppColors.bind(context);
    return ColoredBox(
      color: AppColors.bgDeep,
      child: child,
    );
  }
}

/// Solid panel (replaces frosted glass — classic WA list/card surface).
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding,
    this.radius = 12,
    this.blur = 0,
    this.opacity = 1,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final double blur;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    AppColors.bind(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: AppColors.panel.withValues(alpha: opacity.clamp(0.85, 1.0)),
        border: Border.all(color: AppColors.divider),
      ),
      child: padding == null
          ? child
          : Padding(padding: padding!, child: child),
    );
  }
}
