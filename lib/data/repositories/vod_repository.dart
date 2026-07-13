import '../models/vod_item.dart';
import '../models/xtream_category.dart';
import '../services/content_source.dart';

class VodRepository {
  VodRepository(this._source);

  final ContentSource _source;

  Future<List<XtreamCategory>> getCategories() => _source.getVodCategories();

  Future<List<VodItem>> getItems(String categoryId) =>
      _source.getVodStreams(categoryId: categoryId);

  Future<List<VodItem>> getAllItems() => _source.getVodStreams();

  Future<VodDetail> getDetail(String vodId) => _source.getVodInfo(vodId);

  String streamUrl(String streamId, String containerExtension) =>
      _source.vodStreamUrl(streamId, containerExtension);
}
