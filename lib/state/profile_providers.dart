import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../data/models/xtream_profile.dart';
import '../data/repositories/profile_repository.dart';
import '../data/services/secure_credentials_service.dart';
import '../data/services/storage_service.dart';
import '../data/services/xtream_api_service.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  // On Windows, disable the legacy Credential-Manager backward-compat path:
  // its read→migrate→delete cycle can drop stored values if interrupted.
  // Sticking to the stable DPAPI file store keeps passwords persistent.
  return const FlutterSecureStorage(
    wOptions: WindowsOptions(useBackwardCompatibility: false),
  );
});

final secureCredentialsServiceProvider = Provider<SecureCredentialsService>((ref) {
  return SecureCredentialsService(ref.watch(secureStorageProvider));
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(secureCredentialsServiceProvider));
});

final xtreamApiServiceProvider = Provider<XtreamApiService>((ref) {
  return XtreamApiService();
});

class ProfilesNotifier extends Notifier<List<XtreamProfile>> {
  @override
  List<XtreamProfile> build() {
    return ref.watch(profileRepositoryProvider).getAll();
  }

  Future<void> upsert(XtreamProfile profile, {String? password}) async {
    final repo = ref.read(profileRepositoryProvider);
    await repo.save(profile, password: password);
    state = repo.getAll();
  }

  Future<void> remove(String id) async {
    final repo = ref.read(profileRepositoryProvider);
    await repo.delete(id);
    state = repo.getAll();
  }
}

final profilesProvider = NotifierProvider<ProfilesNotifier, List<XtreamProfile>>(
  ProfilesNotifier.new,
);

/// The profile currently in use for browsing Live/VOD/Series. Persisted so
/// the app always boots straight into the last selected playlist; switching
/// happens only from the Settings screen. Falls back to the first available
/// profile when the saved one no longer exists.
class SelectedProfileIdNotifier extends Notifier<String?> {
  static const _prefsKey = 'selected_profile_id';

  @override
  String? build() {
    final profiles = ref.watch(profilesProvider);
    final saved = StorageService.prefsBox.get(_prefsKey) as String?;
    if (saved != null && profiles.any((p) => p.id == saved)) return saved;
    return profiles.isNotEmpty ? profiles.first.id : null;
  }

  void select(String? id) {
    state = id;
    StorageService.prefsBox.put(_prefsKey, id);
  }
}

final selectedProfileIdProvider = NotifierProvider<SelectedProfileIdNotifier, String?>(
  SelectedProfileIdNotifier.new,
);
