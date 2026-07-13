import 'package:uuid/uuid.dart';

import '../models/xtream_profile.dart';
import '../services/secure_credentials_service.dart';
import '../services/storage_service.dart';

class ProfileRepository {
  ProfileRepository(this._credentials);

  final SecureCredentialsService _credentials;
  final _uuid = const Uuid();

  List<XtreamProfile> getAll() {
    return StorageService.profilesBox.values
        .map(XtreamProfile.fromMap)
        .toList(growable: false);
  }

  String newId() => _uuid.v4();

  Future<void> save(XtreamProfile profile, {String? password}) async {
    await StorageService.profilesBox.put(profile.id, profile.toMap());
    if (password != null && password.isNotEmpty) {
      await _credentials.savePassword(profile.id, password);
    }
  }

  Future<void> delete(String id) async {
    await StorageService.profilesBox.delete(id);
    await _credentials.deletePassword(id);
  }

  Future<String?> getPassword(String id) => _credentials.getPassword(id);
}
