import 'package:flutter_test/flutter_test.dart';

import 'package:broken_iptv/core/ui_mode.dart';
import 'package:broken_iptv/data/services/device_mode_service.dart';

/// Focus policies for the D-pad. These are the rules that, when wrong, locked
/// real devices out — both cases below shipped once:
/// - focusability gated on TV mode → fresh install stuck on the device picker
///   (no mode saved yet → nothing focusable → the remote couldn't choose one);
/// - autofocus allowed on phones → the first tile of every grid lit up on its
///   own ("buttons lit that I never clicked").
void main() {
  group('dpadFocusPolicy (can anything take focus?)', () {
    test('any Android build: yes — even before a mode is chosen', () {
      expect(dpadFocusPolicy(isAndroid: true), isTrue);
    });

    test('Windows: never', () {
      expect(dpadFocusPolicy(isAndroid: false), isFalse);
    });
  });

  group('dpadAutofocusPolicy (may a screen pre-light its first element?)', () {
    test('REGRESSION: no mode chosen yet (device picker) must autofocus', () {
      // This is the fresh-install deadlock: the picker is the screen where the
      // mode gets chosen, so it cannot depend on a chosen mode.
      expect(dpadAutofocusPolicy(isAndroid: true, savedMode: null), isTrue);
    });

    test('TV mode: yes', () {
      expect(dpadAutofocusPolicy(isAndroid: true, savedMode: DeviceMode.tv), isTrue);
    });

    test('phone (touch) mode: never — nothing may light up on its own', () {
      expect(dpadAutofocusPolicy(isAndroid: true, savedMode: DeviceMode.touch), isFalse);
    });

    test('Windows: never', () {
      expect(dpadAutofocusPolicy(isAndroid: false, savedMode: null), isFalse);
      expect(dpadAutofocusPolicy(isAndroid: false, savedMode: DeviceMode.tv), isFalse);
    });
  });
}
