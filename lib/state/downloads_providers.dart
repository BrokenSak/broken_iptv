import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/download_item.dart';
import '../data/repositories/downloads_repository.dart';
import '../data/services/download_service.dart';

final downloadServiceProvider = Provider<DownloadService>((ref) => DownloadService());
final downloadsRepositoryProvider =
    Provider<DownloadsRepository>((ref) => DownloadsRepository());

/// Orchestrates offline downloads: one active transfer at a time (a queue), so
/// the app never opens several parallel connections to the panel — the same
/// flood-protection concern that shaped the EPG/catalog code. Progress updates
/// stream to the UI; state is persisted on transitions and periodically.
class DownloadsNotifier extends Notifier<List<DownloadItem>> {
  final _tokens = <String, CancelToken>{};
  bool _pumping = false;

  @override
  List<DownloadItem> build() {
    final repo = ref.watch(downloadsRepositoryProvider);
    // Anything not completed on load was interrupted by an app close (partial
    // files were removed on error): surface as failed so the user can retry.
    final items = repo.getAll().map((it) {
      return it.isCompleted
          ? it
          : it.copyWith(status: DownloadStatus.failed, error: 'Interrotto');
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  DownloadItem? byKey(String key) {
    for (final it in state) {
      if (it.key == key) return it;
    }
    return null;
  }

  /// Queues [template] for download. No-op if it is already downloaded or in
  /// flight; a previously failed entry is re-queued (retry).
  Future<void> enqueue(DownloadItem template) async {
    final existing = byKey(template.key);
    if (existing != null && (existing.isCompleted || existing.isActive)) return;
    final queued = template.copyWith(
      status: DownloadStatus.queued,
      received: 0,
      total: 0,
      error: null,
    );
    await _upsert(queued);
    unawaited(_pump());
  }

  Future<void> retry(String key) async {
    final item = byKey(key);
    if (item == null || item.isActive) return;
    await _upsert(item.copyWith(status: DownloadStatus.queued, received: 0, total: 0, error: null));
    unawaited(_pump());
  }

  /// Cancels (if active) and deletes the entry and its local file. Used both
  /// for "remove downloaded" and "cancel in-progress".
  Future<void> remove(String key) async {
    _tokens.remove(key)?.cancel('removed');
    final item = byKey(key);
    if (item != null) {
      await ref.read(downloadServiceProvider).deleteFile(item.filePath);
    }
    await ref.read(downloadsRepositoryProvider).remove(key);
    state = [
      for (final it in state)
        if (it.key != key) it,
    ];
  }

  Future<void> _pump() async {
    if (_pumping) return;
    _pumping = true;
    try {
      while (true) {
        DownloadItem? next;
        for (final it in state) {
          if (it.status == DownloadStatus.queued) {
            next = it;
            break;
          }
        }
        if (next == null) break;
        await _run(next);
      }
    } finally {
      _pumping = false;
    }
  }

  Future<void> _run(DownloadItem item) async {
    final service = ref.read(downloadServiceProvider);
    final token = CancelToken();
    _tokens[item.key] = token;

    final path = await service.filePathFor(item.key, item.containerExtension);
    await _upsert(item.copyWith(
      status: DownloadStatus.downloading,
      filePath: path,
      error: null,
    ));

    var lastUi = DateTime.now();
    var lastPersist = DateTime.now();
    var lastReceived = 0;
    var lastTotal = 0;
    try {
      await service.download(
        url: item.remoteUrl,
        savePath: path,
        cancelToken: token,
        onProgress: (received, total) {
          lastReceived = received;
          if (total > 0) lastTotal = total;
          final cur = byKey(item.key);
          if (cur == null) return;
          final updated = cur.copyWith(received: received, total: total > 0 ? total : cur.total);
          final now = DateTime.now();
          // Throttle UI rebuilds (dio fires this very often) and disk writes.
          if (now.difference(lastUi) > const Duration(milliseconds: 300)) {
            lastUi = now;
            _replaceInState(updated);
          }
          if (now.difference(lastPersist) > const Duration(seconds: 5)) {
            lastPersist = now;
            unawaited(ref.read(downloadsRepositoryProvider).save(updated));
          }
        },
      );
      final done = byKey(item.key);
      if (done != null) {
        // Pin the final byte counts: the last progress tick may have been
        // throttled out of state, which would show "0 MB" on a fast download.
        await _upsert(done.copyWith(
          status: DownloadStatus.completed,
          received: lastReceived,
          total: lastTotal > 0 ? lastTotal : done.total,
        ));
      }
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        // Removed/cancelled: the entry is already gone from state.
      } else {
        final cur = byKey(item.key);
        if (cur != null) {
          await _upsert(cur.copyWith(
            status: DownloadStatus.failed,
            error: 'Download non riuscito. Controlla la connessione.',
          ));
        }
      }
    } catch (_) {
      final cur = byKey(item.key);
      if (cur != null) {
        await _upsert(cur.copyWith(status: DownloadStatus.failed, error: 'Download non riuscito.'));
      }
    } finally {
      _tokens.remove(item.key);
    }
  }

  /// In-memory only (progress ticks): swap the item without touching disk.
  void _replaceInState(DownloadItem item) {
    state = [
      for (final it in state)
        if (it.key == item.key) item else it,
    ];
  }

  /// Updates state and persists (used for status transitions).
  Future<void> _upsert(DownloadItem item) async {
    final exists = byKey(item.key) != null;
    state = exists
        ? [for (final it in state) if (it.key == item.key) item else it]
        : [item, ...state];
    await ref.read(downloadsRepositoryProvider).save(item);
  }
}

final downloadsProvider =
    NotifierProvider<DownloadsNotifier, List<DownloadItem>>(DownloadsNotifier.new);
