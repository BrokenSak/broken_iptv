import 'dart:convert';

class EpgProgram {
  const EpgProgram({
    required this.title,
    required this.description,
    required this.start,
    required this.end,
  });

  final String title;
  final String description;
  final DateTime start;
  final DateTime end;

  bool get isLive {
    final now = DateTime.now();
    return now.isAfter(start) && now.isBefore(end);
  }

  bool get isPast => DateTime.now().isAfter(end);

  static const _placeholderPhrases = [
    'epg non disponibile',
    'epg not available',
    'no epg',
    'not available',
    'non disponibile',
    'no information',
    'nessuna informazione',
    'no data',
  ];

  /// True for the fake filler entries some panels emit for channels without a
  /// real guide ("EPG NON DISPONIBILE" & co., or entries with no/zero-length
  /// time span — the parser falls back to `now` for missing timestamps, which
  /// is where the "random time with a bar" came from). The UI must treat these
  /// as "no EPG at all" and show nothing.
  bool get isPlaceholder {
    if (!end.isAfter(start)) return true;
    final t = title.trim().toLowerCase();
    if (t.isEmpty) return true;
    return _placeholderPhrases.any(t.contains);
  }

  static String _decodeBase64(dynamic v) {
    if (v == null) return '';
    var s = v.toString();
    if (s.isEmpty) return '';
    final padded = s.padRight((s.length + 3) ~/ 4 * 4, '=');
    try {
      return utf8.decode(base64.decode(padded));
    } catch (_) {
      return s;
    }
  }

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  factory EpgProgram.fromJson(Map<String, dynamic> json) {
    final startTs = _asInt(json['start_timestamp']);
    final endTs = _asInt(json['stop_timestamp']);
    return EpgProgram(
      title: _decodeBase64(json['title']),
      description: _decodeBase64(json['description']),
      start: startTs != null
          ? DateTime.fromMillisecondsSinceEpoch(startTs * 1000)
          : DateTime.now(),
      end: endTs != null
          ? DateTime.fromMillisecondsSinceEpoch(endTs * 1000)
          : DateTime.now(),
    );
  }
}
