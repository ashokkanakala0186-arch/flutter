import 'dart:math' as math;

import 'package:flutter/material.dart';

enum FarmScene { sunrise, sunny, cloudy, sunset, countryside }

class FarmBackground extends StatelessWidget {
  const FarmBackground({
    super.key,
    required this.child,
    this.scene = FarmScene.sunny,
  });

  final Widget child;
  final FarmScene scene;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(painter: FarmLandscapePainter(scene: scene)),
        child,
      ],
    );
  }
}

class _Blob {
  const _Blob({
    required this.dx,
    required this.dy,
    required this.radius,
    required this.color,
    required this.alpha,
  });

  final double dx;
  final double dy;
  final double radius;
  final Color color;
  final double alpha;
}

class _SceneSpec {
  const _SceneSpec({
    required this.sky,
    required this.hill,
    required this.hillAlpha,
    required this.blobs,
  });

  final List<Color> sky;
  final Color hill;
  final double hillAlpha;
  final List<_Blob> blobs;
}

const Map<FarmScene, _SceneSpec> _specs = {
  FarmScene.sunrise: _SceneSpec(
    sky: [Color(0xFFFEF6EB), Color(0xFFE9F4E7)],
    hill: Color(0xFFBFDCB6),
    hillAlpha: 0.14,
    blobs: [
      _Blob(
        dx: 0.18,
        dy: 0.16,
        radius: 0.30,
        color: Color(0xFFFFD9A0),
        alpha: 0.26,
      ),
      _Blob(
        dx: 0.86,
        dy: 0.62,
        radius: 0.28,
        color: Color(0xFFA8D8A0),
        alpha: 0.20,
      ),
    ],
  ),
  FarmScene.sunny: _SceneSpec(
    sky: [Color(0xFFE3F2FD), Color(0xFFF0F8EC)],
    hill: Color(0xFFB5D3B2),
    hillAlpha: 0.13,
    blobs: [
      _Blob(
        dx: 0.82,
        dy: 0.12,
        radius: 0.26,
        color: Color(0xFF90CAF9),
        alpha: 0.22,
      ),
      _Blob(
        dx: 0.08,
        dy: 0.80,
        radius: 0.30,
        color: Color(0xFFB7E0B0),
        alpha: 0.20,
      ),
      _Blob(
        dx: 0.50,
        dy: 0.38,
        radius: 0.20,
        color: Color(0xFFFFF1B8),
        alpha: 0.16,
      ),
    ],
  ),
  FarmScene.cloudy: _SceneSpec(
    sky: [Color(0xFFECEFF3), Color(0xFFF5F7F5)],
    hill: Color(0xFFC3D4C8),
    hillAlpha: 0.12,
    blobs: [
      _Blob(
        dx: 0.80,
        dy: 0.15,
        radius: 0.24,
        color: Color(0xFFCFE0EA),
        alpha: 0.26,
      ),
      _Blob(
        dx: 0.12,
        dy: 0.70,
        radius: 0.30,
        color: Color(0xFFD5E3D4),
        alpha: 0.20,
      ),
    ],
  ),
  FarmScene.sunset: _SceneSpec(
    sky: [Color(0xFFFFEFF3), Color(0xFFFDF3E9)],
    hill: Color(0xFFE4B7C2),
    hillAlpha: 0.15,
    blobs: [
      _Blob(
        dx: 0.85,
        dy: 0.14,
        radius: 0.26,
        color: Color(0xFFF8BBD0),
        alpha: 0.24,
      ),
      _Blob(
        dx: 0.12,
        dy: 0.62,
        radius: 0.30,
        color: Color(0xFFFFC98F),
        alpha: 0.20,
      ),
    ],
  ),
  FarmScene.countryside: _SceneSpec(
    sky: [Color(0xFFE8F5E9), Color(0xFFF4FAF0)],
    hill: Color(0xFFBEE0BB),
    hillAlpha: 0.13,
    blobs: [
      _Blob(
        dx: 0.52,
        dy: 0.06,
        radius: 0.30,
        color: Color(0xFFA5D6A7),
        alpha: 0.20,
      ),
      _Blob(
        dx: 0.90,
        dy: 0.78,
        radius: 0.26,
        color: Color(0xFFFFE0A3),
        alpha: 0.18,
      ),
    ],
  ),
};

class FarmLandscapePainter extends CustomPainter {
  const FarmLandscapePainter({this.scene = FarmScene.sunny});

  final FarmScene scene;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;
    final s = _specs[scene]!;

    _paintGradient(canvas, w, h, s);
    _paintBlobs(canvas, w, h, s);
    _paintHill(canvas, w, h, s);
  }

  void _paintGradient(Canvas canvas, double w, double h, _SceneSpec s) {
    final rect = Rect.fromLTWH(0, 0, w, h);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: s.sky,
      ).createShader(rect);
    canvas.drawRect(rect, paint);
  }

  void _paintBlobs(Canvas canvas, double w, double h, _SceneSpec s) {
    for (final blob in s.blobs) {
      final cx = w * blob.dx;
      final cy = h * blob.dy;
      final r = math.min(w, h) * blob.radius;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            blob.color.withValues(alpha: blob.alpha),
            blob.color.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
      canvas.drawCircle(Offset(cx, cy), r, paint);
    }
  }

  void _paintHill(Canvas canvas, double w, double h, _SceneSpec s) {
    final path = Path()
      ..moveTo(0, h * 0.80)
      ..quadraticBezierTo(w * 0.30, h * 0.72, w * 0.55, h * 0.79)
      ..quadraticBezierTo(w * 0.85, h * 0.86, w, h * 0.80)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      path,
      Paint()..color = s.hill.withValues(alpha: s.hillAlpha),
    );
  }

  @override
  bool shouldRepaint(covariant FarmLandscapePainter oldDelegate) {
    return oldDelegate.scene != scene;
  }
}
