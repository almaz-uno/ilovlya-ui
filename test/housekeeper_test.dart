import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ilovlya/src/api/directories_riverpod.dart';
import 'package:ilovlya/src/api/housekeeper_riverpod.dart';
import 'package:path/path.dart' as p;

import 'helpers/provider_container.dart';

void main() {
  late Directory root;
  late ProviderContainer c;

  String media(String name) => p.join(root.path, 'media', name);

  void recording(String id, {DateTime? seenAt}) {
    File(p.join(root.path, 'data', 'recordings', id)).writeAsStringSync(jsonEncode({
      'id': id,
      if (seenAt != null) 'seen_at': seenAt.toUtc().toIso8601String(),
    }));
  }

  void file(String name, int length) => File(media(name)).writeAsBytesSync(List.filled(length, 0));

  setUp(() async {
    root = Directory.systemTemp.createTempSync('housekeeper_test');
    c = createTestProviderContainer(overrides: [
      storePlacesProvider.overrideWith((ref) async => StorePlaces(dataDir: p.join(root.path, 'data'), mediaDir: p.join(root.path, 'media'))),
    ]);
    Directory(p.join(root.path, 'media')).createSync(recursive: true);
    await c.read(storePlacesProvider.future);

    recording('seen', seenAt: DateTime(2026, 1, 1));
    recording('unseen');
    file('seen-video.mp4', 100);
    file('unseen-video.mp4', 200);
    // Its recording JSON is gone, for example after the metadata was cleaned.
    file('orphan-video.mp4', 400);
    // The housekeeper is auto-disposed; keep it alive for the whole test.
    c.listen(localMediaHousekeeperProvider, (_, _) {});
  });

  tearDown(() {
    c.dispose();
    root.deleteSync(recursive: true);
  });

  test('a file without a recording does not stop the stale cleanup', () async {
    expect(await c.read(localMediaHousekeeperProvider.future), (3, 700));

    final cleaned = await c.read(localMediaHousekeeperProvider.notifier).cleanStale();

    expect(cleaned, (1, 100));
    expect(File(media('seen-video.mp4')).existsSync(), isFalse);
    expect(File(media('unseen-video.mp4')).existsSync(), isTrue);
    expect(File(media('orphan-video.mp4')).existsSync(), isTrue);
    expect(c.read(localMediaHousekeeperProvider).value, (2, 600));
  });

  test('a failed cleanup reports the failure and still re-evaluates the counters', () async {
    expect(await c.read(localMediaHousekeeperProvider.future), (3, 700));
    // Not counted yet: only a re-evaluation sees it.
    file('unseen-extra.mp4', 1);
    // A read-only media directory makes deleting the seen file fail.
    final dir = p.join(root.path, 'media');
    Process.runSync('chmod', ['a-w', dir]);
    addTearDown(() => Process.runSync('chmod', ['u+w', dir]));

    await expectLater(c.read(localMediaHousekeeperProvider.notifier).cleanStale(), throwsA(isA<FileSystemException>()));

    expect(File(media('seen-video.mp4')).existsSync(), isTrue);
    expect(c.read(localMediaHousekeeperProvider).value, (4, 701));
  }, skip: Process.runSync('id', ['-u']).stdout.toString().trim() == '0' ? 'root ignores directory permissions' : null);
}
