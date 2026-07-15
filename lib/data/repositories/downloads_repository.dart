import '../models/download_item.dart';
import '../services/storage_service.dart';

/// Persists download metadata in the Hive `downloads` box. The media files
/// themselves live on the filesystem (see DownloadService).
class DownloadsRepository {
  List<DownloadItem> getAll() {
    return StorageService.downloadsBox.values
        .map(DownloadItem.fromMap)
        .toList(growable: false);
  }

  DownloadItem? get(String key) {
    final m = StorageService.downloadsBox.get(key);
    return m == null ? null : DownloadItem.fromMap(m);
  }

  Future<void> save(DownloadItem item) {
    return StorageService.downloadsBox.put(item.key, item.toMap());
  }

  Future<void> remove(String key) {
    return StorageService.downloadsBox.delete(key);
  }
}
