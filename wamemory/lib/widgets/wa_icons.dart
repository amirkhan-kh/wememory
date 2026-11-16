import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Premium dual-tone vector icons (not Material defaults / not emoji).
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
    final primary = color ?? AppColors.textSecondary;
    final secondary = secondaryColor ?? AppColors.accentBright;
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
            color: secondary.withValues(alpha: 0.35),
            blurRadius: size * 0.55,
            spreadRadius: 0,
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
      ..strokeWidth = 1.7
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
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final accentFill = Paint()
      ..color = secondary
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    switch (icon) {
      case WaIcons.chats:
      case WaIcons.chatsFilled:
        _chats(canvas, stroke, fill, accentFill, icon == WaIcons.chatsFilled);
        break;
      case WaIcons.deleted:
      case WaIcons.deletedFilled:
        _deleted(canvas, stroke, fill, accent, icon == WaIcons.deletedFilled);
        break;
      case WaIcons.settings:
      case WaIcons.settingsFilled:
        _settings(canvas, stroke, fill, accentFill, icon == WaIcons.settingsFilled);
        break;
      case WaIcons.search:
        _search(canvas, stroke, accent);
        break;
      case WaIcons.more:
        _more(canvas, fill, accentFill);
        break;
      case WaIcons.notify:
        _notify(canvas, stroke, accentFill);
        break;
      case WaIcons.lock:
        _lock(canvas, stroke, accent);
        break;
      case WaIcons.send:
        _send(canvas, fill, accentFill);
        break;
      case WaIcons.plus:
        _plus(canvas, stroke, accent);
        break;
      case WaIcons.camera:
        _camera(canvas, stroke, accent);
        break;
      case WaIcons.call:
        _call(canvas, stroke, accent);
        break;
      case WaIcons.video:
        _video(canvas, stroke, accent);
        break;
      case WaIcons.checkDouble:
        _checkDouble(canvas, accent);
        break;
      case WaIcons.play:
        _play(canvas, fill, accentFill);
        break;
      case WaIcons.image:
        _image(canvas, stroke, accent);
        break;
      case WaIcons.document:
        _document(canvas, stroke, accent);
        break;
      case WaIcons.refresh:
        _refresh(canvas, stroke, accentFill);
        break;
      case WaIcons.lab:
        _lab(canvas, stroke, accentFill);
        break;
      case WaIcons.storage:
        _storage(canvas, stroke, accent);
        break;
      case WaIcons.premium:
        _premium(canvas, stroke, accentFill);
        break;
      case WaIcons.info:
        _info(canvas, stroke, accentFill);
        break;
      case WaIcons.shield:
        _shield(canvas, stroke, accent);
        break;
      case WaIcons.warning:
        _warning(canvas, stroke, accentFill);
        break;
      case WaIcons.check:
        _check(canvas, accent);
        break;
      case WaIcons.archive:
        _archive(canvas, stroke, accentFill);
        break;
    }

    canvas.restore();
  }

  void _chats(Canvas c, Paint stroke, Paint fill, Paint accentFill, bool filled) {
    final a = Path()
      ..moveTo(5, 7.5)
      ..cubicTo(5, 5.5, 6.6, 4, 8.8, 4)
      ..lineTo(13.5, 4)
      ..cubicTo(15.7, 4, 17.2, 5.5, 17.2, 7.5)
      ..lineTo(17.2, 11.2)
      ..cubicTo(17.2, 13.2, 15.7, 14.7, 13.5, 14.7)
      ..lineTo(10.2, 14.7)
      ..lineTo(7.4, 17.2)
      ..lineTo(7.8, 14.7)
      ..lineTo(8.8, 14.7)
      ..cubicTo(6.6, 14.7, 5, 13.2, 5, 11.2)
      ..close();
    if (filled) {
      c.drawPath(
        a,
        Paint()
          ..color = primary.withValues(alpha: 0.92)
          ..style = PaintingStyle.fill
          ..isAntiAlias = true,
      );
    } else {
      c.drawPath(a, stroke);
    }
    final b = Path()
      ..moveTo(10.2, 9.2)
      ..cubicTo(10.2, 8.1, 11.1, 7.2, 12.4, 7.2)
      ..lineTo(16.2, 7.2)
      ..cubicTo(17.6, 7.2, 18.6, 8.2, 18.6, 9.5)
      ..lineTo(18.6, 12.2)
      ..cubicTo(18.6, 13.5, 17.6, 14.5, 16.2, 14.5)
      ..lineTo(14.4, 14.5)
      ..lineTo(16.6, 17)
      ..lineTo(15.8, 14.5)
      ..cubicTo(14.4, 14.5, 13.4, 13.5, 13.4, 12.2);
    c.drawPath(b, filled ? accentFill : stroke);
    // memory spark
    c.drawCircle(const Offset(19.2, 5.2), 1.15, accentFill);
  }

  void _deleted(Canvas c, Paint stroke, Paint fill, Paint accent, bool filled) {
    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(7, 8.5, 10, 11),
      const Radius.circular(2.2),
    );
    if (filled) {
      c.drawRRect(
        body,
        Paint()
          ..color = primary.withValues(alpha: 0.9)
          ..style = PaintingStyle.fill
          ..isAntiAlias = true,
      );
    } else {
      c.drawRRect(body, stroke);
    }
    c.drawLine(const Offset(6, 8.5), const Offset(18, 8.5), stroke);
    c.drawLine(const Offset(9.5, 6.2), const Offset(14.5, 6.2), stroke);
    c.drawLine(const Offset(10.2, 11.2), const Offset(10.2, 16.5), accent);
    c.drawLine(const Offset(13.8, 11.2), const Offset(13.8, 16.5), accent);
  }

  void _settings(Canvas c, Paint stroke, Paint fill, Paint accentFill, bool filled) {
    final cx = 12.0, cy = 12.0, r = 3.1;
    if (filled) {
      c.drawCircle(Offset(cx, cy), r, accentFill);
    } else {
      c.drawCircle(Offset(cx, cy), r, stroke);
    }
    for (var i = 0; i < 8; i++) {
      final a = (i / 8) * math.pi * 2 - math.pi / 2;
      final p1 = Offset(cx + math.cos(a) * 5.2, cy + math.sin(a) * 5.2);
      final p2 = Offset(cx + math.cos(a) * 8.4, cy + math.sin(a) * 8.4);
      final tooth = Path()
        ..moveTo(p1.dx + math.cos(a + 0.35) * 1.1, p1.dy + math.sin(a + 0.35) * 1.1)
        ..lineTo(p2.dx + math.cos(a + 0.22) * 1.4, p2.dy + math.sin(a + 0.22) * 1.4)
        ..lineTo(p2.dx + math.cos(a - 0.22) * 1.4, p2.dy + math.sin(a - 0.22) * 1.4)
        ..lineTo(p1.dx + math.cos(a - 0.35) * 1.1, p1.dy + math.sin(a - 0.35) * 1.1)
        ..close();
      c.drawPath(
        tooth,
        filled
            ? (Paint()
              ..color = primary.withValues(alpha: 0.92)
              ..style = PaintingStyle.fill
              ..isAntiAlias = true)
            : stroke,
      );
    }
  }

  void _search(Canvas c, Paint stroke, Paint accent) {
    c.drawCircle(const Offset(10.5, 10.5), 5.2, stroke);
    c.drawLine(const Offset(14.4, 14.4), const Offset(19, 19), accent);
  }

  void _more(Canvas c, Paint fill, Paint accentFill) {
    c.drawCircle(const Offset(12, 6.5), 1.35, fill);
    c.drawCircle(const Offset(12, 12), 1.35, accentFill);
    c.drawCircle(const Offset(12, 17.5), 1.35, fill);
  }

  void _notify(Canvas c, Paint stroke, Paint accentFill) {
    final p = Path()
      ..moveTo(7, 14)
      ..lineTo(7, 11)
      ..cubicTo(7, 7.8, 9.1, 5.5, 12, 5.5)
      ..cubicTo(14.9, 5.5, 17, 7.8, 17, 11)
      ..lineTo(17, 14)
      ..lineTo(19, 16.2)
      ..lineTo(5, 16.2)
      ..close();
    c.drawPath(p, stroke);
    c.drawArc(const Rect.fromLTWH(9.4, 16.2, 5.2, 3.2), 0, math.pi, false, stroke);
    c.drawCircle(const Offset(16.8, 7.2), 1.6, accentFill);
  }

  void _lock(Canvas c, Paint stroke, Paint accent) {
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(6.5, 11, 11, 9),
        const Radius.circular(2.4),
      ),
      stroke,
    );
    c.drawArc(const Rect.fromLTWH(8.2, 5.2, 7.6, 8), math.pi, math.pi, false, accent);
    c.drawCircle(const Offset(12, 15.2), 1.2, accent);
  }

  void _send(Canvas c, Paint fill, Paint accentFill) {
    final p = Path()
      ..moveTo(4.5, 12)
      ..lineTo(19.5, 5.5)
      ..lineTo(13.2, 12)
      ..lineTo(19.5, 18.5)
      ..close();
    c.drawPath(p, accentFill);
    c.drawLine(const Offset(13.2, 12), const Offset(4.5, 12), fill);
  }

  void _plus(Canvas c, Paint stroke, Paint accent) {
    c.drawCircle(const Offset(12, 12), 8.2, stroke);
    c.drawLine(const Offset(12, 7.5), const Offset(12, 16.5), accent);
    c.drawLine(const Offset(7.5, 12), const Offset(16.5, 12), accent);
  }

  void _camera(Canvas c, Paint stroke, Paint accent) {
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(4.5, 8, 15, 11),
        const Radius.circular(2.6),
      ),
      stroke,
    );
    c.drawCircle(const Offset(12, 13.5), 3.1, accent);
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(9, 6.2, 4.2, 2.2),
        const Radius.circular(1),
      ),
      stroke,
    );
  }

  void _call(Canvas c, Paint stroke, Paint accent) {
    final p = Path()
      ..moveTo(7.2, 5.8)
      ..lineTo(9.6, 5.8)
      ..cubicTo(10.2, 5.8, 10.7, 6.2, 10.9, 6.8)
      ..lineTo(11.7, 9.2)
      ..cubicTo(11.9, 9.8, 11.7, 10.4, 11.2, 10.7)
      ..lineTo(9.8, 11.6)
      ..cubicTo(10.6, 13.4, 12.1, 14.9, 14, 15.7)
      ..lineTo(14.9, 14.3)
      ..cubicTo(15.2, 13.8, 15.8, 13.6, 16.4, 13.8)
      ..lineTo(18.8, 14.6)
      ..cubicTo(19.4, 14.8, 19.8, 15.3, 19.8, 15.9)
      ..lineTo(19.8, 18.2)
      ..cubicTo(19.8, 19, 19.1, 19.6, 18.3, 19.4)
      ..cubicTo(11.2, 17.6, 6, 12.4, 4.2, 5.3)
      ..cubicTo(4, 4.5, 4.6, 3.8, 5.4, 3.8)
      ..lineTo(7.2, 3.8);
    c.drawPath(p, accent);
  }

  void _video(Canvas c, Paint stroke, Paint accent) {
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(3.8, 7.5, 11.5, 9),
        const Radius.circular(2.2),
      ),
      stroke,
    );
    final tri = Path()
      ..moveTo(16, 10)
      ..lineTo(20.2, 7.8)
      ..lineTo(20.2, 16.2)
      ..lineTo(16, 14)
      ..close();
    c.drawPath(tri, accent);
  }

  void _checkDouble(Canvas c, Paint accent) {
    final p1 = Path()
      ..moveTo(4, 12.2)
      ..lineTo(7.2, 15.4)
      ..lineTo(13.5, 8.2);
    c.drawPath(p1, accent);
    final p2 = Path()
      ..moveTo(9.2, 12.2)
      ..lineTo(12.4, 15.4)
      ..lineTo(20, 7.5);
    c.drawPath(p2, accent);
  }

  void _play(Canvas c, Paint fill, Paint accentFill) {
    final p = Path()
      ..moveTo(9, 7.2)
      ..lineTo(17.2, 12)
      ..lineTo(9, 16.8)
      ..close();
    c.drawPath(p, accentFill);
  }

  void _image(Canvas c, Paint stroke, Paint accent) {
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(4.5, 6, 15, 12),
        const Radius.circular(2.4),
      ),
      stroke,
    );
    c.drawCircle(const Offset(9, 10), 1.5, accent);
    final mountain = Path()
      ..moveTo(5.8, 16.5)
      ..lineTo(10.2, 12.2)
      ..lineTo(12.8, 14.4)
      ..lineTo(15.6, 11.5)
      ..lineTo(18.5, 16.5);
    c.drawPath(mountain, accent);
  }

  void _document(Canvas c, Paint stroke, Paint accent) {
    final p = Path()
      ..moveTo(8, 4.5)
      ..lineTo(14.2, 4.5)
      ..lineTo(18, 8.4)
      ..lineTo(18, 19.5)
      ..lineTo(8, 19.5)
      ..close();
    c.drawPath(p, stroke);
    c.drawLine(const Offset(14.2, 4.5), const Offset(14.2, 8.4), stroke);
    c.drawLine(const Offset(14.2, 8.4), const Offset(18, 8.4), stroke);
    c.drawLine(const Offset(10.2, 12), const Offset(15.8, 12), accent);
    c.drawLine(const Offset(10.2, 14.8), const Offset(15.8, 14.8), accent);
  }

  void _refresh(Canvas c, Paint stroke, Paint accentFill) {
    c.drawArc(const Rect.fromLTWH(5, 5, 14, 14), -0.9, 4.2, false, stroke);
    final tip = Path()
      ..moveTo(16.8, 4.2)
      ..lineTo(19.4, 7.2)
      ..lineTo(15.2, 7.6)
      ..close();
    c.drawPath(tip, accentFill);
  }

  void _lab(Canvas c, Paint stroke, Paint accentFill) {
    c.drawLine(const Offset(9, 4.5), const Offset(9, 10), stroke);
    c.drawLine(const Offset(15, 4.5), const Offset(15, 10), stroke);
    c.drawLine(const Offset(8, 4.5), const Offset(16, 4.5), stroke);
    final flask = Path()
      ..moveTo(9, 10)
      ..lineTo(6.2, 17.5)
      ..cubicTo(5.9, 18.4, 6.5, 19.4, 7.5, 19.4)
      ..lineTo(16.5, 19.4)
      ..cubicTo(17.5, 19.4, 18.1, 18.4, 17.8, 17.5)
      ..lineTo(15, 10);
    c.drawPath(flask, stroke);
    c.drawCircle(const Offset(11.2, 16.2), 1.1, accentFill);
    c.drawCircle(const Offset(14.2, 15.2), 0.8, accentFill);
  }

  void _storage(Canvas c, Paint stroke, Paint accent) {
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(5, 5, 14, 4.2),
        const Radius.circular(1.6),
      ),
      stroke,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(5, 10, 14, 4.2),
        const Radius.circular(1.6),
      ),
      stroke,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(5, 15, 14, 4.2),
        const Radius.circular(1.6),
      ),
      accent,
    );
  }

  void _premium(Canvas c, Paint stroke, Paint accentFill) {
    final crown = Path()
      ..moveTo(5, 16.5)
      ..lineTo(5.5, 9)
      ..lineTo(9.2, 12.5)
      ..lineTo(12, 6.5)
      ..lineTo(14.8, 12.5)
      ..lineTo(18.5, 9)
      ..lineTo(19, 16.5)
      ..close();
    c.drawPath(crown, stroke);
    c.drawCircle(const Offset(12, 6.2), 1.1, accentFill);
  }

  void _info(Canvas c, Paint stroke, Paint accentFill) {
    c.drawCircle(const Offset(12, 12), 8, stroke);
    c.drawCircle(const Offset(12, 8.2), 1.05, accentFill);
    c.drawLine(const Offset(12, 11), const Offset(12, 16.5), stroke);
  }

  void _shield(Canvas c, Paint stroke, Paint accent) {
    final p = Path()
      ..moveTo(12, 3.8)
      ..lineTo(18.5, 6.5)
      ..lineTo(18.5, 12.2)
      ..cubicTo(18.5, 16.5, 15.2, 19.6, 12, 20.5)
      ..cubicTo(8.8, 19.6, 5.5, 16.5, 5.5, 12.2)
      ..lineTo(5.5, 6.5)
      ..close();
    c.drawPath(p, stroke);
    c.drawLine(const Offset(9, 12.2), const Offset(11.2, 14.4), accent);
    c.drawLine(const Offset(11.2, 14.4), const Offset(15.4, 9.6), accent);
  }

  void _warning(Canvas c, Paint stroke, Paint accentFill) {
    final p = Path()
      ..moveTo(12, 4.2)
      ..lineTo(20.2, 18.8)
      ..lineTo(3.8, 18.8)
      ..close();
    c.drawPath(p, stroke);
    c.drawLine(const Offset(12, 9.2), const Offset(12, 13.8), stroke);
    c.drawCircle(const Offset(12, 16.2), 0.9, accentFill);
  }

  void _check(Canvas c, Paint accent) {
    final p = Path()
      ..moveTo(5.5, 12.2)
      ..lineTo(10, 16.5)
      ..lineTo(18.5, 7.5);
    c.drawPath(p, accent);
  }

  void _archive(Canvas c, Paint stroke, Paint accentFill) {
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(4.5, 5, 15, 4),
        const Radius.circular(1.8),
      ),
      stroke,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(5.5, 9, 13, 10.5),
        const Radius.circular(1.8),
      ),
      stroke,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(9.5, 12.2, 5, 2.2),
        const Radius.circular(1),
      ),
      accentFill,
    );
  }

  @override
  bool shouldRepaint(covariant _WaIconPainter oldDelegate) {
    return oldDelegate.icon != icon ||
        oldDelegate.primary != primary ||
        oldDelegate.secondary != secondary;
  }
}
