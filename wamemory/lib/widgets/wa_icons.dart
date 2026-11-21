import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// WhatsApp-like outline icons (custom vectors — not Material / not emoji).
enum WaIcons {
  chats,
  chatsFilled,
  deleted,
  deletedFilled,
  settings,
  settingsFilled,
  search,
  more,
  notify,
  lock,
  send,
  plus,
  camera,
  call,
  video,
  checkDouble,
  play,
  image,
  document,
  refresh,
  lab,
  storage,
  premium,
  info,
  shield,
  warning,
  check,
  archive,
}

class WaIcon extends StatelessWidget {
  const WaIcon(
    this.icon, {
    super.key,
    this.size = 22,
    this.color,
    this.secondaryColor,
    this.glow = false,
  });

  final WaIcons icon;
  final double size;
  final Color? color;
  final Color? secondaryColor;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    AppColors.bind(context);
    final primary = color ?? AppColors.iconMuted;
    final secondary = secondaryColor ?? AppColors.accent;
    final child = CustomPaint(
      size: Size.square(size),
      painter: _WaIconPainter(
        icon: icon,
        primary: primary,
        secondary: secondary,
      ),
    );
    if (!glow) return child;
    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: secondary.withValues(alpha: 0.28),
            blurRadius: size * 0.45,
          ),
        ],
      ),
      child: child,
    );
  }
}

class _WaIconPainter extends CustomPainter {
  _WaIconPainter({
    required this.icon,
    required this.primary,
    required this.secondary,
  });

  final WaIcons icon;
  final Color primary;
  final Color secondary;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    canvas.save();
    canvas.scale(s / 24, s / 24);

    final stroke = Paint()
      ..color = primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.55
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final fill = Paint()
      ..color = primary
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final accent = Paint()
      ..color = secondary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.55
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final accentFill = Paint()
      ..color = secondary
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    switch (icon) {
      case WaIcons.chats:
        _chatBubble(canvas, stroke, filled: false);
      case WaIcons.chatsFilled:
        _chatBubble(canvas, fill, filled: true);
      case WaIcons.deleted:
      case WaIcons.deletedFilled:
        _trash(canvas, stroke, fill, icon == WaIcons.deletedFilled);
      case WaIcons.settings:
      case WaIcons.settingsFilled:
        _gear(canvas, stroke, fill, icon == WaIcons.settingsFilled);
      case WaIcons.search:
        _search(canvas, stroke);
      case WaIcons.more:
        _more(canvas, fill);
      case WaIcons.notify:
        _bell(canvas, stroke);
      case WaIcons.lock:
        _lock(canvas, stroke);
      case WaIcons.send:
        _send(canvas, accentFill);
      case WaIcons.plus:
        _plus(canvas, stroke);
      case WaIcons.camera:
        _camera(canvas, stroke);
      case WaIcons.call:
        _call(canvas, stroke);
      case WaIcons.video:
        _video(canvas, stroke);
      case WaIcons.checkDouble:
        _checks(canvas, accent);
      case WaIcons.play:
        _play(canvas, fill);
      case WaIcons.image:
        _image(canvas, stroke);
      case WaIcons.document:
        _doc(canvas, stroke);
      case WaIcons.refresh:
        _refresh(canvas, stroke);
      case WaIcons.lab:
        _star(canvas, stroke); // starred-style
      case WaIcons.storage:
        _storage(canvas, stroke);
      case WaIcons.premium:
        _diamond(canvas, stroke);
      case WaIcons.info:
        _info(canvas, stroke, fill);
      case WaIcons.shield:
        _shield(canvas, stroke);
      case WaIcons.warning:
        _warning(canvas, stroke, fill);
      case WaIcons.check:
        _check(canvas, accent);
      case WaIcons.archive:
        _archive(canvas, stroke);
    }

    canvas.restore();
  }

  /// Classic WA chat bubble with bottom-left tail.
  void _chatBubble(Canvas c, Paint paint, {required bool filled}) {
    final p = Path()
      ..moveTo(6.5, 5.2)
      ..cubicTo(5.2, 5.2, 4.2, 6.3, 4.2, 7.7)
      ..lineTo(4.2, 13.6)
      ..cubicTo(4.2, 15.0, 5.2, 16.1, 6.5, 16.1)
      ..lineTo(8.2, 16.1)
      ..lineTo(6.6, 19.0)
      ..lineTo(11.4, 16.1)
      ..lineTo(17.5, 16.1)
      ..cubicTo(18.8, 16.1, 19.8, 15.0, 19.8, 13.6)
      ..lineTo(19.8, 7.7)
      ..cubicTo(19.8, 6.3, 18.8, 5.2, 17.5, 5.2)
      ..close();
    if (filled) {
      c.drawPath(p, paint);
    } else {
      c.drawPath(p, paint);
    }
  }

  void _trash(Canvas c, Paint stroke, Paint fill, bool filled) {
    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(7.2, 8.8, 9.6, 10.2),
      const Radius.circular(1.6),
    );
    if (filled) {
      c.drawRRect(body, fill);
    } else {
      c.drawRRect(body, stroke);
    }
    c.drawLine(const Offset(6.2, 8.8), const Offset(17.8, 8.8), stroke);
    c.drawLine(const Offset(9.4, 6.6), const Offset(14.6, 6.6), stroke);
    c.drawLine(const Offset(10.4, 11.4), const Offset(10.4, 16.6), stroke);
    c.drawLine(const Offset(13.6, 11.4), const Offset(13.6, 16.6), stroke);
  }

  /// WhatsApp-style cog: closed outline with 8 teeth + centre hole.
  void _gear(Canvas c, Paint stroke, Paint fill, bool filled) {
    const cx = 12.0, cy = 12.0, ro = 9.0, ri = 7.0, teeth = 8;
    const step = 2 * math.pi / teeth;
    const tw = step * 0.20; // half-width of tooth top
    const sl = step * 0.07; // tooth slope
    final p = Path();
    for (var i = 0; i < teeth; i++) {
      final a = i * step - math.pi / 2;
      final pts = <Offset>[
        Offset(cx + math.cos(a - tw) * ro, cy + math.sin(a - tw) * ro),
        Offset(cx + math.cos(a + tw) * ro, cy + math.sin(a + tw) * ro),
        Offset(
          cx + math.cos(a + tw + sl) * ri,
          cy + math.sin(a + tw + sl) * ri,
        ),
        Offset(
          cx + math.cos(a + step - tw - sl) * ri,
          cy + math.sin(a + step - tw - sl) * ri,
        ),
      ];
      if (i == 0) {
        p.moveTo(pts[0].dx, pts[0].dy);
      } else {
        p.lineTo(pts[0].dx, pts[0].dy);
      }
      p.lineTo(pts[1].dx, pts[1].dy);
      p.lineTo(pts[2].dx, pts[2].dy);
      p.lineTo(pts[3].dx, pts[3].dy);
    }
    p.close();
    if (filled) {
      c.drawPath(p, fill);
      c.drawCircle(
        const Offset(cx, cy),
        2.6,
        Paint()
          ..color = AppColors.appBar
          ..style = PaintingStyle.fill
          ..isAntiAlias = true,
      );
    } else {
      c.drawPath(p, stroke);
      c.drawCircle(const Offset(cx, cy), 2.6, stroke);
    }
  }

  void _search(Canvas c, Paint stroke) {
    c.drawCircle(const Offset(10.6, 10.6), 5.0, stroke);
    c.drawLine(const Offset(14.3, 14.3), const Offset(19.0, 19.0), stroke);
  }

  void _more(Canvas c, Paint fill) {
    c.drawCircle(const Offset(12, 6.2), 1.35, fill);
    c.drawCircle(const Offset(12, 12), 1.35, fill);
    c.drawCircle(const Offset(12, 17.8), 1.35, fill);
  }

  void _bell(Canvas c, Paint stroke) {
    final p = Path()
      ..moveTo(7.2, 13.8)
      ..lineTo(7.2, 10.6)
      ..cubicTo(7.2, 7.6, 9.2, 5.4, 12, 5.4)
      ..cubicTo(14.8, 5.4, 16.8, 7.6, 16.8, 10.6)
      ..lineTo(16.8, 13.8)
      ..lineTo(18.6, 16.0)
      ..lineTo(5.4, 16.0)
      ..close();
    c.drawPath(p, stroke);
    c.drawArc(
      const Rect.fromLTWH(9.6, 16.0, 4.8, 3.0),
      0,
      math.pi,
      false,
      stroke,
    );
  }

  void _lock(Canvas c, Paint stroke) {
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(6.8, 11.0, 10.4, 8.2),
        const Radius.circular(2.0),
      ),
      stroke,
    );
    c.drawArc(
      const Rect.fromLTWH(8.4, 5.4, 7.2, 7.6),
      math.pi,
      math.pi,
      false,
      stroke,
    );
  }

  void _send(Canvas c, Paint fill) {
    // WA paper-plane pointing up-right
    final p = Path()
      ..moveTo(4.2, 11.6)
      ..lineTo(19.6, 5.0)
      ..lineTo(12.2, 12.0)
      ..lineTo(19.6, 19.0)
      ..close();
    c.drawPath(p, fill);
  }

  void _plus(Canvas c, Paint stroke) {
    c.drawLine(const Offset(12, 6.5), const Offset(12, 17.5), stroke);
    c.drawLine(const Offset(6.5, 12), const Offset(17.5, 12), stroke);
  }

  void _camera(Canvas c, Paint stroke) {
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(4.2, 8.0, 15.6, 10.4),
        const Radius.circular(2.4),
      ),
      stroke,
    );
    c.drawCircle(const Offset(12, 13.2), 3.2, stroke);
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(9.2, 6.4, 4.2, 2.0),
        const Radius.circular(0.8),
      ),
      stroke,
    );
  }

  /// Classic telephone handset (WA call).
  void _call(Canvas c, Paint stroke) {
    final p = Path()
      ..moveTo(7.0, 4.8)
      ..cubicTo(7.8, 4.4, 8.8, 4.8, 9.2, 5.6)
      ..lineTo(10.4, 8.6)
      ..cubicTo(10.7, 9.3, 10.5, 10.1, 9.9, 10.5)
      ..lineTo(8.6, 11.3)
      ..cubicTo(9.5, 13.4, 11.2, 15.1, 13.4, 16.0)
      ..lineTo(14.2, 14.7)
      ..cubicTo(14.6, 14.1, 15.4, 13.9, 16.1, 14.2)
      ..lineTo(19.0, 15.4)
      ..cubicTo(19.8, 15.8, 20.1, 16.8, 19.7, 17.6)
      ..cubicTo(18.6, 19.8, 15.8, 20.6, 13.4, 19.8)
      ..cubicTo(8.2, 18.0, 4.6, 14.2, 3.4, 8.8)
      ..cubicTo(2.8, 6.4, 4.2, 4.0, 7.0, 4.8)
      ..close();
    c.drawPath(p, stroke);
  }

  void _video(Canvas c, Paint stroke) {
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(3.6, 7.6, 11.2, 8.8),
        const Radius.circular(2.0),
      ),
      stroke,
    );
    final tri = Path()
      ..moveTo(15.4, 9.6)
      ..lineTo(20.2, 7.2)
      ..lineTo(20.2, 16.8)
      ..lineTo(15.4, 14.4)
      ..close();
    c.drawPath(tri, stroke);
  }

  void _checks(Canvas c, Paint paint) {
    final a = Path()
      ..moveTo(3.8, 12.2)
      ..lineTo(7.0, 15.4)
      ..lineTo(13.2, 8.0);
    c.drawPath(a, paint);
    final b = Path()
      ..moveTo(9.0, 12.2)
      ..lineTo(12.2, 15.4)
      ..lineTo(20.0, 7.4);
    c.drawPath(b, paint);
  }

  void _play(Canvas c, Paint fill) {
    final p = Path()
      ..moveTo(9.0, 7.0)
      ..lineTo(17.4, 12.0)
      ..lineTo(9.0, 17.0)
      ..close();
    c.drawPath(p, fill);
  }

  void _image(Canvas c, Paint stroke) {
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(4.4, 6.2, 15.2, 11.6),
        const Radius.circular(2.2),
      ),
      stroke,
    );
    c.drawCircle(const Offset(9.0, 10.2), 1.4, stroke);
    final m = Path()
      ..moveTo(5.6, 16.4)
      ..lineTo(10.0, 12.2)
      ..lineTo(12.8, 14.4)
      ..lineTo(15.6, 11.4)
      ..lineTo(18.6, 16.4);
    c.drawPath(m, stroke);
  }

  void _doc(Canvas c, Paint stroke) {
    final p = Path()
      ..moveTo(8.0, 4.4)
      ..lineTo(14.0, 4.4)
      ..lineTo(17.8, 8.4)
      ..lineTo(17.8, 19.4)
      ..lineTo(8.0, 19.4)
      ..close();
    c.drawPath(p, stroke);
    c.drawLine(const Offset(14.0, 4.4), const Offset(14.0, 8.4), stroke);
    c.drawLine(const Offset(14.0, 8.4), const Offset(17.8, 8.4), stroke);
    c.drawLine(const Offset(10.2, 12.0), const Offset(15.6, 12.0), stroke);
    c.drawLine(const Offset(10.2, 14.8), const Offset(15.6, 14.8), stroke);
  }

  void _refresh(Canvas c, Paint stroke) {
    c.drawArc(const Rect.fromLTWH(5.2, 5.2, 13.6, 13.6), -1.0, 4.4, false, stroke);
    final tip = Path()
      ..moveTo(16.6, 4.0)
      ..lineTo(19.4, 7.0)
      ..lineTo(15.0, 7.4)
      ..close();
    c.drawPath(
      tip,
      Paint()
        ..color = stroke.color
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );
  }

  void _star(Canvas c, Paint stroke) {
    // 5-point star — WA starred messages
    const cx = 12.0, cy = 12.0, r = 7.2, ri = 3.0;
    final p = Path();
    for (var i = 0; i < 10; i++) {
      final ang = -math.pi / 2 + i * math.pi / 5;
      final rad = i.isEven ? r : ri;
      final x = cx + math.cos(ang) * rad;
      final y = cy + math.sin(ang) * rad;
      if (i == 0) {
        p.moveTo(x, y);
      } else {
        p.lineTo(x, y);
      }
    }
    p.close();
    c.drawPath(p, stroke);
  }

  void _storage(Canvas c, Paint stroke) {
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(5.0, 5.0, 14.0, 4.0),
        const Radius.circular(1.4),
      ),
      stroke,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(5.0, 10.0, 14.0, 4.0),
        const Radius.circular(1.4),
      ),
      stroke,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(5.0, 15.0, 14.0, 4.0),
        const Radius.circular(1.4),
      ),
      stroke,
    );
  }

  void _diamond(Canvas c, Paint stroke) {
    // WA-ish subscriptions diamond
    final p = Path()
      ..moveTo(12, 4.2)
      ..lineTo(19.2, 12)
      ..lineTo(12, 19.8)
      ..lineTo(4.8, 12)
      ..close();
    c.drawPath(p, stroke);
    c.drawLine(const Offset(8.2, 10.2), const Offset(12, 7.2), stroke);
    c.drawLine(const Offset(12, 7.2), const Offset(15.8, 10.2), stroke);
  }

  void _info(Canvas c, Paint stroke, Paint fill) {
    c.drawCircle(const Offset(12, 12), 7.6, stroke);
    c.drawCircle(const Offset(12, 8.2), 1.0, fill);
    c.drawLine(const Offset(12, 11.0), const Offset(12, 16.4), stroke);
  }

  void _shield(Canvas c, Paint stroke) {
    final p = Path()
      ..moveTo(12, 3.8)
      ..lineTo(18.4, 6.4)
      ..lineTo(18.4, 12.0)
      ..cubicTo(18.4, 16.2, 15.2, 19.2, 12, 20.2)
      ..cubicTo(8.8, 19.2, 5.6, 16.2, 5.6, 12.0)
      ..lineTo(5.6, 6.4)
      ..close();
    c.drawPath(p, stroke);
  }

  void _warning(Canvas c, Paint stroke, Paint fill) {
    final p = Path()
      ..moveTo(12, 4.4)
      ..lineTo(20.0, 18.6)
      ..lineTo(4.0, 18.6)
      ..close();
    c.drawPath(p, stroke);
    c.drawLine(const Offset(12, 9.4), const Offset(12, 13.8), stroke);
    c.drawCircle(const Offset(12, 16.2), 0.85, fill);
  }

  void _check(Canvas c, Paint paint) {
    final p = Path()
      ..moveTo(5.4, 12.2)
      ..lineTo(10.0, 16.6)
      ..lineTo(18.6, 7.4);
    c.drawPath(p, paint);
  }

  void _archive(Canvas c, Paint stroke) {
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(4.6, 5.0, 14.8, 3.8),
        const Radius.circular(1.4),
      ),
      stroke,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(5.6, 8.8, 12.8, 10.2),
        const Radius.circular(1.4),
      ),
      stroke,
    );
    c.drawLine(const Offset(9.6, 12.6), const Offset(14.4, 12.6), stroke);
  }

  @override
  bool shouldRepaint(covariant _WaIconPainter oldDelegate) {
    return oldDelegate.icon != icon ||
        oldDelegate.primary != primary ||
        oldDelegate.secondary != secondary;
  }
}
