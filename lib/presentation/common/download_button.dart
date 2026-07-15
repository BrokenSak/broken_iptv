import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/download_item.dart';
import '../../state/downloads_providers.dart';
import 'app_dialogs.dart';
import 'tv_focusable.dart';

/// Reactive download control for a single catalog item. Watches the download
/// state for [template]'s key and shows: download / progress% (tap cancels) /
/// downloaded (tap deletes) / retry. Caller must gate visibility on
/// `downloadsSupported()` — this widget assumes it should be shown.
///
/// [compact] renders an icon-only chip (episode rows); otherwise a labelled
/// button (movie detail).
class DownloadButton extends ConsumerWidget {
  const DownloadButton({super.key, required this.template, this.compact = false});

  final DownloadItem template;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(downloadsProvider);
    DownloadItem? current;
    for (final it in items) {
      if (it.key == template.key) {
        current = it;
        break;
      }
    }
    final status = current?.status;

    IconData icon;
    String label;
    VoidCallback onTap;
    Widget? progressRing;

    switch (status) {
      case null:
        icon = Icons.download_outlined;
        label = 'Scarica';
        onTap = () => ref.read(downloadsProvider.notifier).enqueue(template);
      case DownloadStatus.queued:
        icon = Icons.hourglass_empty;
        label = 'In coda';
        onTap = () => ref.read(downloadsProvider.notifier).remove(template.key);
      case DownloadStatus.downloading:
        final pct = (current!.fraction * 100).round();
        icon = Icons.close;
        label = current.total > 0 ? '$pct%' : 'Scarico…';
        onTap = () => ref.read(downloadsProvider.notifier).remove(template.key);
        progressRing = SizedBox(
          width: compact ? 22 : 20,
          height: compact ? 22 : 20,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            value: current.total > 0 ? current.fraction : null,
            color: Colors.white,
            backgroundColor: Colors.white24,
          ),
        );
      case DownloadStatus.completed:
        icon = Icons.download_done;
        label = 'Scaricato';
        onTap = () async {
          final ok = await showAppConfirmDialog(
            context,
            title: 'Rimuovere il download?',
            message: '"${template.name}" verrà eliminato dalla memoria del dispositivo.',
            confirmLabel: 'Rimuovi',
          );
          if (ok) await ref.read(downloadsProvider.notifier).remove(template.key);
        };
      case DownloadStatus.failed:
        icon = Icons.refresh;
        label = 'Riprova';
        onTap = () => ref.read(downloadsProvider.notifier).enqueue(template);
    }

    final highlight = status == DownloadStatus.completed;
    final content = compact
        ? _chip(icon, label, progressRing, highlight)
        : _button(icon, label, progressRing, highlight);

    return TvFocusable(
      borderRadius: compact ? 10 : 14,
      onTap: onTap,
      child: content,
    );
  }

  Widget _button(IconData icon, String label, Widget? ring, bool highlight) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      decoration: BoxDecoration(
        color: highlight ? Colors.white : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ring ?? Icon(icon, size: 20, color: highlight ? Colors.black : AppColors.textPrimary),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: highlight ? Colors.black : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label, Widget? ring, bool highlight) {
    return Container(
      width: 62,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: highlight ? Colors.white.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ring ?? Icon(icon, size: 22, color: Colors.white),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
