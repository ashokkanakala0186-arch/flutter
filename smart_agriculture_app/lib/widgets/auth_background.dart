import 'package:flutter/material.dart';

import 'animated_background.dart';

class AuthBackground extends StatelessWidget {
  const AuthBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBackground(
      scene: SkyScene.cloud,
      child: SafeArea(child: child),
    );
  }
}
