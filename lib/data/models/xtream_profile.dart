enum PlaylistKind { xtream, m3u }

class XtreamProfile {
  const XtreamProfile({
    required this.id,
    required this.name,
    required this.host,
    required this.username,
    this.kind = PlaylistKind.xtream,
    this.m3uUrl,
    this.epgUrl,
  });

  final String id;
  final String name;

  /// Xtream server base URL (kind == xtream). Empty for M3U playlists.
  final String host;
  final String username;

  /// How this playlist is served.
  final PlaylistKind kind;

  /// M3U playlist URL (kind == m3u).
  final String? m3uUrl;

  /// Optional XMLTV EPG URL (kind == m3u).
  final String? epgUrl;

  bool get isM3u => kind == PlaylistKind.m3u;

  XtreamProfile copyWith({
    String? name,
    String? host,
    String? username,
    PlaylistKind? kind,
    String? m3uUrl,
    String? epgUrl,
  }) {
    return XtreamProfile(
      id: id,
      name: name ?? this.name,
      host: host ?? this.host,
      username: username ?? this.username,
      kind: kind ?? this.kind,
      m3uUrl: m3uUrl ?? this.m3uUrl,
      epgUrl: epgUrl ?? this.epgUrl,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'host': host,
        'username': username,
        'kind': kind.name,
        'm3uUrl': m3uUrl,
        'epgUrl': epgUrl,
      };

  factory XtreamProfile.fromMap(Map<dynamic, dynamic> map) => XtreamProfile(
        id: map['id'] as String,
        name: map['name'] as String,
        host: (map['host'] as String?) ?? '',
        username: (map['username'] as String?) ?? '',
        kind: PlaylistKind.values.firstWhere(
          (k) => k.name == map['kind'],
          orElse: () => PlaylistKind.xtream,
        ),
        m3uUrl: map['m3uUrl'] as String?,
        epgUrl: map['epgUrl'] as String?,
      );
}
