import 'package:flutter/material.dart';

/// App-wide backdrop: the Broken IPTV wallpaper, covered by a subtle dark
/// scrim so foreground content (text, tiles, controls) always stays readable
/// whatever the image contains. Applied per-route (see app_router) so each
/// pushed page is opaque and fully covers the previous one during transitions.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Solid base first, so there is never a see-through flash before the
        // image is decoded.
        const ColoredBox(color: Color(0xFF000000)),
        Image.asset(
          'assets/images/wallpaper.png',
          fit: BoxFit.cover,
          // If the asset ever fails to load, fall back to plain black rather
          // than showing a broken-image glyph.
          errorBuilder: (_, _, _) => const ColoredBox(color: Color(0xFF000000)),
        ),
        // Gentle dark scrim to keep contrast high over any wallpaper region,
        // while still letting the image show through.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x59000000), Color(0x8C000000)],
            ),
          ),
          child: SizedBox.expand(),
        ),
        child,
      ],
    );
  }
}
