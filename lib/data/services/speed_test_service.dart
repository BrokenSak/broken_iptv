import 'dart:async';

import 'package:dio/dio.dart';

class SpeedTestResult {
  const SpeedTestResult({required this.mbps, required this.verdict, required this.detail});

  final double mbps;
  final String verdict;
  final String detail;
}

/// Measures download throughput using Netflix's **fast.com** infrastructure.
///
/// IPTV panels reject direct stream GETs (HTTP 458 / connection-limited), so we
/// measure against fast.com's CDN instead — what matters for smooth playback is
/// the user's actual bandwidth. Everything runs in-app over HTTPS (so it also
/// works on Android, where cleartext is blocked) and never opens a browser.
class SpeedTestService {
  SpeedTestService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              headers: const {'User-Agent': 'Mozilla/5.0 (BrokenIPTV SpeedTest)'},
            ));

  final Dio _dio;

  /// fast.com's public API token. Normally scraped from the site's JS bundle;
  /// this long-stable value is the fallback when scraping fails.
  static const _fallbackToken = 'YXNkZmFzZGxmbnNkYWZoYXNkZmhrYWxm';

  Future<SpeedTestResult> run() async {
    final token = await _resolveToken();
    final targets = await _targets(token);
    if (targets.isEmpty) {
      throw Exception('Nessun server di test disponibile.');
    }
    final mbps = await _measure(targets);
    if (mbps <= 0) {
      throw Exception('Misurazione non riuscita.');
    }
    return _rate(mbps);
  }

  /// Scrapes the current API token from fast.com's JS bundle, falling back to
  /// the well-known static token if anything goes wrong.
  Future<String> _resolveToken() async {
    try {
      final page = await _dio.get<String>(
        'https://fast.com/',
        options: Options(responseType: ResponseType.plain),
      );
      final script = RegExp(r'app-[a-z0-9]+\.js').firstMatch(page.data ?? '');
      if (script != null) {
        final js = await _dio.get<String>(
          'https://fast.com/${script.group(0)}',
          options: Options(responseType: ResponseType.plain),
        );
        final token = RegExp(r'token:"([^"]+)"').firstMatch(js.data ?? '');
        if (token != null) return token.group(1)!;
      }
    } catch (_) {
      // Ignore and use the fallback token.
    }
    return _fallbackToken;
  }

  /// Asks the fast.com API for a set of CDN download targets.
  Future<List<String>> _targets(String token, {int urlCount = 5}) async {
    final resp = await _dio.get(
      'https://api.fast.com/netflix/speedtest/v2',
      queryParameters: {'https': 'true', 'token': token, 'urlCount': '$urlCount'},
    );
    final data = resp.data;
    if (data is! Map) return const [];
    final targets = data['targets'];
    if (targets is! List) return const [];
    return targets
        .whereType<Map>()
        .map((t) => t['url']?.toString())
        .whereType<String>()
        .toList();
  }

  /// Downloads from all targets in parallel for a short sampling window and
  /// returns the aggregate throughput in Mbps. Short payloads are re-requested
  /// so the pipe never sits idle before the window closes.
  Future<double> _measure(List<String> urls) async {
    const window = Duration(seconds: 8);
    const byteCap = 150 * 1024 * 1024;

    var totalBytes = 0;
    final sw = Stopwatch();
    final subs = <StreamSubscription<dynamic>>[];
    final done = Completer<void>();
    var finished = false;

    void finish() {
      if (finished) return;
      finished = true;
      if (!done.isCompleted) done.complete();
    }

    void onData(int len) {
      if (!sw.isRunning) sw.start();
      totalBytes += len;
      if (sw.elapsed >= window || totalBytes >= byteCap) finish();
    }

    for (final url in urls) {
      unawaited(() async {
        while (!finished) {
          try {
            final resp = await _dio.get<ResponseBody>(
              url,
              options: Options(
                responseType: ResponseType.stream,
                receiveTimeout: const Duration(seconds: 8),
              ),
            );
            if (finished) break;
            final sub = resp.data!.stream.listen(
              (chunk) => onData(chunk.length),
              onError: (_) {},
              cancelOnError: true,
            );
            subs.add(sub);
            await sub.asFuture<void>().catchError((_) {});
            subs.remove(sub);
          } catch (_) {
            if (finished) break;
            await Future<void>.delayed(const Duration(milliseconds: 150));
          }
        }
      }());
    }

    // Hard guard so a fully stalled connection can't hang the test.
    final guard = Timer(const Duration(seconds: 12), finish);
    await done.future;
    guard.cancel();
    sw.stop();
    for (final s in subs) {
      unawaited(s.cancel());
    }

    final seconds = sw.elapsedMilliseconds / 1000.0;
    if (seconds <= 0 || totalBytes <= 0) return 0;
    return (totalBytes * 8) / seconds / 1e6;
  }

  SpeedTestResult _rate(double mbps) {
    String verdict;
    String detail;
    if (mbps >= 25) {
      verdict = 'Ottimo';
      detail = 'Puoi guardare 4K senza problemi.';
    } else if (mbps >= 12) {
      verdict = 'Buono';
      detail = 'Full HD fluido; 4K possibile.';
    } else if (mbps >= 6) {
      verdict = 'Sufficiente';
      detail = 'Adatto a HD.';
    } else if (mbps >= 3) {
      verdict = 'Scarso';
      detail = 'Solo SD; possibili buffering in HD.';
    } else {
      verdict = 'Insufficiente';
      detail = 'Buffering probabile anche in SD.';
    }
    return SpeedTestResult(mbps: mbps, verdict: verdict, detail: detail);
  }
}
