import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/favorite_item.dart';
import '../../state/favorites_providers.dart';

/// On Android, tiles support long-press to toggle a favorite (there is no
/// hover to reveal the heart). Returns null on desktop, where the heart
/// button is always visible.
VoidCallback? longPressFavorite(WidgetRef ref, FavoriteItem item) {
  if (!Platform.isAndroid) return null;
  return () => ref.read(favoritesProvider.notifier).toggle(item);
}

/// Long-press action for a "Continua a guardare" tile: opens a small sheet to
/// toggle the favorite or remove the item from continue-watching. Returns null
/// on desktop (Windows), where long-press is disabled — the on-tile × button is
/// used to remove instead.
VoidCallback? longPressContinueOptions(
  BuildContext context,
  WidgetRef ref,
  FavoriteItem favorite,
  Future<void> Function() onRemoveFromContinue,
) {
  if (!Platform.isAndroid) return null;
  return () => _showContinueOptions(context, ref, favorite, onRemoveFromContinue);
}

Future<void> _showContinueOptions(
  BuildContext context,
  WidgetRef ref,
  FavoriteItem favorite,
  Future<void> Function() onRemoveFromContinue,
) async {
  final isFav = ref.read(favoritesProvider.notifier).isFavorite(favorite.type, favorite.id);
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surfaceElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                favorite.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          ListTile(
            // D-pad: give the sheet a focused row so OK works right away.
            autofocus: true,
            leading: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: Colors.white),
            title: Text(isFav ? 'Rimuovi dai preferiti' : 'Aggiungi ai preferiti'),
            onTap: () {
              ref.read(favoritesProvider.notifier).toggle(favorite);
              Navigator.pop(sheetContext);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.white),
            title: const Text('Rimuovi da Continua a guardare'),
            onTap: () async {
              Navigator.pop(sheetContext);
              await onRemoveFromContinue();
            },
          ),
        ],
      ),
    ),
  );
}

class FavoriteButton extends ConsumerWidget {
  const FavoriteButton({
    super.key,
    required this.type,
    required this.id,
    required this.name,
    this.imageUrl,
  });

  final FavoriteType type;
  final String id;
  final String name;
  final String? imageUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(favoritesProvider);
    final isFav = ref.read(favoritesProvider.notifier).isFavorite(type, id);
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Material(
        color: Colors.black.withValues(alpha: 0.55),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => ref.read(favoritesProvider.notifier).toggle(
                FavoriteItem(type: type, id: id, name: name, imageUrl: imageUrl),
              ),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: isFav ? Colors.white : Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
