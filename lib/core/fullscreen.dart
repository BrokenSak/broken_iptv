import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

/// Cross-platform fullscreen toggle: window_manager on Windows desktop,
/// immersive system UI on Android.
class FullscreenController extends Notifier<bool> {
  // Whether the window was maximized before we entered fullscreen, so we can
  // restore that exact state on exit.
  bool _wasMaximized = false;

  @override
  bool build() => false;

  Future<void> toggle() => set(!state);

  Future<void> set(bool value) async {
    if (Platform.isWindows) {
      if (value) {
        // window_manager can't transition cleanly straight from a *maximized*
        // window into fullscreen (it ends up stuck/half-covered), so drop the
        // maximized state first and remember it for the way back.
        _wasMaximized = await windowManager.isMaximized();
        if (_wasMaximized) {
          await windowManager.unmaximize();
          // Give Windows a moment to apply the restore before going fullscreen,
          // otherwise the fullscreen bounds are computed from the stale
          // maximized frame and the window looks broken.
          await Future<void>.delayed(const Duration(milliseconds: 120));
        }
        await windowManager.setFullScreen(true);
      } else {
        await windowManager.setFullScreen(false);
        // Restore the maximized state we came from.
        if (_wasMaximized) {
          await Future<void>.delayed(const Duration(milliseconds: 120));
          await windowManager.maximize();
          _wasMaximized = false;
        }
      }
    } else if (Platform.isAndroid) {
      await SystemChrome.setEnabledSystemUIMode(
        value ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
      );
    }
    state = value;
  }
}

final fullscreenProvider = NotifierProvider<FullscreenController, bool>(
  FullscreenController.new,
);
