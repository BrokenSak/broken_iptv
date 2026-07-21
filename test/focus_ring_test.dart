import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:broken_iptv/core/theme/app_theme.dart';
import 'package:broken_iptv/core/ui_mode.dart';
import 'package:broken_iptv/data/services/device_mode_service.dart';
import 'package:broken_iptv/presentation/common/tv_focusable.dart';

/// The persistent focus ring must appear ONLY where a remote drives the UI.
/// The reported bug: on the phone the first item stayed ringed and touch
/// couldn't clear it. A node may still take focus on a phone (the remote has
/// to work even if the mode is wrong), but it must look no different.
Color? _ringColor(WidgetTester tester) {
  final container = tester.widget<AnimatedContainer>(
    find.descendant(
      of: find.byType(TvFocusable),
      matching: find.byType(AnimatedContainer),
    ),
  );
  return (container.decoration as BoxDecoration).border?.top.color;
}

Widget _wrap(FocusNode node) => MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: Center(
          child: TvFocusable(
            focusNode: node,
            autofocus: true,
            onTap: () {},
            child: const SizedBox(width: 80, height: 40),
          ),
        ),
      ),
    );

void main() {
  tearDown(() => debugDeviceModeOverride = null);

  testWidgets('TV mode: a focused tile shows the focus ring', (tester) async {
    debugDeviceModeOverride = DeviceMode.tv;
    final node = FocusNode();
    addTearDown(node.dispose);

    await tester.pumpWidget(_wrap(node));
    await tester.pumpAndSettle();

    expect(node.hasPrimaryFocus, isTrue, reason: 'autofocus lands on TV');
    expect(_ringColor(tester), AppColors.focusRing);
  });

  testWidgets('phone (touch): a focused tile shows NO ring', (tester) async {
    debugDeviceModeOverride = DeviceMode.touch;
    final node = FocusNode();
    addTearDown(node.dispose);

    await tester.pumpWidget(_wrap(node));
    await tester.pumpAndSettle();
    // Autofocus is off on touch; focus it by hand to prove that even a
    // genuinely-focused node stays invisible.
    node.requestFocus();
    await tester.pumpAndSettle();

    expect(node.hasPrimaryFocus, isTrue);
    expect(_ringColor(tester), Colors.transparent,
        reason: 'no persistent ring on a phone — only touch feedback');
  });
}
