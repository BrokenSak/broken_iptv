import 'package:hive_ce_flutter/hive_ce_flutter.dart';

/// Thin wrapper around the local Hive boxes used across the app.
/// Boxes hold plain Map data — no generated type adapters needed.
class StorageService {
  static const profilesBoxName = 'profiles';
  static const prefsBoxName = 'prefs';
  static const favoritesBoxName = 'favorites';
  static const watchProgressBoxName = 'watch_progress';

  static late Box<Map> profilesBox;
  static late Box prefsBox;
  static late Box<Map> favoritesBox;
  static late Box<Map> watchProgressBox;

  /// [testPath] lets tests point Hive at a plain temp directory instead of
  /// going through [Hive.initFlutter], which needs path_provider's platform
  /// channel and isn't available in a widget-test host.
  static Future<void> init({String? testPath}) async {
    if (testPath != null) {
      Hive.init(testPath);
    } else {
      await Hive.initFlutter();
    }
    profilesBox = await Hive.openBox<Map>(profilesBoxName);
    prefsBox = await Hive.openBox(prefsBoxName);
    favoritesBox = await Hive.openBox<Map>(favoritesBoxName);
    watchProgressBox = await Hive.openBox<Map>(watchProgressBoxName);
  }
}
