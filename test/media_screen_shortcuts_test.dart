import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ilovlya/src/api/api.dart';
import 'package:ilovlya/src/api/api_riverpod.dart';
import 'package:ilovlya/src/api/downloads_riverpod.dart';
import 'package:ilovlya/src/api/local_download_task_riverpod.dart';
import 'package:ilovlya/src/api/media_list_riverpod.dart';
import 'package:ilovlya/src/api/recording_riverpod.dart';
import 'package:ilovlya/src/api/thumbnail_riverpod.dart';
import 'package:ilovlya/src/localization/app_localizations.dart';
import 'package:ilovlya/src/keyboard_shortcuts.dart';
import 'package:ilovlya/src/media/media_add.dart';
import 'package:ilovlya/src/media/media_details.dart';
import 'package:ilovlya/src/media/media_list.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:ilovlya/src/media/media_kit/recording_play.dart';
import 'package:ilovlya/src/model/local_download.dart';
import 'package:ilovlya/src/model/download.dart';
import 'package:ilovlya/src/model/recording_info.dart';
import 'package:ilovlya/src/model/settings.dart';
import 'package:ilovlya/src/model/tenant.dart';
import 'package:ilovlya/src/settings/settings_provider.dart';
import 'package:ilovlya/src/settings/settings_view.dart';
import 'package:ilovlya/src/utils/provider_retry.dart';

class _TestMediaListNotifier extends MediaListNotifier {
  _TestMediaListNotifier(this.recordings);
  final List<RecordingInfo> recordings;

  @override
  Future<List<RecordingInfo>> build() async {
    final phrase = ref.watch(searchPhraseProvider).toLowerCase();
    return phrase.isEmpty ? recordings : recordings.where((recording) => recording.title.toLowerCase().contains(phrase)).toList();
  }

  @override
  Future<void> refreshFromServer() async {}
}

class _TestSettingsNotifier extends SettingsNotifier {
  @override
  Future<Settings> build() async => Settings();
}

class _TestLocalDTNotifier extends LocalDTNotifier {
  @override
  Map<String, LocalDownloadTask> build() => {};
}

class _TestThumbnailNotifier extends ThumbnailDataNotifier {
  @override
  Future<Uint8List> build(String thumbnailUrl) async => Uint8List.fromList(_png);
}

class _TestRecordingNotifier extends RecordingNotifier {
  _TestRecordingNotifier(this.recording, {this.onRefresh});
  final RecordingInfo recording;
  final Future<void> Function()? onRefresh;

  @override
  Future<RecordingInfo> build(String recordingId) async => recording;

  @override
  Future<void> refreshFromServer() async {
    await onRefresh?.call();
  }
}

class _TestDownloadsNotifier extends DownloadsNotifier {
  _TestDownloadsNotifier(this.downloads);
  final List<Download> downloads;
  final deleted = <String>[];

  @override
  Future<List<Download>> build(String recordingId) async => downloads;

  @override
  Future<void> refreshFromServer() async {}

  @override
  Future<void> clean(String downloadId) async {
    deleted.add(downloadId);
  }
}

const _png = <int>[
  0x89,
  0x50,
  0x4e,
  0x47,
  0x0d,
  0x0a,
  0x1a,
  0x0a,
  0x00,
  0x00,
  0x00,
  0x0d,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1f,
  0x15,
  0xc4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0b,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9c,
  0x63,
  0x60,
  0x00,
  0x02,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0xa5,
  0xf6,
  0x45,
  0x40,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4e,
  0x44,
  0xae,
  0x42,
  0x60,
  0x82,
];

final _recordings = [
  RecordingInfo(id: 'one', title: 'Jazz recording', thumbnailUrl: 'thumb:first', createdAt: DateTime.utc(2026)),
  RecordingInfo(id: 'two', title: 'Second recording', thumbnailUrl: 'thumb:second', createdAt: DateTime.utc(2025)),
];

List<Override> _overrides({Future<RecordingInfo> Function(String url)? addRecording}) => [
      mediaListProvider.overrideWith(() => _TestMediaListNotifier(_recordings)),
      settingsProvider.overrideWith(_TestSettingsNotifier.new),
      localDTProvider.overrideWith(_TestLocalDTNotifier.new),
      getTenantProvider.overrideWith((ref) async => Tenant(id: 'test', telegramId: 1)),
      for (final recording in _recordings) thumbnailDataProvider(recording.thumbnailUrl).overrideWith(_TestThumbnailNotifier.new),
      if (addRecording != null) addRecordingProvider('https://example.test/video').overrideWith((ref) => addRecording('https://example.test/video')),
    ];

Route<dynamic> _route(RouteSettings settings) {
  final name = settings.name ?? '';
  if (name.startsWith('/$pathRecordings?add')) {
    final forcePaste = Uri.parse(name).queryParameters.containsKey('paste');
    return MaterialPageRoute<void>(settings: settings, builder: (_) => MediaAddView(forcePaste: forcePaste));
  }
  return MaterialPageRoute<void>(settings: settings, builder: (_) => Scaffold(body: Text('Route: $name')));
}

Widget _app({Future<RecordingInfo> Function(String url)? addRecording}) => ProviderScope(
      retry: disableProviderRetry,
      overrides: _overrides(addRecording: addRecording),
      child: MaterialApp(
        restorationScopeId: 'shortcuts-test',
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        onGenerateRoute: _route,
        home: const MediaListViewRiverpod(),
      ),
    );


List<Override> _detailsOverrides({
  required RecordingInfo recording,
  Future<void> Function()? setSeen,
  Future<void> Function()? onRefresh,
}) => [
      settingsProvider.overrideWith(_TestSettingsNotifier.new),
      localDTProvider.overrideWith(_TestLocalDTNotifier.new),
      recordingProvider(recording.id).overrideWith(() => _TestRecordingNotifier(recording, onRefresh: onRefresh)),
      downloadsProvider(recording.id).overrideWith(() => _TestDownloadsNotifier([])),
      thumbnailDataProvider(recording.thumbnailUrl).overrideWith(_TestThumbnailNotifier.new),
      if (setSeen != null) setSeenProvider(recording.id).overrideWith((ref) => setSeen()),
    ];

Widget _detailsApp(RecordingInfo recording) => MaterialApp(
        restorationScopeId: 'details-safety-test',
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => MediaDetailsView(id: recording.id))),
              child: const Text('Open recording'),
            ),
          ),
        ),
      );

Future<void> _pumpUi(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('real media list selects by id and opens the selected recording', (tester) async {
    await tester.pumpWidget(_app());
    await _pumpUi(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    final tiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();
    expect(tiles.first.selected, isTrue);
    expect(tiles.last.selected, isFalse);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(tester.widgetList<ListTile>(find.byType(ListTile)).last.selected, isTrue);
    await tester.tap(find.byTooltip('Refresh list'));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(find.textContaining('Route:'), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await _pumpUi(tester);
    expect(find.text('Route: /$pathRecordings/two'), findsOneWidget);
  });

  testWidgets('tab focus and arrow selection stay on the same recording', (tester) async {
    await tester.pumpWidget(_app());
    await _pumpUi(tester);

    ListTile? focusedTile;
    for (var i = 0; i < 20 && focusedTile == null; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final context = FocusManager.instance.primaryFocus?.context;
      focusedTile = context?.findAncestorWidgetOfExactType<ListTile>();
    }
    expect(focusedTile, isNotNull);
    expect(focusedTile!.selected, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'recording row two');
    expect(tester.widgetList<ListTile>(find.byType(ListTile)).last.selected, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await _pumpUi(tester);
    expect(find.text('Route: /$pathRecordings/two'), findsOneWidget);
  });

  testWidgets('real media list add, paste, and settings shortcuts navigate', (tester) async {
    await tester.pumpWidget(_app());
    await _pumpUi(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.equal, character: '+');
    await _pumpUi(tester);
    expect(find.byType(MediaAddView), findsOneWidget);
    expect(ModalRoute.of(tester.element(find.byType(MediaAddView)))?.isCurrent, isTrue);
    Navigator.of(tester.element(find.byType(MediaAddView))).pop();
    await _pumpUi(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.insert);
    await _pumpUi(tester);
    expect(find.byType(MediaAddView), findsOneWidget);
    expect(tester.widget<MediaAddView>(find.byType(MediaAddView)).forcePaste, isTrue);
    Navigator.of(tester.element(find.byType(MediaAddView))).pop();
    await _pumpUi(tester);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.comma);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await _pumpUi(tester);
    expect(find.text('Route: ${SettingsView.routeName}'), findsOneWidget);
  });

  testWidgets('plus shortcuts focus URL field and preserve question marks', (tester) async {
    await tester.pumpWidget(_app());
    await _pumpUi(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.equal, character: '+');
    await _pumpUi(tester);
    var field = find.byType(TextField);
    expect(field, findsOneWidget);
    expect(tester.widget<TextField>(field).focusNode!.hasFocus, isTrue);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.slash, character: '?');
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    expect(find.text('Keyboard shortcuts'), findsNothing);
    await tester.enterText(field, 'x?y');
    expect(tester.widget<TextField>(field).controller!.text, 'x?y');

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await _pumpUi(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.numpadAdd, physicalKey: PhysicalKeyboardKey.numpadAdd);
    await _pumpUi(tester);
    field = find.byType(TextField);
    expect(field, findsOneWidget);
    expect(isTextInputFocused(), isTrue);
  });

  testWidgets('search receives typed characters and Escape restores list shortcuts', (tester) async {
    await tester.pumpWidget(_app());
    await _pumpUi(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    await tester.tap(find.text('Search...'));
    await _pumpUi(tester);
    final field = find.byType(TextFormField);
    expect(field, findsOneWidget);
    await tester.enterText(field, 'j');
    await tester.pump();
    expect(tester.widget<TextFormField>(field).controller!.text, 'j');
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.slash, character: '?');
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    expect(find.text('Keyboard shortcuts'), findsNothing);
    await tester.enterText(field, 'j?');
    expect(tester.widget<TextFormField>(field).controller!.text, 'j?');
    await tester.enterText(field, 'j');
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('Jazz recording'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(isTextInputFocused(), isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(find.textContaining('Route:'), findsNothing);
    await tester.tap(find.byTooltip('Refresh list'));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(tester.widgetList<ListTile>(find.byType(ListTile)).first.selected, isTrue);
  });

  testWidgets('real media add ignores a second Enter while the first add is pending', (tester) async {
    final completion = Completer<RecordingInfo>();
    var requests = 0;
    await tester.pumpWidget(_app(addRecording: (_) {
      requests++;
      return completion.future;
    }));
    await _pumpUi(tester);
    await tester.tap(find.byTooltip('Add an arbitrary media'));
    await _pumpUi(tester);
    expect(find.byType(MediaAddView), findsOneWidget);
    final field = find.byType(TextField);
    expect(ModalRoute.of(tester.element(find.byType(MediaAddView)))?.isCurrent, isTrue);
    await tester.enterText(field, 'https://example.test/video');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(requests, 1);

    completion.complete(RecordingInfo(id: 'added', title: 'Added recording'));
    await _pumpUi(tester);
    expect(find.text('Added recording successfully added'), findsOneWidget);
    expect(ModalRoute.of(tester.element(find.byType(MediaAddView)))?.isCurrent, isFalse);
    expect(find.byType(MediaListViewRiverpod), findsOneWidget);
  });

  testWidgets('seen request completion after leaving recording does not use disposed ref', (tester) async {
    final request = Completer<void>();
    final recording = RecordingInfo(id: 'one', title: 'Jazz recording', thumbnailUrl: 'thumb:seen');
    await tester.pumpWidget(ProviderScope(
      retry: disableProviderRetry,
      overrides: _detailsOverrides(recording: recording, setSeen: () => request.future),
      child: _detailsApp(recording),
    ));
    await tester.tap(find.text('Open recording'));
    await _pumpUi(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await _pumpUi(tester);
    request.complete();
    await _pumpUi(tester);
    expect(find.text('Open recording'), findsOneWidget);
  });

  testWidgets('refreshes that complete after leaving recording do not use disposed ref', (tester) async {
    final pendingRefresh = Completer<void>();
    var refreshCalls = 0;
    final recording = RecordingInfo(id: 'one', title: 'Jazz recording', thumbnailUrl: 'thumb:periodic');
    await tester.pumpWidget(ProviderScope(
      retry: disableProviderRetry,
      overrides: _detailsOverrides(recording: recording, onRefresh: () async {
        refreshCalls++;
        await pendingRefresh.future;
      }),
      child: _detailsApp(recording),
    ));
    await tester.tap(find.text('Open recording'));
    await tester.pumpAndSettle();
    expect(find.byType(MediaDetailsView), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
    await tester.pump();
    expect(refreshCalls, greaterThan(0));

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    pendingRefresh.complete();
    await _pumpUi(tester);
    expect(find.text('Open recording'), findsOneWidget);
  });

  testWidgets('real recording screen Delete asks which local copy to remove', (tester) async {
    final recording = RecordingInfo(id: 'one', title: 'Jazz recording', thumbnailUrl: 'thumb:details');
    final downloads = <Download>[
      Download(id: 'local-a', recordingId: 'one', filename: 'copy-a.mp4', status: 'ready', updatedAt: DateTime.utc(2026))..fullPathMedia = '/tmp/copy-a.mp4',
      Download(id: 'local-b', recordingId: 'one', filename: 'copy-b.mp4', status: 'ready', updatedAt: DateTime.utc(2025))..fullPathMedia = '/tmp/copy-b.mp4',
    ];
    late _TestDownloadsNotifier notifier;
    await tester.pumpWidget(ProviderScope(
      retry: disableProviderRetry,
      overrides: [
        settingsProvider.overrideWith(_TestSettingsNotifier.new),
        localDTProvider.overrideWith(_TestLocalDTNotifier.new),
        recordingProvider('one').overrideWith(() => _TestRecordingNotifier(recording)),
        downloadsProvider('one').overrideWith(() => notifier = _TestDownloadsNotifier(downloads)),
        thumbnailDataProvider(recording.thumbnailUrl).overrideWith(_TestThumbnailNotifier.new),
      ],
      child: MaterialApp(
        restorationScopeId: 'details-shortcuts-test',
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        onGenerateRoute: _route,
        home: const MediaDetailsView(id: 'one'),
      ),
    ));
    await _pumpUi(tester);
    final detailsContext = tester.element(find.byType(MediaDetailsView));
    await ProviderScope.containerOf(detailsContext).read(downloadsProvider('one').future);
    expect(ProviderScope.containerOf(detailsContext).read(recordingProvider('one')).hasValue, isTrue);
    expect(ProviderScope.containerOf(detailsContext).read(downloadsProvider('one')).hasValue, isTrue);
    expect(isTextInputFocused(), isFalse);
    final screenFocus = Focus.of(tester.element(find.byType(Scaffold)));
    screenFocus.requestFocus();
    await tester.pump();
    expect(FocusManager.instance.primaryFocus, same(screenFocus));
    expect(isTextInputFocused(), isFalse);

    expect(isDesktopKeyboardPlatform, isTrue);
    expect(await tester.sendKeyEvent(LogicalKeyboardKey.delete), isTrue);
    await _pumpUi(tester);
    expect(find.text('copy-a.mp4'), findsOneWidget);
    expect(find.text('copy-b.mp4'), findsOneWidget);
    expect(notifier.deleted, isEmpty);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await _pumpUi(tester);
    expect(find.text('copy-a.mp4'), findsNothing);
    expect(notifier.deleted, isEmpty);
    expect(find.byType(RecordingViewMediaKitHandler), findsNothing);
  });
}
