import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:broken_iptv/data/services/storage_service.dart';
import 'package:broken_iptv/presentation/common/tv_focusable.dart';
import 'package:broken_iptv/presentation/screens/onboarding/device_mode_screen.dart';

/// End-to-end remote drive of the REAL device picker screen.
///
/// This reproduces the shipped deadlock: focusability used to depend on the
/// *saved* TV mode, but the picker runs before any mode exists — so nothing
/// was focusable and a remote could not even choose "TV". These tests press
/// actual keys against the real screen (prefs empty, like a fresh install).
void main() {
  setUpAll(() async {
    final dir = Directory.systemTemp.createTempSync('broken_iptv_picker_test');
    await StorageService.init(testPath: dir.path);
  });

  setUp(() {
    TvFocusable.debugDpadOverride = true; // behave like a TV / fresh install
    // No await: Hive clears the in-memory value synchronously, and awaiting
    // the disk flush under the test's fake-async clock can hang.
    StorageService.prefsBox.delete('device_mode');
  });

  tearDown(() {
    TvFocusable.debugDpadOverride = null;
  });

  Widget app() {
    final router = GoRouter(
      initialLocation: '/device-mode',
      routes: [
        GoRoute(path: '/device-mode', builder: (_, _) => const DeviceModeScreen()),
        GoRoute(
          path: '/profiles',
          builder: (_, _) => const Scaffold(body: Text('PROFILES_STUB')),
        ),
      ],
    );
    return MaterialApp.router(routerConfig: router);
  }

  /// Bounded pumps instead of pumpAndSettle (which can hang for its full
  /// 10-minute default on anything that keeps scheduling frames), plus a
  /// runAsync window so the real-IO Hive write inside `_choose` can complete
  /// before the navigation happens (same trick as profile_flow_test).
  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 250)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('fresh install: OK on the remote picks "TV / Telecomando"',
      (tester) async {
    await tester.pumpWidget(app());
    await settle(tester);

    // No taps, no arrows: the first card must already hold the focus
    // (autofocus), so a bare OK selects it.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.select);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.select);
    await settle(tester);

    expect(find.text('PROFILES_STUB'), findsOneWidget,
        reason: 'OK must select the focused card and move on');
    expect(StorageService.prefsBox.get('device_mode'), 'tv');
  });

  testWidgets('fresh install: arrow moves to the second card, OK picks touch',
      (tester) async {
    await tester.pumpWidget(app());
    await settle(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.select);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.select);
    await settle(tester);

    expect(find.text('PROFILES_STUB'), findsOneWidget);
    expect(StorageService.prefsBox.get('device_mode'), 'touch');
  });
}
