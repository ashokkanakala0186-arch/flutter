import 'dart:math' as math;

import 'package:flutter/material.dart';

class DashboardBackground extends StatefulWidget {
  const DashboardBackground({
    super.key,
    required this.child,
    this.particleCount = 14,
  });

  final Widget child;
  final int particleCount;

  @override
  State<DashboardBackground> createState() => _DashboardBackgroundState();
}

class _DashboardBackgroundState extends State<DashboardBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(
          painter: _FarmPainter(
            controller: _controller,
            particleCount: widget.particleCount,
          ),
          isComplex: true,
          willChange: true,
        ),
        widget.child,
      ],
    );
  }
}

class _FarmPainter extends CustomPainter {
  _FarmPainter({required this.controller, required this.particleCount})
    : super(repaint: controller);

  final AnimationController controller;
  final int particleCount;

  static const Color _skyTop = Color(0xFF7FC8F5);
  static const Color _skyMid = Color(0xFFC7F0E4);
  static const Color _skyBottom = Color(0xFFFFF3C4);
  static const Color _sunColor = Color(0xFFFFD54F);
  static const Color _hillFar = Color(0xFFA9D9A3);
  static const Color _hillMid = Color(0xFF7FC98B);
  static const Color _fieldTop = Color(0xFFF3C14A);
  static const Color _fieldBottom = Color(0xFFDF982C);
  static const Color _furrow = Color(0xFFB97A1E);
  static const Color _barnBody = Color(0xFFBB4326);
  static const Color _barnRoof = Color(0xFF7A2E1B);
  static const Color _barnDoor = Color(0xFFFFE6B8);

  static const List<Color> _leaves = [
    Color(0xFFF9A825),
    Color(0xFF66BB6A),
    Color(0xFFFFF176),
    Color(0xFFFF8F00),
    Color(0xFFA5D6A7),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;
    final t = controller.value;
    final rect = Rect.fromLTWH(0, 0, w, h);

    _drawSky(canvas, rect, t);
    _drawGlow(canvas, w * 0.16, h * 0.14, math.max(w, h) * 0.32, _skyTop, 0.35);
    _drawGlow(
      canvas,
      w * 0.88,
      h * 0.60,
      math.max(w, h) * 0.28,
      _skyBottom,
      0.28,
    );
    _drawSun(canvas, Offset(w * 0.82, h * 0.13), math.max(w, h) * 0.036, t);
    for (var i = 0; i < 3; i++) {
      final seed = i * 0.37;
      final cx = w * ((seed + 0.06 * i + t * 0.014) % 1.0);
      final cy = h * (0.10 + 0.18 * ((seed * 11) % 1.0));
      final s = math.min(w, h) * (0.05 + 0.02 * ((seed * 7) % 1.0));
      _drawCloud(canvas, cx, cy, s, 0.82);
    }

    final move = 0.012 * math.sin(2 * math.pi * t);
    _drawFarHill(canvas, w, h, move);
    _drawMidHill(canvas, w, h, move);
    _drawBarn(canvas, w, h);
    _drawField(canvas, w, h, t);
    _drawFlowers(canvas, w, h, t);

    for (var i = 0; i < particleCount; i++) {
      _drawLeaf(canvas, w, h, t, i);
    }
  }

  void _drawSky(Canvas canvas, Rect rect, double t) {
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: const [0.0, 0.5, 1.0],
        colors: const [_skyTop, _skyMid, _skyBottom],
      ).createShader(rect);
    canvas.drawRect(rect, skyPaint);
    final breath = 0.5 + 0.5 * math.sin(2 * math.pi * t);
    canvas.drawRect(
      rect,
      Paint()..color = Colors.white.withValues(alpha: 0.05 * breath),
    );
  }

  void _drawGlow(
    Canvas canvas,
    double cx,
    double cy,
    double r,
    Color color,
    double peak,
  ) {
    final gp = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: peak),
          color.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    canvas.drawCircle(Offset(cx, cy), r, gp);
  }

  void _drawSun(Canvas canvas, Offset p, double r, double t) {
    final pulse = 0.5 + 0.5 * math.sin(2 * math.pi * t * 0.7);
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          _sunColor.withValues(alpha: 0.55 + 0.15 * pulse),
          _sunColor.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: p, radius: r * 3.0));
    canvas.drawCircle(p, r * 3.0, glowPaint);

    final rayPaint = Paint()..color = _sunColor.withValues(alpha: 0.5);
    final rot = 2 * math.pi * t * 0.2;
    for (var i = 0; i < 8; i++) {
      final a = rot + i * math.pi / 4;
      final dir = Offset(math.cos(a), math.sin(a));
      final base = p + dir * (r * 1.32);
      final tip = p + dir * (r * (2.0 + 0.2 * pulse));
      final c1 = p + _rotate(dir, 0.2) * (r * 1.6);
      final c2 = p + _rotate(dir, -0.2) * (r * 1.6);
      final ray = Path()
        ..moveTo(base.dx, base.dy)
        ..quadraticBezierTo(c1.dx, c1.dy, tip.dx, tip.dy)
        ..quadraticBezierTo(c2.dx, c2.dy, base.dx, base.dy)
        ..close();
      canvas.drawPath(ray, rayPaint);
    }
    canvas.drawCircle(
      p,
      r,
      Paint()..color = Colors.white.withValues(alpha: 0.92),
    );
    canvas.drawCircle(p, r * 0.8, Paint()..color = _sunColor);
  }

  Offset _rotate(Offset v, double a) {
    final c = math.cos(a);
    final s = math.sin(a);
    return Offset(v.dx * c - v.dy * s, v.dx * s + v.dy * c);
  }

  void _drawCloud(Canvas canvas, double cx, double cy, double s, double o) {
    final paint = Paint()..color = Colors.white.withValues(alpha: o);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: s * 3.2, height: s * 0.8),
      paint,
    );
    canvas.drawCircle(Offset(cx - s * 0.7, cy + s * 0.1), s * 0.5, paint);
    canvas.drawCircle(Offset(cx + s * 0.55, cy + s * 0.14), s * 0.44, paint);
    canvas.drawCircle(Offset(cx, cy - s * 0.16), s * 0.6, paint);
  }

  void _drawFarHill(Canvas canvas, double w, double h, double move) {
    final path = Path()
      ..moveTo(0, h * (0.70 - move))
      ..quadraticBezierTo(w * 0.35, h * 0.62, w * 0.68, h * 0.72)
      ..quadraticBezierTo(w * 0.9, h * 0.77, w, h * 0.70)
      ..lineTo(w, h * 0.82)
      ..lineTo(0, h * 0.82)
      ..close();
    canvas.drawPath(path, Paint()..color = _hillFar);
  }

  void _drawMidHill(Canvas canvas, double w, double h, double move) {
    final path = Path()
      ..moveTo(0, h * (0.84 - move))
      ..quadraticBezierTo(w * 0.30, h * 0.78, w * 0.58, h * 0.86)
      ..quadraticBezierTo(w * 0.82, h * 0.92, w, h * 0.84)
      ..lineTo(w, h * 0.98)
      ..lineTo(0, h * 0.98)
      ..close();
    canvas.drawPath(path, Paint()..color = _hillMid);
  }

  void _drawBarn(Canvas canvas, double w, double h) {
    final scale = h / 700.0;
    final bx = w * 0.79;
    final topY = h * 0.685;
    final bw = 46 * scale;
    final bh = 28 * scale;
    final roofH = 20 * scale;
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(bx - bw / 2, topY, bw, bh),
      Radius.circular(3 * scale),
    );
    canvas.drawRRect(bodyRect, Paint()..color = _barnBody);
    final roof = Path()
      ..moveTo(bx - bw / 2 - 3 * scale, topY)
      ..lineTo(bx, topY - roofH)
      ..lineTo(bx + bw / 2 + 3 * scale, topY)
      ..close();
    canvas.drawPath(roof, Paint()..color = _barnRoof);
    canvas.drawRect(
      Rect.fromLTWH(
        bx - 6 * scale,
        topY + bh - 15 * scale,
        12 * scale,
        15 * scale,
      ),
      Paint()..color = _barnDoor,
    );
  }

  void _drawField(Canvas canvas, double w, double h, double t) {
    final yField = h * 0.80;
    final fieldRect = Rect.fromLTWH(0, yField, w, h - yField);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [_fieldTop, _fieldBottom],
      ).createShader(fieldRect);
    canvas.drawRect(fieldRect, paint);

    final cx = w / 2;
    for (var i = 0; i < 17; i++) {
      final x = w * (i + 0.5) / 17;
      final sway = 0.5 + 0.5 * math.sin(2 * math.pi * t * 0.7 + i * 1.9);
      final offset = (cx - x) * (0.08 + 0.02 * sway);
      final path = Path()
        ..moveTo(x, yField)
        ..quadraticBezierTo(
          x + offset * 0.4,
          yField + (h - yField) * 0.5,
          x + offset,
          h,
        );
      canvas.drawPath(
        path,
        Paint()
          ..color = _furrow.withValues(alpha: 0.22)
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.2, h / 600),
      );
    }
    for (var i = 0; i < 8; i++) {
      final x = w * (i + 0.4) / 9;
      final top = yField + 10;
      final path = Path()
        ..moveTo(x, top)
        ..quadraticBezierTo(x + 4, top - 8, x + 9, top);
      canvas.drawPath(
        path,
        Paint()
          ..color = _furrow.withValues(alpha: 0.30)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }
  }

  void _drawFlowers(Canvas canvas, double w, double h, double t) {
    for (var i = 0; i < 12; i++) {
      final seed = i * 0.079;
      final fx = w * ((seed * 13 + 0.03) % 1.0);
      final bob = 0.5 + 0.5 * math.sin(2 * math.pi * t * 0.6 + seed * 20);
      final fy = h * (0.80 + 0.04 * bob + 0.03 * ((seed * 31) % 1.0));
      final r = math.max(w, h) * (0.007 + 0.005 * ((seed * 19) % 1.0));
      final petal = i.isEven
          ? const Color(0xFFFFF176)
          : (i % 3 == 0 ? const Color(0xFFF48FB1) : const Color(0xFFCE93D8));
      for (var k = 0; k < 5; k++) {
        final a = k * 2 * math.pi / 5;
        canvas.drawCircle(
          Offset(fx + math.cos(a) * r, fy + math.sin(a) * r),
          r * 0.55,
          Paint()..color = petal.withValues(alpha: 0.9),
        );
      }
      canvas.drawCircle(
        Offset(fx, fy),
        r * 0.5,
        Paint()..color = Colors.white.withValues(alpha: 0.95),
      );
    }
  }

  void _drawLeaf(Canvas canvas, double w, double h, double t, int i) {
    final seed = i * 0.6180339;
    final phase = (seed * 2 * math.pi) % (2 * math.pi);
    final speed = 0.16 + 0.09 * ((seed * 7) % 1.0);
    final cycle = t * speed + seed * 0.7;
    final frac = cycle - cycle.floorToDouble();

    final x =
        w *
        ((seed * 0.91 + 0.07 * math.sin(2 * math.pi * t + phase) + 1) % 1.0);
    final y = h * (1.18 - frac * 1.38);
    final fade = math.sin(math.pi * frac).clamp(0.0, 1.0);
    final size = 4.0 + 3.5 * ((seed * 13) % 1.0);
    final color = _leaves[i % _leaves.length];
    final angle = 2 * math.pi * (t * 0.3 + phase);

    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(angle);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: size, height: size * 0.5),
      Paint()..color = color.withValues(alpha: 0.55 * fade),
    );
    canvas.drawLine(
      Offset(-size * 0.25, 0),
      Offset(size * 0.2, 0),
      Paint()
        ..color = color.withValues(alpha: 0.45 * fade)
        ..strokeWidth = 1.0,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FarmPainter oldDelegate) => true;
}
