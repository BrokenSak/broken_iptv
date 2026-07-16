import 'package:flutter/services.dart';

/// What a key press should do in the player.
///
/// Kept out of the widget (and away from media_kit) so the rules are pure and
/// testable: the volume-key bug below shipped once already.
enum PlayerKeyAction {
  /// Not ours: let it through untouched. Volume keys land here so the OS
  /// changes the volume — consuming them is exactly what broke them before.
  ignore,

  /// Controls are hidden: reveal them and consume the key, so it can't
  /// blind-activate a button that is invisible but still focusable.
  revealControls,

  /// Keep the controls awake and let the focused widget handle the key: with
  /// the controls up, OK belongs to the focused button, and the arrows to the
  /// focus traversal. Closing is Back's job (and the auto-hide timer's).
  pokeAndPass,
}

/// Volume keys belong to the OS — the player must never react to them.
bool isVolumeKey(LogicalKeyboardKey k) =>
    k == LogicalKeyboardKey.audioVolumeUp ||
    k == LogicalKeyboardKey.audioVolumeDown ||
    k == LogicalKeyboardKey.audioVolumeMute;

/// OK / Enter / gamepad A — the "select" key across remotes and keyboards.
bool isSelectKey(LogicalKeyboardKey k) =>
    k == LogicalKeyboardKey.select ||
    k == LogicalKeyboardKey.enter ||
    k == LogicalKeyboardKey.numpadEnter ||
    k == LogicalKeyboardKey.gameButtonA;

/// Decides what a key press does in the player.
///
/// Note there is no "close" here: once the controls are up, every key belongs
/// to them (OK presses the focused button, arrows move between buttons). The
/// menu is closed with Back or by the inactivity timer.
PlayerKeyAction playerKeyAction({
  required LogicalKeyboardKey key,
  required bool isKeyDown,
  required bool controlsVisible,
}) {
  if (isVolumeKey(key)) return PlayerKeyAction.ignore;
  if (!isKeyDown) return PlayerKeyAction.ignore;
  if (!controlsVisible) return PlayerKeyAction.revealControls;
  return PlayerKeyAction.pokeAndPass;
}
