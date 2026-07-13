import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/xtream_profile.dart';
import '../../../state/profile_providers.dart';
import '../../common/app_logo.dart';
import '../../common/tv_focusable.dart';

class ProfilesScreen extends ConsumerWidget {
  const ProfilesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profiles = ref.watch(profilesProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLogo(size: 30),
            const SizedBox(width: 12),
            Text('Broken IPTV', style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
      body: profiles.isEmpty
          ? _EmptyState(onAdd: () => context.push('/profiles/add'))
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: profiles.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final profile = profiles[index];
                return _ProfileTile(
                  profile: profile,
                  autofocus: index == 0,
                  onSelect: () => context.push('/profiles/add', extra: profile),
                  onEdit: () => context.push('/profiles/add', extra: profile),
                  onDelete: () => _confirmDelete(context, ref, profile),
                );
              },
            ),
      floatingActionButton: profiles.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/profiles/add'),
              icon: const Icon(Icons.add),
              label: const Text('Aggiungi playlist'),
            ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, XtreamProfile profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminare playlist?'),
        content: Text('"${profile.name}" verrà rimossa insieme alle credenziali salvate.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annulla')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Elimina')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(profilesProvider.notifier).remove(profile.id);
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.live_tv_outlined, size: 56, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text('Nessuna playlist', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Aggiungi le credenziali Xtream Codes per iniziare',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Aggiungi playlist'),
          ),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.profile,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
    this.autofocus = false,
  });

  final XtreamProfile profile;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TvFocusable(
      onTap: onSelect,
      autofocus: autofocus,
      child: Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: const CircleAvatar(
            backgroundColor: AppColors.surfaceElevated,
            child: Icon(Icons.playlist_play, color: AppColors.accent),
          ),
          title: Text(profile.name, style: Theme.of(context).textTheme.titleLarge),
          subtitle: Text('${profile.username}@${profile.host}'),
          onTap: onSelect,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(icon: const Icon(Icons.edit_outlined), onPressed: onEdit),
              IconButton(icon: const Icon(Icons.delete_outline), onPressed: onDelete),
            ],
          ),
        ),
      ),
    );
  }
}
