import 'package:flutter_test/flutter_test.dart';

import 'package:broken_iptv/presentation/common/poster_image.dart';

/// Panels put anything in the artwork field. Only an absolute http(s) URL is
/// worth handing to the image loader — everything else must reach the
/// fallback, not fail somewhere deeper and leave an empty box (which is how
/// this showed up: covers of titles this device had never rendered before).
void main() {
  test('accepts real artwork URLs', () {
    expect(PosterImage.usable('http://panel.example.com:8080/movie.jpg'), isTrue);
    expect(PosterImage.usable('https://images.example.com/a/b/c.png'), isTrue);
    // Spaces and accents survive: panels emit them and Uri parses them.
    expect(PosterImage.usable('http://x.example/Il Padrino.jpg'), isTrue);
  });

  test('rejects everything that is not a fetchable image URL', () {
    expect(PosterImage.usable(null), isFalse);
    expect(PosterImage.usable(''), isFalse);
    expect(PosterImage.usable('   '), isFalse);
    expect(PosterImage.usable('n/a'), isFalse);
    expect(PosterImage.usable('poster.jpg'), isFalse, reason: 'no host');
    expect(PosterImage.usable('/data/user/0/com.app/files/p.jpg'), isFalse,
        reason: 'a local path from another device means nothing here');
    expect(PosterImage.usable('C:\\Users\\x\\p.jpg'), isFalse);
    expect(PosterImage.usable('ftp://x.example/p.jpg'), isFalse);
  });

  test('surrounding whitespace does not make a good URL unusable', () {
    expect(PosterImage.usable('  https://x.example/p.jpg  '), isTrue);
  });
}
