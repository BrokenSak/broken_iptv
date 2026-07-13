import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/channel.dart';
import '../data/models/series_item.dart';
import '../data/models/vod_item.dart';
import 'live_providers.dart';
import 'series_providers.dart';
import 'vod_providers.dart';

class SearchResults {
  const SearchResults({required this.channels, required this.movies, required this.series});

  static const empty = SearchResults(channels: [], movies: [], series: []);

  final List<Channel> channels;
  final List<VodItem> movies;
  final List<SeriesItem> series;

  bool get isEmpty => channels.isEmpty && movies.isEmpty && series.isEmpty;
}

final searchProvider = FutureProvider.family<SearchResults, String>((ref, query) async {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return SearchResults.empty;

  final liveRepo = await ref.watch(liveRepositoryProvider.future);
  final vodRepo = await ref.watch(vodRepositoryProvider.future);
  final seriesRepo = await ref.watch(seriesRepositoryProvider.future);

  final channels = liveRepo != null ? await liveRepo.getAllChannels() : const <Channel>[];
  final movies = vodRepo != null ? await vodRepo.getAllItems() : const <VodItem>[];
  final series = seriesRepo != null ? await seriesRepo.getAllItems() : const <SeriesItem>[];

  return SearchResults(
    channels: channels.where((c) => c.name.toLowerCase().contains(q)).toList(),
    movies: movies.where((m) => m.name.toLowerCase().contains(q)).toList(),
    series: series.where((s) => s.name.toLowerCase().contains(q)).toList(),
  );
});
