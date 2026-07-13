import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/favorite_item.dart';
import '../data/repositories/favorites_repository.dart';

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return FavoritesRepository();
});

class FavoritesNotifier extends Notifier<List<FavoriteItem>> {
  @override
  List<FavoriteItem> build() {
    return ref.watch(favoritesRepositoryProvider).getAll();
  }

  Future<void> toggle(FavoriteItem item) async {
    final repo = ref.read(favoritesRepositoryProvider);
    await repo.toggle(item);
    state = repo.getAll();
  }

  bool isFavorite(FavoriteType type, String id) {
    return state.any((f) => f.type == type && f.id == id);
  }
}

final favoritesProvider = NotifierProvider<FavoritesNotifier, List<FavoriteItem>>(
  FavoritesNotifier.new,
);
