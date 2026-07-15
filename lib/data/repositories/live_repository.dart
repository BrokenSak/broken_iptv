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

  /// EPG entries for a channel, with the fake "EPG NON DISPONIBILE"-style
  /// placeholders some panels emit filtered out: downstream UI (channel tile,
  /// player top bar, full guide) treats an empty list as "no EPG" and shows
  /// nothing, which is the correct rendering for those channels.
  Future<List<EpgProgram>> getShortEpg(String streamId, {int limit = 20}) async {
    final programs = await _source.getShortEpg(streamId, limit: limit);
    return programs.where((p) => !p.isPlaceholder).toList();
  }

  String streamUrl(String streamId) => _source.liveStreamUrl(streamId);

  String timeshiftUrl(String streamId, DateTime start, Duration duration) =>
      _source.timeshiftUrl(streamId, start, duration);
}
