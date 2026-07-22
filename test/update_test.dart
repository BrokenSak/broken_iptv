import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:broken_iptv/data/services/update_service.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);

  ResponseBody Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

/// The version check is a plain build-number comparison; the artifact picked
/// depends on the platform. Both are pure (updateFromJson) and tested here.
void main() {
  Map<String, dynamic> json(int build) => {
        'build': build,
        'version': '9.9.9',
        'notes': 'nuove cose',
        'apk': 'https://x/BrokenIPTV.apk',
        'exe': 'https://x/BrokenIPTV.exe',
      };

  test('offers the update only when the published build is newer', () {
    expect(updateFromJson(json(5), 4), isNotNull);
    expect(updateFromJson(json(5), 5), isNull, reason: 'same build = no update');
    expect(updateFromJson(json(5), 6), isNull, reason: 'older remote = no update');
  });

  test('picks the APK on mobile and the EXE on Windows', () {
    expect(updateFromJson(json(5), 1, isWindows: false)!.downloadUrl, endsWith('.apk'));
    expect(updateFromJson(json(5), 1, isWindows: true)!.downloadUrl, endsWith('.exe'));
  });

  test('carries version and notes through', () {
    final info = updateFromJson(json(7), 1)!;
    expect(info.build, 7);
    expect(info.version, '9.9.9');
    expect(info.notes, 'nuove cose');
  });

  test('malformed json yields no update (never throws)', () {
    expect(updateFromJson(const {}, 1), isNull);
    expect(updateFromJson(const {'build': 'x'}, 1), isNull);
    // build present but the platform artifact URL missing.
    expect(updateFromJson(const {'build': 9}, 1, isWindows: false), isNull);
  });

  group('check() over the wire', () {
    const body = '{"build":9,"version":"9.9.9","notes":"n",'
        '"apk":"https://x/BrokenIPTV.apk","exe":"https://x/BrokenIPTV.exe"}';

    UpdateService serviceReturning(String payload, {String? contentType}) {
      final dio = Dio()
        ..httpClientAdapter = _FakeAdapter((_) => ResponseBody.fromString(
              payload,
              200,
              headers: contentType == null
                  ? null
                  : {Headers.contentTypeHeader: [contentType]},
            ));
      return UpdateService(dio: dio);
    }

    test('parses version.json served as text/plain', () async {
      // ⚠️ REGRESSION: this is exactly what raw.githubusercontent returns for
      // a .json file. dio does NOT auto-decode a non-JSON content type, so the
      // old code got a String, failed its `is Map` check and reported "no
      // update" forever — the 1.2.0 updater never fired once. The pure
      // updateFromJson tests above all passed while it was broken, which is
      // why this one has to go through check().
      final info = await serviceReturning(body, contentType: 'text/plain; charset=utf-8')
          .check(1);
      expect(info, isNotNull);
      expect(info!.build, 9);
    });

    test('parses it when served as application/json too', () async {
      final info = await serviceReturning(body, contentType: 'application/json').check(1);
      expect(info?.build, 9);
    });

    test('no update when the published build is not newer', () async {
      expect(await serviceReturning(body, contentType: 'text/plain').check(9), isNull);
    });

    test('garbage or an empty body never throws', () async {
      expect(await serviceReturning('<html>404</html>', contentType: 'text/html').check(1),
          isNull);
      expect(await serviceReturning('', contentType: 'text/plain').check(1), isNull);
      expect(await serviceReturning('[1,2,3]', contentType: 'text/plain').check(1), isNull);
    });
  });
}
