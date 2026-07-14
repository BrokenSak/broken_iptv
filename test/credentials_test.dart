import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:broken_iptv/data/services/secure_credentials_service.dart';
import 'package:broken_iptv/data/services/storage_service.dart';

/// The OS secure store isn't wired up in a test host, so every call throws —
/// exactly the "secure storage unavailable" situation we must survive. The
/// service must still round-trip the password through its Hive-backed store.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final dir = Directory.systemTemp.createTempSync('broken_iptv_creds_test');
    await StorageService.init(testPath: dir.path);
  });

  test('password round-trips via Hive even when secure storage fails', () async {
    final svc = SecureCredentialsService(const FlutterSecureStorage());

    await svc.savePassword('profile-1', 'sup3r-segreta');
    expect(await svc.getPassword('profile-1'), 'sup3r-segreta');

    // Not stored as cleartext in the box.
    expect(StorageService.credentialsBox.get('xtream_password_profile-1'),
        isNot(contains('sup3r-segreta')));

    await svc.deletePassword('profile-1');
    expect(await svc.getPassword('profile-1'), isNull);
  });

  test('handles special characters and unicode', () async {
    final svc = SecureCredentialsService(const FlutterSecureStorage());
    const pw = 'p@ss/wörd:+=&é#';
    await svc.savePassword('profile-2', pw);
    expect(await svc.getPassword('profile-2'), pw);
  });
}
