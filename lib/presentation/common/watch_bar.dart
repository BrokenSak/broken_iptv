import 'package:flutter/material.dart';

/// Thin white progress bar showing how much of an item has been watched.
/// Empty = unwatched, partial = left off midway, full = finished.
class WatchBar extends StatelessWidget {
  const WatchBar({super.key, required this.fraction, this.height = 4});

  final double fraction;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: fraction.clamp(0.0, 1.0),
        minHeight: height,
        backgroundColor: Colors.white.withValues(alpha: 0.18),
        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
      ),
    );
  }
}
