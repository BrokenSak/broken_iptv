/// What was downloaded: a movie or a single series episode.
enum DownloadType { vod, series }

/// Lifecycle of a download. `queued` waits for the single active slot,
/// `downloading` is in flight, `completed` has a playable local file, and
/// `failed` covers both errors and downloads interrupted by an app close.
enum DownloadStatus { queued, downloading, completed, failed }

/// One offline download. The [key] matches the `watch_progress` scheme
/// (`vod:<id>` / `series:<seriesId>:<episodeId>`) so a downloaded item and its
/// resume point line up.
class DownloadItem {
  const DownloadItem({
    required this.key,
    required this.type,
    required this.name,
    required this.remoteUrl,
    required this.containerExtension,
    required this.createdAt,
    this.filePath,
    this.imageUrl,
    this.vodId,
    this.seriesId,
    this.episodeId,
    this.episodeLabel,
    this.status = DownloadStatus.queued,
    this.received = 0,
    this.total = 0,
    this.error,
  });

  final String key;
  final DownloadType type;
  final String name;

  /// Panel URL the file is fetched from.
  final String remoteUrl;
  final String containerExtension;
  final int createdAt;

  /// Absolute path of the local file (set once the download starts).
  final String? filePath;
  final String? imageUrl;

  // Identity of the source item, so playback can track resume progress and the
  // catalog can tell what is already downloaded.
  final String? vodId;
  final String? seriesId;
  final String? episodeId;
  final String? episodeLabel;

  final DownloadStatus status;
  final int received;
  final int total;
  final String? error;

  static String vodKey(String streamId) => 'vod:$streamId';
  static String episodeKey(String seriesId, String episodeId) =>
      'series:$seriesId:$episodeId';

  double get fraction =>
      total > 0 ? (received / total).clamp(0.0, 1.0) : 0.0;

  bool get isCompleted => status == DownloadStatus.completed;
  bool get isActive =>
      status == DownloadStatus.queued || status == DownloadStatus.downloading;

  static const _keep = Object();

  DownloadItem copyWith({
    DownloadStatus? status,
    String? filePath,
    int? received,
    int? total,
    Object? error = _keep,
  }) {
    return DownloadItem(
      key: key,
      type: type,
      name: name,
      remoteUrl: remoteUrl,
      containerExtension: containerExtension,
      createdAt: createdAt,
      filePath: filePath ?? this.filePath,
      imageUrl: imageUrl,
      vodId: vodId,
      seriesId: seriesId,
      episodeId: episodeId,
      episodeLabel: episodeLabel,
      status: status ?? this.status,
      received: received ?? this.received,
      total: total ?? this.total,
      error: identical(error, _keep) ? this.error : error as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'key': key,
        'type': type.name,
        'name': name,
        'remoteUrl': remoteUrl,
        'containerExtension': containerExtension,
        'createdAt': createdAt,
        'filePath': filePath,
        'imageUrl': imageUrl,
        'vodId': vodId,
        'seriesId': seriesId,
        'episodeId': episodeId,
        'episodeLabel': episodeLabel,
        'status': status.name,
        'received': received,
        'total': total,
        'error': error,
      };

  factory DownloadItem.fromMap(Map<dynamic, dynamic> m) => DownloadItem(
        key: m['key'] as String,
        type: DownloadType.values
            .firstWhere((t) => t.name == m['type'], orElse: () => DownloadType.vod),
        name: m['name'] as String? ?? '',
        remoteUrl: m['remoteUrl'] as String? ?? '',
        containerExtension: m['containerExtension'] as String? ?? 'mp4',
        createdAt: (m['createdAt'] as num?)?.toInt() ?? 0,
        filePath: m['filePath'] as String?,
        imageUrl: m['imageUrl'] as String?,
        vodId: m['vodId'] as String?,
        seriesId: m['seriesId'] as String?,
        episodeId: m['episodeId'] as String?,
        episodeLabel: m['episodeLabel'] as String?,
        status: DownloadStatus.values.firstWhere(
            (s) => s.name == m['status'],
            orElse: () => DownloadStatus.failed),
        received: (m['received'] as num?)?.toInt() ?? 0,
        total: (m['total'] as num?)?.toInt() ?? 0,
        error: m['error'] as String?,
      );
}
