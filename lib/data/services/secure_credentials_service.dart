import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'storage_service.dart';

/// Stores Xtream profile passwords, keyed by profile id.
///
/// History / why Hive is the source of truth: `flutter_secure_storage` has been
/// unreliable across platforms for this app. On Windows it needed
/// `useBackwardCompatibility:false` to stop dropping values; on Android v10 it
/// can fail to read back a value that was just written (returns `null` even
/// after a clean install + fresh save), which left the app stuck on
/// "Nessuna playlist attiva" despite a valid profile.
///
/// Since this is a sideloaded personal app on a device the user controls, we
/// keep a Hive-backed copy as the reliable source of truth and treat the OS
/// secure store as a best-effort mirror. The Hive copy is lightly obfuscated
/// (NOT real encryption) so it isn't sitting as grep-able cleartext in the box
/// file; the OS secure store still holds a properly encrypted copy where it
/// works. Result: passwords survive on every device.
class SecureCredentialsService {
  SecureCredentialsService(this._storage);

  final FlutterSecureStorage _storage;

  String _keyFor(String profileId) => 'xtream_password_$profileId';

  // Fixed XOR key + base64. Deliberately light: it only prevents casual
  // plaintext exposure in the local Hive file, which is already in the app's
  // private storage.
  static const _obfKey = 'BrokenIPTV.credential.v1';

  String _obfuscate(String value) {
    final key = _obfKey.codeUnits;
    final bytes = utf8.encode(value);
    final out = List<int>.generate(
      bytes.length,
      (i) => bytes[i] ^ key[i % key.length],
    );
    return base64.encode(out);
  }

  String? _deobfuscate(String? stored) {
    if (stored == null || stored.isEmpty) return null;
    try {
      final bytes = base64.decode(stored);
      final key = _obfKey.codeUnits;
      final out = List<int>.generate(
        bytes.length,
        (i) => bytes[i] ^ key[i % key.length],
      );
      return utf8.decode(out);
    } catch (_) {
      return null;
    }
  }

  Future<void> savePassword(String profileId, String password) async {
    final key = _keyFor(profileId);
    // Reliable store first.
    await StorageService.credentialsBox.put(key, _obfuscate(password));
    // Best-effort mirror into the OS secure store (ignored if it throws or is
    // unavailable on this device).
    try {
      await _storage.write(key: key, value: password);
    } catch (_) {}
  }

  Future<String?> getPassword(String profileId) async {
    final key = _keyFor(profileId);
    // The reliable Hive copy is authoritative.
    final local = _deobfuscate(StorageService.credentialsBox.get(key));
    if (local != null && local.isNotEmpty) return local;

    // Older installs (before the Hive store existed) kept it only in the OS
    // secure store: read it there and backfill Hive so it stays reliable.
    try {
      final v = await _storage.read(key: key);
      if (v != null && v.isNotEmpty) {
        await StorageService.credentialsBox.put(key, _obfuscate(v));
        return v;
      }
    } catch (_) {}
    return null;
  }

  Future<void> deletePassword(String profileId) async {
    final key = _keyFor(profileId);
    await StorageService.credentialsBox.delete(key);
    try {
      await _storage.delete(key: key);
    } catch (_) {}
  }
}
