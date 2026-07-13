import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';

/// Wraps a child so it works with both pointer (mouse/touch) and D-pad input.
///
/// On Windows only mouse+keyboard are used, so we suppress the TV-style
/// autofocus and the large focus scale (which used to overflow), and instead
/// show a subtle hover/focus highlight. On Android TV the D-pad focus ring
/// and a gentle scale remain.
class TvFocusable extends StatefulWidget {
  const TvFocusable({
    super.key,
    required this.child,
    required this.onTap,
    this.onLongPress,
    this.borderRadius = 16,
    this.autofocus = false,
    this.focusNode,
  });

  final Widget child;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final double borderRadius;
  final bool autofocus;
  final FocusNode? focusNode;

  @override
  State<TvFocusable> createState() => _TvFocusableState();
}

class _TvFocusableState extends State<TvFocusable> {
  bool _focused = false;
  bool _hovered = false;

  static final bool _isDesktop = Platform.isWindows;

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.gameButtonA ||
        key == LogicalKeyboardKey.numpadEnter) {
      widget.onTap();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final highlighted = _focused || _hovered;
    // Keep the scale small so a highlighted tile never spills past its bounds.
    final scale = highlighted ? (_isDesktop ? 1.015 : 1.03) : 1.0;

    return FocusableActionDetector(
      focusNode: widget.focusNode,
      // Never grab focus automatically on desktop: it would let arrow keys
      // drive navigation, which we don't want on Windows.
      autofocus: widget.autofocus && !_isDesktop,
      descendantsAreFocusable: true,
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      mouseCursor: SystemMouseCursors.click,
      child: Focus(
        skipTraversal: _isDesktop,
        onKeyEvent: _handleKey,
        child: GestureDetector(
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          child: AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 130),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 130),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border: Border.all(
                  color: highlighted ? AppColors.focusRing : Colors.transparent,
                  width: 2,
                ),
                boxShadow: highlighted
                    ? [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.18),
                          blurRadius: 14,
                          spreadRadius: 0,
                        ),
                      ]
                    : null,
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
