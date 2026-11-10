import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

enum NaturalLandscapeMode { splash, welcome }

class NaturalLandscape extends StatelessWidget {
  const NaturalLandscape({super.key, this.mode = NaturalLandscapeMode.splash});

  final NaturalLandscapeMode mode;

  @override
  Widget build(BuildContext context) {
    final spec = _specFor(mode);
    return CustomPaint(
      painter: NaturalLandscapePainter(
        skyTop: spec.skyTop,
        skyBottom: spec.skyBottom,
        sunColor: spec.sunColor,
        sunDx: spec.sunDx,
        cloudColor: spec.cloudColor,
        hillFar: spec.hillFar,
        hillMid: spec.hillMid,
        field: spec.field,
        fieldRow: spec.fieldRow,
        showWater: spec.showWater,
      ),
      size: Size.infinite,
    );
  }

  _LandscapeSpec _specFor(NaturalLandscapeMode mode) {
    switch (mode) {
      case NaturalLandscapeMode.splash:
        return const _LandscapeSpec(
          skyTop: Color(0xFF7FCFE8),
          skyBottom: Color(0xFFFDF3DC),
          sunColor: Color(0xFFFFF3C4),
          sunDx: 0.28,
          cloudColor: Colors.white,
          hillFar: Color(0xFFA8CF95),
          hillMid: Color(0xFF79B878),
          field: Color(0xFF4E9A4F),
          fieldRow: Color(0xFF2E6A33),
          showWater: true,
        );
      case NaturalLandscapeMode.welcome:
        return const _LandscapeSpec(
          skyTop: Color(0xFF64B5F6),
          skyBottom: Color(0xFFE8F5E9),
          sunColor: Color(0xFFFFECB3),
          sunDx: 0.55,
          cloudColor: Colors.white,
          hillFar: Color(0xFF8FCE8F),
          hillMid: Color(0xFF66A866),
          field: Color(0xFF3E8A45),
          fieldRow: Color(0xFF2A6B2F),
          showWater: false,
        );
    }
  }
}

class _LandscapeSpec {
  const _LandscapeSpec({
    required this.skyTop,
    required this.skyBottom,
    required this.sunColor,
    required this.sunDx,
    required this.cloudColor,
    required this.hillFar,
    required this.hillMid,
    required this.field,
    required this.fieldRow,
    required this.showWater,
  });

  final Color skyTop;
  final Color skyBottom;
  final Color sunColor;
  final double sunDx;
  final Color cloudColor;
  final Color hillFar;
  final Color hillMid;
  final Color field;
  final Color fieldRow;
  final bool showWater;
}

class NaturalLandscapePainter extends CustomPainter {
  NaturalLandscapePainter({
    required this.skyTop,
    required this.skyBottom,
    required this.sunColor,
    required this.sunDx,
    required this.cloudColor,
    required this.hillFar,
    required this.hillMid,
    required this.field,
    required this.fieldRow,
    required this.showWater,
  });

  final Color skyTop;
  final Color skyBottom;
  final Color sunColor;
  final double sunDx;
  final Color cloudColor;
  final Color hillFar;
  final Color hillMid;
  final Color field;
  final Color fieldRow;
  final bool showWater;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;

    final horizonY = h * 0.38;

    _paintSky(canvas, w, h);
    _paintSun(canvas, w, horizonY);
    _paintClouds(canvas, w, h);
    _paintFarHill(canvas, w, h);
    _paintMidHill(canvas, w, h);
    _paintField(canvas, w, h);
    if (showWater) {
      _paintWater(canvas, w, h);
    } else {
      _paintGroundRows(canvas, w, h);
    }
  }

  void _paintSky(Canvas canvas, double w, double h) {
    final rect = Rect.fromLTWH(0, 0, w, h);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [skyTop, skyBottom],
      ).createShader(rect);
    canvas.drawRect(rect, paint);
  }

  void _paintSun(Canvas canvas, double w, double horizonY) {
    final cx = w * sunDx;
    final cy = horizonY;
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          sunColor.withValues(alpha: 0.65),
          sunColor.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: w * 0.42));
    canvas.drawCircle(Offset(cx, cy), w * 0.42, glow);

    final sun = Paint()..color = sunColor;
    canvas.drawCircle(Offset(cx, cy), w * 0.055, sun);

    final rim = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(cx, cy), w * 0.055, rim);
  }

  void _paintClouds(Canvas canvas, double w, double h) {
    final cloudPaint = Paint()
      ..color = cloudColor.withValues(alpha: 0.32)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);

    final clouds = [
      (Offset(w * 0.12, h * 0.16), w * 0.30),
      (Offset(w * 0.62, h * 0.10), w * 0.26),
      (Offset(w * 0.45, h * 0.26), w * 0.34),
    ];
    for (final entry in clouds) {
      final center = entry.$1;
      final scale = entry.$2;
      canvas.drawOval(
        Rect.fromCenter(center: center, width: scale, height: scale * 0.32),
        cloudPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(center.dx - scale * 0.22, center.dy + scale * 0.10),
          width: scale * 0.55,
          height: scale * 0.22,
        ),
        cloudPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(center.dx + scale * 0.24, center.dy + scale * 0.08),
          width: scale * 0.45,
          height: scale * 0.20,
        ),
        cloudPaint,
      );
    }
  }

  void _paintFarHill(Canvas canvas, double w, double h) {
    final path = Path()
      ..moveTo(0, h * 0.52)
      ..quadraticBezierTo(w * 0.24, h * 0.38, w * 0.52, h * 0.50)
      ..quadraticBezierTo(w * 0.80, h * 0.60, w, h * 0.48)
      ..lineTo(w, h * 0.72)
      ..lineTo(0, h * 0.72)
      ..close();
    canvas.drawPath(path, Paint()..color = hillFar);
  }

  void _paintMidHill(Canvas canvas, double w, double h) {
    final path = Path()
      ..moveTo(0, h * 0.66)
      ..quadraticBezierTo(w * 0.34, h * 0.52, w * 0.64, h * 0.64)
      ..quadraticBezierTo(w * 0.86, h * 0.70, w, h * 0.66)
      ..lineTo(w, h * 0.88)
      ..lineTo(0, h * 0.88)
      ..close();
    canvas.drawPath(path, Paint()..color = hillMid);
  }

  void _paintField(Canvas canvas, double w, double h) {
    final fieldTop = h * (showWater ? 0.76 : 0.74);
    final fieldBottom = h * (showWater ? 0.90 : 1.0);
    final rect = Rect.fromLTRB(0, fieldTop, w, fieldBottom);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [hillMid, field],
      ).createShader(rect);
    canvas.drawRect(rect, paint);

    if (showWater) {
      final rows = 5;
      for (var i = 0; i < rows; i++) {
        final y = fieldTop + (fieldBottom - fieldTop) * (i + 1) / (rows + 1);
        final paintRow = Paint()
          ..color = fieldRow.withValues(alpha: 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6;
        final path = Path()
          ..moveTo(0, y)
          ..quadraticBezierTo(w * 0.3, y - 6, w * 0.6, y)
          ..quadraticBezierTo(w * 0.85, y + 6, w, y);
        canvas.drawPath(path, paintRow);
      }
    }
  }

  void _paintGroundRows(Canvas canvas, double w, double h) {
    final rows = 7;
    final startY = h * 0.80;
    for (var i = 0; i < rows; i++) {
      final t = (i + 1) / (rows + 1);
      final y = startY + (h - startY) * t;
      final paintRow = Paint()
        ..color = fieldRow.withValues(alpha: 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      final path = Path()
        ..moveTo(0, y)
        ..quadraticBezierTo(w * 0.28, y - 8, w * 0.55, y)
        ..quadraticBezierTo(w * 0.82, y + 8, w, y);
      canvas.drawPath(path, paintRow);
    }
  }

  void _paintWater(Canvas canvas, double w, double h) {
    final rect = Rect.fromLTRB(0, h * 0.88, w, h);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFF7EC8E3), const Color(0xFF3A9BC5)],
      ).createShader(rect);
    canvas.drawRect(rect, paint);

    final highlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    for (var i = 0; i < 5; i++) {
      final y = h * (0.90 + i * 0.02);
      final path = Path()
        ..moveTo(w * 0.06, y)
        ..lineTo(w * 0.16, y + 2)
        ..moveTo(w * 0.42, y + 2)
        ..lineTo(w * 0.58, y)
        ..moveTo(w * 0.74, y)
        ..lineTo(w * 0.90, y + 2);
      canvas.drawPath(path, highlight);
    }
  }

  @override
  bool shouldRepaint(covariant NaturalLandscapePainter oldDelegate) {
    return oldDelegate.skyTop != skyTop ||
        oldDelegate.skyBottom != skyBottom ||
        oldDelegate.sunColor != sunColor ||
        oldDelegate.hillFar != hillFar ||
        oldDelegate.hillMid != hillMid ||
        oldDelegate.field != field;
  }
}

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.radius = 28,
    this.blur = 14,
    this.borderAlpha = 0.45,
    this.backgroundAlpha = 0.18,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blur;
  final double borderAlpha;
  final double backgroundAlpha;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withValues(alpha: borderAlpha)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: backgroundAlpha),
              borderRadius: BorderRadius.circular(radius),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
