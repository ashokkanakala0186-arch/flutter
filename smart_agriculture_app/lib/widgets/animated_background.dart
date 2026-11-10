import 'dart:math' as math;

import 'package:flutter/material.dart';

enum SkyScene { sunshine, meadow, dawn, dusk, cloud }

class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({
    super.key,
    required this.child,
    this.scene = SkyScene.sunshine,
    this.showParticles = true,
    this.showHills = true,
    this.particleCount = 14,
  });

  final Widget child;
  final SkyScene scene;
  final bool showParticles;
  final bool showHills;
  final int particleCount;

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 26),
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
          painter: _SkyPainter(
            scene: widget.scene,
            controller: _controller,
            particleCount: widget.particleCount,
            showParticles: widget.showParticles,
            showHills: widget.showHills,
          ),
          isComplex: true,
          willChange: true,
        ),
        widget.child,
      ],
    );
  }
}

class _Scene {
  const _Scene({
    required this.sky,
    this.sun,
    this.sunPos = const Offset(0.84, 0.18),
    this.sunRadius = 0.035,
    required this.hillFar,
    required this.hillNear,
    required this.flowers,
    required this.leaves,
    this.clouds = 0,
  });

  final List<Color> sky;
  final Color? sun;
  final Offset sunPos;
  final double sunRadius;
  final Color hillFar;
  final Color hillNear;
  final List<Color> flowers;
  final List<Color> leaves;
  final int clouds;
}

const Map<SkyScene, _Scene> _scenes = {
  SkyScene.sunshine: _Scene(
    sky: [Color(0xFF8ED6F7), Color(0xFFBFF5DE), Color(0xFFFFF3B8)],
    sun: Color(0xFFFFD54F),
    sunPos: Offset(0.84, 0.16),
    sunRadius: 0.035,
    hillFar: Color(0xFFA9D8A3),
    hillNear: Color(0xFF5FBF73),
    flowers: [
      Color(0xFFFFF176),
      Color(0xFFF48FB1),
      Color(0xFFCE93D8),
      Color(0xFFFF8A65),
      Color(0xFF4FC3F7),
    ],
    leaves: [
      Color(0xFF43A047),
      Color(0xFFFFB74D),
      Color(0xFF29B6F6),
      Color(0xFFFFD54F),
      Color(0xFFEF9A9A),
    ],
    clouds: 3,
  ),
  SkyScene.meadow: _Scene(
    sky: [Color(0xFFA6E3B8), Color(0xFFD6F5CE), Color(0xFFFFF6C9)],
    sun: Color(0xFFFFF176),
    sunPos: Offset(0.80, 0.20),
    sunRadius: 0.030,
    hillFar: Color(0xFF9BD4A0),
    hillNear: Color(0xFF66BB6A),
    flowers: [
      Color(0xFFFFF176),
      Color(0xFFFFF8E1),
      Color(0xFFF48FB1),
      Color(0xFFCE93D8),
      Color(0xFFFFAB91),
    ],
    leaves: [
      Color(0xFF43A047),
      Color(0xFFFFD54F),
      Color(0xFF81C784),
      Color(0xFFF06292),
      Color(0xFF90CAF9),
    ],
    clouds: 2,
  ),
  SkyScene.dawn: _Scene(
    sky: [Color(0xFFF7B267), Color(0xFFFFD5A1), Color(0xFFF3D8E8)],
    sun: Color(0xFFFFE082),
    sunPos: Offset(0.52, 0.62),
    sunRadius: 0.028,
    hillFar: Color(0xFFC9DDA8),
    hillNear: Color(0xFF96C58A),
    flowers: [
      Color(0xFFFFD54F),
      Color(0xFFF48FB1),
      Color(0xFFFF8A65),
      Color(0xFFF8BBD0),
      Color(0xFFCE93D8),
    ],
    leaves: [
      Color(0xFFFFB74D),
      Color(0xFFF48FB1),
      Color(0xFF81C784),
      Color(0xFFFB8C00),
      Color(0xFFFF8A80),
    ],
    clouds: 2,
  ),
  SkyScene.dusk: _Scene(
    sky: [Color(0xFFF48FB1), Color(0xFFFFB7B2), Color(0xFFFFE0B2)],
    sun: Color(0xFFFFF176),
    sunPos: Offset(0.18, 0.56),
    sunRadius: 0.026,
    hillFar: Color(0xFFCEB6D9),
    hillNear: Color(0xFFA5C8A0),
    flowers: [
      Color(0xFFFFF176),
      Color(0xFFF06292),
      Color(0xFFE1BEE7),
      Color(0xFFFFD54F),
    ],
    leaves: [
      Color(0xFFF06292),
      Color(0xFFFFB74D),
      Color(0xFF81C784),
      Color(0xFFCE93D8),
      Color(0xFFFF8A80),
    ],
    clouds: 2,
  ),
  SkyScene.cloud: _Scene(
    sky: [Color(0xFFB0D6F0), Color(0xFFE3F0F5), Color(0xFFFDF2CE)],
    hillFar: Color(0xFFAFC9B7),
    hillNear: Color(0xFF84B98C),
    flowers: [
      Color(0xFFFFF176),
      Color(0xFFA5D6A7),
      Color(0xFFF8BBD0),
      Color(0xFFFFD54F),
      Color(0xFFCE93D8),
    ],
    leaves: [
      Color(0xFF90CAF9),
      Color(0xFF81C784),
      Color(0xFFFFB74D),
      Color(0xFFCFD8DC),
    ],
    clouds: 4,
  ),
};

class _SkyPainter extends CustomPainter {
  _SkyPainter({
    required this.scene,
    required this.controller,
    required this.particleCount,
    required this.showParticles,
    required this.showHills,
  }) : super(repaint: controller);

  final SkyScene scene;
  final AnimationController controller;
  final int particleCount;
  final bool showParticles;
  final bool showHills;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;
    final t = controller.value;
    final cfg = _scenes[scene]!;
    final rect = Rect.fromLTWH(0, 0, w, h);

    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: const [0.0, 0.55, 1.0],
        colors: cfg.sky,
      ).createShader(rect);
    canvas.drawRect(rect, skyPaint);

    final breath = 0.5 + 0.5 * math.sin(2 * math.pi * t);
    canvas.drawRect(
      rect,
      Paint()..color = Colors.white.withValues(alpha: 0.05 * breath),
    );

    final glowT = 0.5 + 0.5 * math.sin(2 * math.pi * t);
    _drawGlow(
      canvas,
      w * (0.14 + 0.05 * glowT),
      h * 0.16,
      math.max(w, h) * 0.34,
      cfg.sky[0],
      0.35,
    );
    _drawGlow(
      canvas,
      w * (0.88 - 0.05 * glowT),
      h * 0.62,
      math.max(w, h) * 0.30,
      cfg.sky[2],
      0.25,
    );

    final sun = cfg.sun;
    if (sun != null) {
      _drawSun(
        canvas,
        Offset(cfg.sunPos.dx * w, cfg.sunPos.dy * h),
        math.max(w, h) * cfg.sunRadius,
        sun,
        t,
      );
    }

    if (cfg.clouds > 0) {
      for (var i = 0; i < cfg.clouds; i++) {
        final seed = i * 0.37;
        final cx = w * ((seed + 0.10 * i + t * 0.012) % 1.0);
        final cy = h * (0.10 + 0.20 * ((seed * 11) % 1.0));
        final s = math.min(w, h) * (0.05 + 0.02 * ((seed * 7) % 1.0));
        _drawCloud(canvas, cx, cy, s, 0.75 + 0.08 * ((6 - i) % 3) * 0.05);
      }
    }

    if (showHills) {
      final move = 0.012 * math.sin(2 * math.pi * t);
      _drawFarHill(canvas, w, h, cfg.hillFar, move);
      _drawNearHill(canvas, w, h, cfg.hillNear, move);
      _drawFlowers(canvas, w, h, t, cfg);
    }

    if (showParticles) {
      for (var i = 0; i < particleCount; i++) {
        _drawLeaf(canvas, w, h, t, i, cfg);
      }
    }
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

  void _drawSun(Canvas canvas, Offset p, double r, Color color, double t) {
    final pulse = 0.5 + 0.5 * math.sin(2 * math.pi * t * 0.7);
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.50 + 0.15 * pulse),
          color.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: p, radius: r * 3.1));
    canvas.drawCircle(p, r * 3.1, glowPaint);

    final rayPaint = Paint()..color = color.withValues(alpha: 0.55);
    final rot = 2 * math.pi * t * 0.20;
    for (var i = 0; i < 8; i++) {
      final a = rot + i * math.pi / 4;
      final dir = Offset(math.cos(a), math.sin(a));
      final base = p + dir * (r * 1.35);
      final tip = p + dir * (r * (2.0 + 0.25 * pulse));
      final c1 = p + _rotate(dir, 0.20) * (r * 1.60);
      final c2 = p + _rotate(dir, -0.20) * (r * 1.60);
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
    canvas.drawCircle(p, r * 0.82, Paint()..color = color);
  }

  Offset _rotate(Offset v, double a) {
    final c = math.cos(a);
    final s = math.sin(a);
    return Offset(v.dx * c - v.dy * s, v.dx * s + v.dy * c);
  }

  void _drawCloud(Canvas canvas, double cx, double cy, double s, double o) {
    final paint = Paint()..color = Colors.white.withValues(alpha: o);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: s * 3.4, height: s * 0.85),
      paint,
    );
    canvas.drawCircle(Offset(cx - s * 0.75, cy + s * 0.10), s * 0.52, paint);
    canvas.drawCircle(Offset(cx + s * 0.60, cy + s * 0.14), s * 0.46, paint);
    canvas.drawCircle(Offset(cx, cy - s * 0.16), s * 0.62, paint);
  }

  void _drawFarHill(
    Canvas canvas,
    double w,
    double h,
    Color color,
    double move,
  ) {
    final path = Path()
      ..moveTo(0, h * (0.78 + move))
      ..quadraticBezierTo(
        w * 0.30,
        h * (0.68 + move),
        w * 0.60,
        h * (0.76 + move),
      )
      ..quadraticBezierTo(w * 0.85, h * (0.82 + move), w, h * (0.74 + move))
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawNearHill(
    Canvas canvas,
    double w,
    double h,
    Color color,
    double move,
  ) {
    final path = Path()
      ..moveTo(0, h * (0.92 - move))
      ..quadraticBezierTo(
        w * 0.28,
        h * (0.80 + move),
        w * 0.55,
        h * (0.94 - move),
      )
      ..quadraticBezierTo(w * 0.80, h * 1.03, w, h * (0.90 - move))
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawFlowers(Canvas canvas, double w, double h, double t, _Scene cfg) {
    for (var i = 0; i < 14; i++) {
      final seed = i * 0.071;
      final fx = w * ((seed * 13 + 0.05) % 1.0);
      final bob = 0.5 + 0.5 * math.sin(2 * math.pi * t * 0.6 + seed * 20);
      final fy = h * (0.84 + 0.05 * bob + 0.02 * ((seed * 31) % 1.0));
      final r = math.max(w, h) * (0.009 + 0.005 * ((seed * 19) % 1.0));
      final petal = cfg.flowers[i % cfg.flowers.length];
      final center = i.isEven ? Colors.white : Color(0xFFFFF176);
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
        r * 0.50,
        Paint()..color = center.withValues(alpha: 0.95),
      );
    }
  }

  void _drawLeaf(
    Canvas canvas,
    double w,
    double h,
    double t,
    int i,
    _Scene cfg,
  ) {
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
    final color = cfg.leaves[i % cfg.leaves.length];
    final angle = 2 * math.pi * (t * 0.3 + phase);

    final leafPaint = Paint()..color = color.withValues(alpha: 0.55 * fade);
    final stemPaint = Paint()
      ..color = color.withValues(alpha: 0.45 * fade)
      ..strokeWidth = 1.0;

    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(angle);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: size, height: size * 0.5),
      leafPaint,
    );
    canvas.drawLine(Offset(-size * 0.25, 0), Offset(size * 0.2, 0), stemPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SkyPainter oldDelegate) => true;
}
