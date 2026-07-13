class Channel {
  const Channel({
    required this.streamId,
    required this.name,
    required this.categoryId,
    this.logoUrl,
    this.epgChannelId,
    this.hasArchive = false,
    this.archiveDurationDays = 0,
  });

  final String streamId;
  final String name;
  final String categoryId;
  final String? logoUrl;
  final String? epgChannelId;
  final bool hasArchive;
  final int archiveDurationDays;

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  factory Channel.fromJson(Map<String, dynamic> json) => Channel(
        streamId: json['stream_id'].toString(),
        name: (json['name'] as String?)?.trim() ?? 'Canale',
        categoryId: (json['category_id'] ?? '').toString(),
        logoUrl: (json['stream_icon'] as String?)?.trim().isNotEmpty == true
            ? json['stream_icon'] as String
            : null,
        epgChannelId: (json['epg_channel_id'] as String?)?.trim().isNotEmpty == true
            ? json['epg_channel_id'] as String
            : null,
        hasArchive: (_asInt(json['tv_archive']) ?? 0) == 1,
        archiveDurationDays: _asInt(json['tv_archive_duration']) ?? 0,
      );
}
