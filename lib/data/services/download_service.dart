import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import 'panel_http.dart';

/// Low-level file downloader: fetches a panel URL to a local file, reporting
/// progress and honouring cancellation. The queue/orchestration lives in the
/// DownloadsNotifier; this class only does one transfer at a time on request.
class DownloadService {
  /// `<app-support>/downloads`, created on first use.
  Future<Directory> downloadsDir() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}${Platform.pathSeparator}downloads');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Absolute path for a download, derived from its key + container extension.
  Future<String> filePathFor(String key, String ext) async {
    final dir = await downloadsDir();
    final safe = key.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    return '${dir.path}${Platform.pathSeparator}$safe.$ext';
  }

  /// Downloads [url] to [savePath]. Partial files are removed on error so a
  /// retry always starts clean. [receiveTimeout] here is the inactivity gap
  /// between chunks (dio 5), not a total cap — sized large for slow panels.
  Future<void> download({
    required String url,
    required String savePath,
    required CancelToken cancelToken,
    required void Function(int received, int total) onProgress,
  }) async {
    final dio = createPanelDio(receiveTimeout: const Duration(minutes: 10));
    await dio.download(
      url,
      savePath,
      cancelToken: cancelToken,
      deleteOnError: true,
      onReceiveProgress: onProgress,
    );
  }

  Future<void> deleteFile(String? path) async {
    if (path == null) return;
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {
      // Best-effort: a missing/locked file must not break removal from the UI.
    }
  }

  Future<bool> fileExists(String? path) async {
    if (path == null) return false;
    try {
      return File(path).exists();
    } catch (_) {
      return false;
    }
  }
}
