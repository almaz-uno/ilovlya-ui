import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:ilovlya/src/api/api_riverpod.dart';
import 'package:ilovlya/src/api/media_list_riverpod.dart';
import 'package:ilovlya/src/localization/app_localizations.dart';
import 'package:ilovlya/src/media/media_add.dart';
import 'package:ilovlya/src/model/recording_info.dart';
import 'package:ilovlya/src/model/url_info.dart';
import 'package:ilovlya/src/utils/provider_retry.dart';

const _url = 'https://example.test/video';

class _TestMediaListNotifier extends MediaListNotifier {
  @override
  Future<List<RecordingInfo>> build() async => [];

  @override
  Future<void> refreshFromServer() async {}
}

const _thumbnail = 'https://example.test/thumbnail.png';

RecordingInfo _info(String id) => RecordingInfo(id: id, title: 'Video $id', webpageUrl: '$_url/$id', thumbnailDataUrl: _thumbnail);

/// The add screen over a home page, its server answered by [urlInfo] and
/// [addRecording], the clipboard holding [_url].
Widget _app({required bool forcePaste, required Future<URLInfo> urlInfo, required Map<String, Future<RecordingInfo>> addRecording}) {
  final overrides = <Override>[
    mediaListProvider.overrideWith(_TestMediaListNotifier.new),
    getUrlInfoProvider(_url).overrideWith((ref) => urlInfo),
    for (final e in addRecording.entries) addRecordingProvider(e.key).overrideWith((ref) => e.value),
  ];
  return ProviderScope(
    retry: disableProviderRetry,
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => MediaAddView(forcePaste: forcePaste))),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
}

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

/// Frames enough for the clipboard, the lookup and the add to answer; not
/// pumpAndSettle, which a running progress indicator never lets settle.
Future<void> _frames(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized().defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.getData') return <String, dynamic>{'text': _url};
      return null;
    });
  });

  tearDown(() {
    TestWidgetsFlutterBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('a pasted link with one video shows one progress indicator while it is added, and none once it failed', (tester) async {
    final added = Completer<RecordingInfo>();
    await tester.pumpWidget(
      _app(
        forcePaste: true,
        urlInfo: Future.value(URLInfo(url: _url, infos: [_info('one')])),
        addRecording: {'$_url/one': added.future},
      ),
    );
    await tester.tap(find.text('open'));
    await _frames(tester);

    expect(find.text('Adding url $_url/one...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    added.completeError(Exception('server said no'));
    await _frames(tester);

    expect(find.textContaining('server said no'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('a lookup shows one progress indicator until the server answers', (tester) async {
    final info = Completer<URLInfo>();
    await tester.pumpWidget(_app(forcePaste: false, urlInfo: info.future, addRecording: const {}));
    await _open(tester);

    await tester.enterText(find.byType(TextField), _url);
    await tester.tap(find.byIcon(Icons.youtube_searched_for));
    await tester.pump();

    expect(find.text('Media info acquiring in progress...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    info.complete(URLInfo(url: _url));
    await tester.pumpAndSettle();

    expect(find.text('There is no recordings in the url'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('a video added from the list shows one progress indicator while it is added, and the list stays', (tester) async {
    // The list loads each thumbnail, which the test's HTTP client answers 400;
    // the thumbnails are not what this test is about.
    final onError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.library != 'image resource service') onError?.call(details);
    };
    try {
      await _addFromList(tester);
    } finally {
      FlutterError.onError = onError;
    }
  });
}

Future<void> _addFromList(WidgetTester tester) async {
  final added = Completer<RecordingInfo>();
  await tester.pumpWidget(
    _app(
      forcePaste: true,
      urlInfo: Future.value(URLInfo(url: _url, infos: [_info('one'), _info('two')])),
      addRecording: {'$_url/two': added.future},
    ),
  );
  await tester.tap(find.text('open'));
  await _frames(tester);

  expect(find.byType(ListTile), findsNWidgets(2));
  expect(find.byType(CircularProgressIndicator), findsNothing);

  await tester.tap(find.textContaining('Video two'));
  await _frames(tester);
  expect(find.byType(CircularProgressIndicator), findsOneWidget);

  added.complete(_info('two'));
  await _frames(tester);
  expect(find.text('Video two successfully added'), findsOneWidget);
  expect(find.byType(CircularProgressIndicator), findsNothing);
  expect(find.byType(ListTile), findsNWidgets(2));
}
