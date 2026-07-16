import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:broken_iptv/presentation/screens/player/player_keys.dart';

/// Rules for keys inside the player. The volume case is a real regression:
/// the player used to swallow the first key press to reveal its controls,
/// which ate the volume key too — the volume only moved from the 2nd press.
void main() {
  const volumeKeys = [
    LogicalKeyboardKey.audioVolumeUp,
    LogicalKeyboardKey.audioVolumeDown,
    LogicalKeyboardKey.audioVolumeMute,
  ];

  group('volume keys', () {
    test('are always passed to the OS, whatever the player state', () {
      for (final key in volumeKeys) {
        for (final visible in [true, false]) {
          expect(
            playerKeyAction(key: key, isKeyDown: true, controlsVisible: visible),
            PlayerKeyAction.ignore,
            reason: 'volume must never be consumed nor open the menu',
          );
        }
      }
    });
  });

  group('OK', () {
    test('opens the controls when they are hidden', () {
      expect(
        playerKeyAction(
          key: LogicalKeyboardKey.select,
          isKeyDown: true,
          controlsVisible: false,
        ),
        PlayerKeyAction.revealControls,
      );
    });

    test('goes to the focused button once the controls are up (never closes)', () {
      // Closing is Back's job / the inactivity timer's: with the controls open
      // OK must press whatever the remote has selected.
      for (final key in [
        LogicalKeyboardKey.select,
        LogicalKeyboardKey.enter,
        LogicalKeyboardKey.gameButtonA,
      ]) {
        expect(
          playerKeyAction(key: key, isKeyDown: true, controlsVisible: true),
          PlayerKeyAction.pokeAndPass,
        );
      }
    });
  });

  group('other keys', () {
    test('reveal hidden controls without acting', () {
      expect(
        playerKeyAction(
          key: LogicalKeyboardKey.arrowDown,
          isKeyDown: true,
          controlsVisible: false,
        ),
        PlayerKeyAction.revealControls,
      );
    });

    test('keep the controls awake and pass through when visible', () {
      expect(
        playerKeyAction(
          key: LogicalKeyboardKey.arrowDown,
          isKeyDown: true,
          controlsVisible: true,
        ),
        PlayerKeyAction.pokeAndPass,
      );
    });

    test('key-up events are never acted on (only key-down drives the UI)', () {
      expect(
        playerKeyAction(
          key: LogicalKeyboardKey.select,
          isKeyDown: false,
          controlsVisible: true,
        ),
        PlayerKeyAction.ignore,
      );
    });
  });
}
