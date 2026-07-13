import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores Xtream profile passwords in the platform secure storage
/// (Android Keystore / Windows Credential Locker), keyed by profile id.
class SecureCredentialsService {
  SecureCredentialsService(this._storage);

  final FlutterSecureStorage _storage;

  String _keyFor(String profileId) => 'xtream_password_$profileId';

  Future<void> savePassword(String profileId, String password) {
    return _storage.write(key: _keyFor(profileId), value: password);
  }

  Future<String?> getPassword(String profileId) {
    return _storage.read(key: _keyFor(profileId));
  }

  Future<void> deletePassword(String profileId) {
    return _storage.delete(key: _keyFor(profileId));
  }
}
