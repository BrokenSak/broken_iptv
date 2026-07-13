import '../models/channel.dart';
import '../models/epg_program.dart';
import '../models/series_item.dart';
import '../models/vod_item.dart';
import '../models/xtream_category.dart';

/// Account / subscription info shown in the Account panel.
class AccountInfo {
  const AccountInfo({
    this.status,
    this.expiresAt,
    this.isTrial,
    this.activeConnections,
    this.maxConnections,
    this.createdAt,
    this.serverUrl,
    this.timezone,
  });

  final String? status;
  final DateTime? expiresAt;
  final bool? isTrial;
  final int? activeConnections;
  final int? maxConnections;
  final DateTime? createdAt;
  final String? serverUrl;
  final String? timezone;
}

/// Abstraction over a playlist backend so the repositories don't care whether
/// the active playlist is an **Xtream Codes** account (`player_api.php`) or a
/// plain **M3U + XMLTV** playlist. Both provide the same catalog surface.
abstract class ContentSource {
  // Live TV
  Future<List<XtreamCategory>> getLiveCategories();
  Future<List<Channel>> getLiveStreams({String? categoryId});
  Future<List<EpgProgram>> getShortEpg(String streamId, {int limit = 20});
  String liveStreamUrl(String streamId, {String ext = 'ts'});
  String timeshiftUrl(String streamId, DateTime start, Duration duration, {String ext = 'ts'});

  // Movies (VOD)
  Future<List<XtreamCategory>> getVodCategories();
  Future<List<VodItem>> getVodStreams({String? categoryId});
  Future<VodDetail> getVodInfo(String vodId);
  String vodStreamUrl(String streamId, String containerExtension);

  // Series
  Future<List<XtreamCategory>> getSeriesCategories();
  Future<List<SeriesItem>> getSeries({String? categoryId});
  Future<SeriesDetail> getSeriesInfo(String seriesId);
  String seriesEpisodeUrl(String episodeId, String containerExtension);

  // Account
  Future<DateTime?> getExpiryDate();
  Future<AccountInfo?> getAccountInfo();
}
