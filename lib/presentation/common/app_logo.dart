import 'package:flutter/material.dart';

/// Black & white play-button brand mark, used everywhere the app name
/// would otherwise appear. A white rounded square with a black triangle.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.28;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.25),
            blurRadius: size * 0.4,
            spreadRadius: -size * 0.1,
          ),
        ],
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.only(left: size * 0.08),
          child: Icon(Icons.play_arrow_rounded, color: Colors.black, size: size * 0.66),
        ),
      ),
    );
  }
}
