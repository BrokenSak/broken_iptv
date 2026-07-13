enum FavoriteType { live, vod, series }

class FavoriteItem {
  const FavoriteItem({
    required this.type,
    required this.id,
    required this.name,
    this.imageUrl,
  });

  final FavoriteType type;
  final String id;
  final String name;
  final String? imageUrl;

  String get key => '${type.name}:$id';

  Map<String, dynamic> toMap() => {
        'type': type.name,
        'id': id,
        'name': name,
        'imageUrl': imageUrl,
      };

  factory FavoriteItem.fromMap(Map<dynamic, dynamic> map) => FavoriteItem(
        type: FavoriteType.values.firstWhere((t) => t.name == map['type']),
        id: map['id'] as String,
        name: map['name'] as String,
        imageUrl: map['imageUrl'] as String?,
      );
}
