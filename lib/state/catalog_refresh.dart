import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/services/storage_service.dart';
import '../data/services/xtream_session.dart';
import 'live_providers.dart';
import 'series_providers.dart';
import 'vod_providers.dart';

final catalogRefreshingProvider = NotifierProvider<_RefreshingNotifier, bool>(
  _RefreshingNotifier.new,
);

class _RefreshingNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void set(bool v) => state = v;
}

/// Manual + automatic (every 24h) catalog refresh. Refreshing simply rebuilds
/// the session and category providers so the next screen re-fetches fresh
/// data from the panel.
class CatalogRefresh {
  CatalogRefresh(this._ref) {
    _scheduleAuto();
  }

  final Ref _ref;
  Timer? _timer;
  static const _lastKey = 'catalog_last_refresh';
  static const _interval = Duration(hours: 24);

  void _scheduleAuto() {
    // Refresh on startup if more than 24h have passed.
    final lastMs = StorageService.prefsBox.get(_lastKey) as int?;
    final last = lastMs != null ? DateTime.fromMillisecondsSinceEpoch(lastMs) : null;
    if (last == null || DateTime.now().difference(last) >= _interval) {
      _markRefreshed();
    }
    // Then keep refreshing on a 24h cadence while the app runs.
    _timer?.cancel();
    _timer = Timer.periodic(_interval, (_) => refreshNow());
  }

  void _markRefreshed() {
    StorageService.prefsBox.put(_lastKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Rebuilds the session/catalog providers and forces a real re-fetch so we
  /// actually know whether the playlist is reachable. Returns null on success
  /// or a human-readable message when the refresh failed.
  Future<String?> refreshNow() async {
    _ref.read(catalogRefreshingProvider.notifier).set(true);
    // Drop the profile's cached catalogs first: a manual/24h refresh must hit
    // the panel for real, not be answered by the disk cache.
    try {
      final source = await _ref.read(xtreamSessionProvider.future);
      if (source is XtreamSession) await source.clearCatalogCache();
    } catch (_) {}
    _ref.invalidate(xtreamSessionProvider);
    _ref.invalidate(liveRepositoryProvider);
    _ref.invalidate(vodRepositoryProvider);
    _ref.invalidate(seriesRepositoryProvider);
    _ref.invalidate(liveCategoriesProvider);
    _ref.invalidate(vodCategoriesProvider);
    _ref.invalidate(seriesCategoriesProvider);
    _markRefreshed();

    String? error;
    try {
      // Actually hit the panel so a failure (unreachable host, wrong
      // credentials, connection limit) surfaces instead of silently "refreshing".
      await _ref.read(liveCategoriesProvider.future);
    } on NoActivePlaylistException {
      // No playlist selected yet — nothing to refresh, not a failure to report.
    } catch (e) {
      error = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
    }

    _ref.read(catalogRefreshingProvider.notifier).set(false);
    return error;
  }

  void dispose() => _timer?.cancel();
}

final catalogRefreshProvider = Provider<CatalogRefresh>((ref) {
  final refresher = CatalogRefresh(ref);
  ref.onDispose(refresher.dispose);
  return refresher;
});
