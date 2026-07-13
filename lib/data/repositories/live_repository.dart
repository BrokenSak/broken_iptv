import '../models/channel.dart';
import '../models/epg_program.dart';
import '../models/xtream_category.dart';
import '../services/content_source.dart';

class LiveRepository {
  LiveRepository(this._source);

  final ContentSource _source;

  Future<List<XtreamCategory>> getCategories() => _source.getLiveCategories();

  Future<List<Channel>> getChannels(String categoryId) =>
      _source.getLiveStreams(categoryId: categoryId);

  Future<List<Channel>> getAllChannels() => _source.getLiveStreams();

  Future<List<EpgProgram>> getShortEpg(String streamId, {int limit = 20}) =>
      _source.getShortEpg(streamId, limit: limit);

  String streamUrl(String streamId) => _source.liveStreamUrl(streamId);

  String timeshiftUrl(String streamId, DateTime start, Duration duration) =>
      _source.timeshiftUrl(streamId, start, duration);
}
