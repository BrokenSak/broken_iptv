import 'dart:io';

import 'package:flutter/foundation.dart';

import '../data/services/device_mode_service.dart';

/// Test hook: pretend the app runs on Android with this saved device mode,
/// so widget tests (which run on the dev host, where Platform says Windows)
/// can drive the REAL screens as a TV or a phone. Null = real platform.
@visibleForTesting
DeviceMode? debugDeviceModeOverride;

DeviceMode? _savedMode() => debugDeviceModeOverride ?? DeviceModeService().getSaved();
bool get _isAndroidLike => debugDeviceModeOverride != null || Platform.isAndroid;

/// Running on a TV/Firestick: the Android APK with the saved device mode set
/// to [DeviceMode.tv]. Drives TV-only affordances (favourite heart as a badge,
/// focus landing on the player's main control, TV text fields).
bool isTvMode() => _isAndroidLike && _savedMode() == DeviceMode.tv;

/// Running on a phone/tablet: the Android APK in touch mode.
bool isPhoneMode() => _isAndroidLike && _savedMode() == DeviceMode.touch;

/// Whether TvFocusable nodes can take focus at all.
///
/// Any Android build — NOT just TV mode. Gating this on the *saved* mode
/// locked fresh installs out: the device picker shows before a mode exists,
/// `isTvMode()` was false, nothing was focusable, and a remote could not even
/// pick "TV" (the choice needed the very focus it would have enabled). It also
/// left a TV stuck in touch mode with a dead remote and no way to reach the
/// settings that fix it. Focusable-but-unfocused nodes are invisible on a
/// phone: nothing autofocuses there (see below) and taps never focus them.
bool dpadFocusEnabled() => dpadFocusPolicy(isAndroid: _isAndroidLike);

/// Whether `autofocus` requests should be honoured, pre-lighting the first
/// element of a screen. TV mode, plus the first launch **before a mode
/// exists** — that is the device picker itself, which must come up with a
/// focused card or a remote has nothing to press OK on. Never in touch mode:
/// an element lighting up on its own on a phone reads as a bug (reported).
bool dpadAutofocusEnabled() => dpadAutofocusPolicy(
      isAndroid: _isAndroidLike,
      savedMode: _savedMode(),
    );

/// Pure policy behind [dpadFocusEnabled], separated so tests can exercise it
/// on a host where Platform.isAndroid is false.
bool dpadFocusPolicy({required bool isAndroid}) => isAndroid;

/// Pure policy behind [dpadAutofocusEnabled]. `savedMode == null` (fresh
/// install, picker on screen) MUST allow autofocus — regression guard.
bool dpadAutofocusPolicy({required bool isAndroid, required DeviceMode? savedMode}) =>
    isAndroid && savedMode != DeviceMode.touch;
