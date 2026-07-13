import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'data/services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await StorageService.init();

  if (Platform.isWindows) {
    await windowManager.ensureInitialized();
    const options = WindowOptions(
      title: 'Broken IPTV',
      minimumSize: Size(640, 420),
      titleBarStyle: TitleBarStyle.normal,
    );
    windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const ProviderScope(child: BrokenIptvApp()));
}
