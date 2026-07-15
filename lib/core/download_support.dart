import 'dart:io';

import '../data/services/device_mode_service.dart';

/// Downloads are a **phone-only** feature: available only on the Android APK
/// and only in touch (phone/tablet) mode — never on Windows and never on
/// Android TV, where saving media for offline use makes little sense. Every
/// download entry point (home button, detail-screen buttons) is gated on this.
bool downloadsSupported() =>
    Platform.isAndroid && DeviceModeService().getSaved() == DeviceMode.touch;
