import 'json_utils.dart';

class VodItem {
  const VodItem({
    required this.streamId,
    required this.name,
    required this.categoryId,
    this.posterUrl,
    this.containerExtension,
    this.rating,
    this.added = 0,
  });

  final String streamId;
  final String name;
  final String categoryId;
  final String? posterUrl;
  final String? containerExtension;
  final double? rating;

  /// Unix timestamp when the item was added to the panel (for "Ultimi aggiunti").
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

  factory VodItem.fromJson(Map<String, dynamic> json) => VodItem(
        streamId: json['stream_id'].toString(),
        name: (json['name'] as String?)?.trim() ?? 'Film',
        categoryId: (json['category_id'] ?? '').toString(),
        posterUrl: (json['stream_icon'] as String?)?.trim().isNotEmpty == true
            ? json['stream_icon'] as String
            : null,
        containerExtension: json['container_extension'] as String?,
        rating: _asDouble(json['rating']),
        added: _asInt(json['added']),
      );
}

class VodDetail {
  const VodDetail({
    required this.streamId,
    required this.name,
    this.posterUrl,
    this.plot,
    this.genre,
    this.releaseDate,
    this.cast,
    this.director,
    this.rating,
    required this.containerExtension,
  });

  final String streamId;
  final String name;
  final String? posterUrl;
  final String? plot;
  final String? genre;
  final String? releaseDate;
  final String? cast;
  final String? director;
  final double? rating;
  final String containerExtension;

  factory VodDetail.fromJson(String streamId, Map<String, dynamic> json) {
    final info = asStringMap(json['info']);
    final movieData = asStringMap(json['movie_data']);
    return VodDetail(
      streamId: streamId,
      name: (info['name'] as String?) ?? (movieData['name'] as String?) ?? 'Film',
      posterUrl: info['movie_image'] as String?,
      plot: info['plot'] as String?,
      genre: info['genre'] as String?,
      releaseDate: info['releasedate'] as String?,
      cast: info['cast'] as String?,
      director: info['director'] as String?,
      rating: VodItem._asDouble(info['rating']),
      containerExtension: (movieData['container_extension'] as String?) ?? 'mp4',
    );
  }
}
