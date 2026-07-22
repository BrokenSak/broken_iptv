import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// A poster/cover coming from the panel, with one fallback for every way it
/// can fail to be a picture.
///
/// The catalog grids already showed a placeholder when a cover failed, but the
/// "continua a guardare" tiles fed the URL straight to the image loader: a
/// cover that didn't load left an empty box. It showed up most on entries that
/// arrived by sync, simply because those are titles this device never rendered
/// before — nothing to do with syncing itself.
class PosterImage extends StatelessWidget {
  const PosterImage({
    super.key,
    required this.url,
    required this.fallback,
    this.fit = BoxFit.cover,
  });

  final String? url;

  /// Shown while loading, when [url] is unusable, and when the load fails.
  final Widget fallback;

  final BoxFit fit;

  /// Panels put all sorts of things in the artwork field: empty strings, bare
  /// file names, occasionally a sentence. Only an absolute http(s) URL is worth
  /// handing to the loader — the rest goes straight to the fallback instead of
  /// failing somewhere deeper.
  static bool usable(String? url) {
    final trimmed = url?.trim() ?? '';
    if (trimmed.isEmpty) return false;
    final uri = Uri.tryParse(trimmed);
    if (uri == null || uri.host.isEmpty) return false;
    return uri.scheme == 'http' || uri.scheme == 'https';
  }

  @override
  Widget build(BuildContext context) {
    if (!usable(url)) return fallback;
    return CachedNetworkImage(
      imageUrl: url!.trim(),
      fit: fit,
      placeholder: (_, _) => fallback,
      errorWidget: (_, _, _) => fallback,
    );
  }
}
