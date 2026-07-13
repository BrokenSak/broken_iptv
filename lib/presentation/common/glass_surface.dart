import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Apple-style liquid glass panel: backdrop blur, translucent white tint,
/// hairline border and a soft top-left sheen. Use it for surfaces layered
/// over content (player controls, floating bars); for large grids prefer
/// the cheaper CardTheme look, which mimics the same material without blur.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.padding,
    this.blur = 28,
    this.tintAlpha = 0.08,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double blur;
  final double tintAlpha;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: AppColors.glassBorder, width: 1),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: tintAlpha + 0.04),
                Colors.white.withValues(alpha: tintAlpha - 0.03),
              ],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
