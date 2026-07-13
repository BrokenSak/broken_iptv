// Xtream panels are notoriously inconsistent: where an object is expected they
// sometimes return an empty JSON array (e.g. "info": [], "episodes": []). A
// plain `value as Map?` cast then throws
// "type 'List<dynamic>' is not a subtype of type 'Map<...>?'". These helpers
// cast defensively so such responses never crash parsing.

/// Returns [v] as a String-keyed map when it really is a map, else an empty map.
Map<String, dynamic> asStringMap(dynamic v) =>
    v is Map ? v.cast<String, dynamic>() : <String, dynamic>{};

/// Returns [v] as a String-keyed map when it really is a map, else null.
Map<String, dynamic>? asStringMapOrNull(dynamic v) =>
    v is Map ? v.cast<String, dynamic>() : null;
