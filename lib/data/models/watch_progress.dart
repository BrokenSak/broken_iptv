enum WatchKind { vod, series }

/// A resume point for a movie or a series episode. Series progress is stored
/// per episode (so each episode gets its own bar); "Continua a guardare"
/// groups by series and shows the most recently watched episode.
class WatchProgress {
  const WatchProgress({
    required this.kind,
    required this.vodId,
    required this.seriesId,
    required this.episodeId,
    required this.episodeLabel,
    required this.name,
    required this.imageUrl,
    required this.url,
    required this.positionMs,
    required this.durationMs,
    required this.updatedAt,
  });

  final WatchKind kind;
  final String? vodId;
  final String? seriesId;
  final String? episodeId;
  final String? episodeLabel;
  final String name;
  final String? imageUrl;
  final String url;
  final int positionMs;
  final int durationMs;
  final int updatedAt;

  static String vodKey(String id) => 'vod:$id';
  static String seriesKey(String seriesId, String episodeId) => 'series:$seriesId:$episodeId';

  String get key => kind == WatchKind.vod
      ? vodKey(vodId!)
      : seriesKey(seriesId!, episodeId!);

  double get fraction {
    if (durationMs <= 0) return 0;
    return (positionMs / durationMs).clamp(0.0, 1.0);
  }

  bool get finished => fraction >= 0.95;
  bool get started => positionMs > 5000 && !finished;

  Map<String, dynamic> toMap() => {
        'kind': kind.name,
        'vodId': vodId,
        'seriesId': seriesId,
        'episodeId': episodeId,
        'episodeLabel': episodeLabel,
        'name': name,
        'imageUrl': imageUrl,
        'url': url,
        'positionMs': positionMs,
        'durationMs': durationMs,
        'updatedAt': updatedAt,
      };

  factory WatchProgress.fromMap(Map<dynamic, dynamic> m) => WatchProgress(
        kind: WatchKind.values.firstWhere((k) => k.name == m['kind']),
        vodId: m['vodId'] as String?,
        seriesId: m['seriesId'] as String?,
        episodeId: m['episodeId'] as String?,
        episodeLabel: m['episodeLabel'] as String?,
        name: m['name'] as String? ?? '',
        imageUrl: m['imageUrl'] as String?,
        url: m['url'] as String? ?? '',
        positionMs: (m['positionMs'] as num?)?.toInt() ?? 0,
        durationMs: (m['durationMs'] as num?)?.toInt() ?? 0,
        updatedAt: (m['updatedAt'] as num?)?.toInt() ?? 0,
      );
}
