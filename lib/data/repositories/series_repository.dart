import '../models/series_item.dart';
import '../models/xtream_category.dart';
import '../services/content_source.dart';

class SeriesRepository {
  SeriesRepository(this._source);

  final ContentSource _source;

  Future<List<XtreamCategory>> getCategories() => _source.getSeriesCategories();

  Future<List<SeriesItem>> getItems(String categoryId) =>
      _source.getSeries(categoryId: categoryId);

  Future<List<SeriesItem>> getAllItems() => _source.getSeries();

  Future<SeriesDetail> getDetail(String seriesId) => _source.getSeriesInfo(seriesId);

  String episodeUrl(String episodeId, String containerExtension) =>
      _source.seriesEpisodeUrl(episodeId, containerExtension);
}
