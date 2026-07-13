import '../models/favorite_item.dart';
import '../services/storage_service.dart';

class FavoritesRepository {
  List<FavoriteItem> getAll() {
    return StorageService.favoritesBox.values
        .map(FavoriteItem.fromMap)
        .toList(growable: false);
  }

  bool isFavorite(FavoriteType type, String id) {
    return StorageService.favoritesBox.containsKey('${type.name}:$id');
  }

  Future<void> add(FavoriteItem item) {
    return StorageService.favoritesBox.put(item.key, item.toMap());
  }

  Future<void> remove(FavoriteType type, String id) {
    return StorageService.favoritesBox.delete('${type.name}:$id');
  }

  Future<void> toggle(FavoriteItem item) async {
    if (isFavorite(item.type, item.id)) {
      await remove(item.type, item.id);
    } else {
      await add(item);
    }
  }
}
