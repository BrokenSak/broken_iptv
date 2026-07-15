import 'dart:io';

import 'package:broken_iptv/data/services/catalog_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

void main() {
  late Directory tmp;
  late LazyBox<Map> box;
  late CatalogCache cache;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('catalog_cache_test');
    Hive.init(tmp.path);
    box = await Hive.openLazyBox<Map>('catalog_cache');
    cache = CatalogCache(box);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await tmp.delete(recursive: true);
  });

  test('put → fresh returns the body', () async {
    await cache.put('host|user|get_live_categories|', '[{"category_id":"1"}]');
    expect(await cache.fresh('host|user|get_live_categories|'),
        '[{"category_id":"1"}]');
  });

  test('expired entry is not fresh but still served by anyAge', () async {
    const key = 'host|user|get_live_categories|';
    await box.put(key, {
      'ts': DateTime.now()
          .subtract(const Duration(hours: 25))
          .millisecondsSinceEpoch,
      'body': '[]',
    });
    expect(await cache.fresh(key), isNull);
    expect(await cache.anyAge(key), '[]');
  });

  test('clearPrefix removes only that profile', () async {
    await cache.put('hostA|user|get_live_categories|', '[1]');
    await cache.put('hostA|user|get_vod_categories|', '[2]');
    await cache.put('hostB|user|get_live_categories|', '[3]');

    await cache.clearPrefix('hostA|user|');

    expect(await cache.anyAge('hostA|user|get_live_categories|'), isNull);
    expect(await cache.anyAge('hostA|user|get_vod_categories|'), isNull);
    expect(await cache.anyAge('hostB|user|get_live_categories|'), '[3]');
  });

  test('non-ASCII and overlong keys are stored safely', () async {
    final longKey = 'host|user|get_live_streams|category_id=${'x' * 400}';
    await cache.put(longKey, '[42]');
    expect(await cache.fresh(longKey), '[42]');

    await cache.put('hòst|ùser|azione|', '[7]');
    expect(await cache.fresh('hòst|ùser|azione|'), '[7]');
  });
}
