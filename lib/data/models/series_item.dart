import 'json_utils.dart';

class SeriesItem {
  const SeriesItem({
    required this.seriesId,
    required this.name,
    required this.categoryId,
    this.coverUrl,
    this.plot,
    this.rating,
    this.added = 0,
  });

  final String seriesId;
  final String name;
  final String categoryId;
  final String? coverUrl;
  final String? plot;
  final double? rating;

  /// Unix timestamp when the series was added/updated (for "Ultimi aggiunti").
  final int added;

  static double? _asDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  factory SeriesItem.fromJson(Map<String, dynamic> json) => SeriesItem(
        seriesId: json['series_id'].toString(),
        name: (json['name'] as String?)?.trim() ?? 'Serie',
        categoryId: (json['category_id'] ?? '').toString(),
        coverUrl: (json['cover'] as String?)?.trim().isNotEmpty == true
            ? json['cover'] as String
            : null,
        plot: json['plot'] as String?,
        rating: _asDouble(json['rating']),
        added: _asInt(json['last_modified'] ?? json['added']),
      );
}

class Episode {
  const Episode({
    required this.id,
    required this.title,
    required this.episodeNum,
    required this.season,
    required this.containerExtension,
    this.imageUrl,
  });

  final String id;
  final String title;
  final int episodeNum;
  final int season;
  final String containerExtension;
  final String? imageUrl;

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  factory Episode.fromJson(Map<String, dynamic> json, int season) {
    final info = asStringMap(json['info']);
    final img = (info['movie_image'] ?? info['cover_big'] ?? info['still_path']) as String?;
    return Episode(
      id: json['id'].toString(),
      title: (json['title'] as String?)?.trim() ?? 'Episodio',
      episodeNum: _asInt(json['episode_num']),
      season: season,
      containerExtension: (json['container_extension'] as String?) ?? 'mp4',
      imageUrl: (img != null && img.trim().isNotEmpty) ? img : null,
    );
  }
}

class SeriesDetail {
  const SeriesDetail({
    required this.seriesId,
    required this.name,
    this.coverUrl,
    this.plot,
    this.genre,
    required this.episodesBySeason,
  });

  final String seriesId;
  final String name;
  final String? coverUrl;
  final String? plot;
  final String? genre;
  final Map<int, List<Episode>> episodesBySeason;

  factory SeriesDetail.fromJson(String seriesId, Map<String, dynamic> json) {
    final info = asStringMap(json['info']);
    final episodesJson = asStringMap(json['episodes']);

    final episodesBySeason = <int, List<Episode>>{};
    for (final entry in episodesJson.entries) {
      final season = int.tryParse(entry.key) ?? 0;
      final list = entry.value;
      if (list is List) {
        episodesBySeason[season] = list
            .whereType<Map>()
            .map((e) => Episode.fromJson(e.cast<String, dynamic>(), season))
            .toList()
          ..sort((a, b) => a.episodeNum.compareTo(b.episodeNum));
      }
    }

    return SeriesDetail(
      seriesId: seriesId,
      name: (info['name'] as String?) ?? 'Serie',
      coverUrl: info['cover'] as String?,
      plot: info['plot'] as String?,
      genre: info['genre'] as String?,
      episodesBySeason: episodesBySeason,
    );
  }
}
