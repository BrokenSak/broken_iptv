import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:broken_iptv/app.dart';
import 'package:broken_iptv/data/services/storage_service.dart';

void main() {
  setUpAll(() async {
    final dir = Directory.systemTemp.createTempSync('broken_iptv_test');
    await StorageService.init(testPath: dir.path);
  });

  testWidgets('App boots to the empty profiles screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: BrokenIptvApp()));
    await tester.pumpAndSettle();

    expect(find.text('Nessuna playlist'), findsOneWidget);
  });
}
