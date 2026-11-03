import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ilovlya/src/api/directories_riverpod.dart';
import 'package:ilovlya/src/api/local_download_task_riverpod.dart';
import 'package:ilovlya/src/localization/app_localizations.dart';
import 'package:ilovlya/src/media/media_list.dart';
import 'package:ilovlya/src/model/local_download.dart';
import 'package:ilovlya/src/model/settings.dart';
import 'package:ilovlya/src/settings/settings_provider.dart';
import 'package:ilovlya/src/utils/provider_retry.dart';

/// The token the server accepts; any other is answered 401.
const _good = 'good';

/// The server URL of the settings unless a test sets another.
const _server = 'https://server.test';

const _unauthorized = 'Unauthorized: please check and specify token and server URL in settings';

class _LocalDT extends LocalDTNotifier {
  @override
  Map<String, LocalDownloadTask> build() => {};
}

class _Settings extends SettingsNotifier {
  _Settings(this.token, this.serverUrl);
  String token;
  String serverUrl;

  @override
  Future<Settings> build() async => Settings(token: token, serverUrl: serverUrl);

  void setToken(String token) => state = AsyncData(Settings(token: this.token = token, serverUrl: serverUrl));

  void setServerUrl(String serverUrl) => state = AsyncData(Settings(token: token, serverUrl: this.serverUrl = serverUrl));
}

/// The server the list polls: the requests it got, with the time since the list was shown, and what it answers.
class _Server {
  final requests = <(Duration, String, String)>[];
  Duration now = Duration.zero;
  String accepted = _good;

  /// The host whose token is [accepted]; any other host answers 401 to every token. `null`: every host accepts it.
  String? acceptingHost;

  /// While set, the answers of [heldHost] wait for it.
  Completer<void>? hold;
  String? heldHost;

  late final client = MockClient((req) async {
    requests.add((now, req.url.host, req.url.path));
    if (hold != null && req.url.host == heldHost) await hold!.future;
    final host = acceptingHost;
    if (req.headers['Authorization'] != accepted || (host != null && req.url.host != host)) {
      return http.Response('{"message":"code=401, message=auth token is invalid"}', 401);
    }
    return switch (req.url.path) {
      '/api/recordings' => http.Response('[]', 200),
      '/api/tenant' => http.Response('{"id":"t","telegram_id":1}', 200),
      _ => http.Response('', 404),
    };
  });

  /// When [path] was asked for, of [host] if given, in whole seconds since the list was shown.
  List<int> of(String path, {String? host}) =>
      [for (final (at, h, p) in requests) if (p == path && (host == null || h == host)) (at.inMilliseconds + 500) ~/ 1000];
}

void main() {
  late Directory dir;
  late _Server server;
  late _Settings settings;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('media_list_polling');
    server = _Server();
    mediaListPlayerPlaying = () => false;
  });
  tearDown(() => dir.deleteSync(recursive: true));

  /// Lets [seconds] of fake time pass, in steps of 100 ms.
  Future<void> pass(WidgetTester tester, int seconds) async {
    for (var i = 0; i < seconds * 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      server.now += const Duration(milliseconds: 100);
    }
  }

  /// Shows the list with [token], then lets [seconds] of fake time pass, all requests going to [server].
  Future<void> show(WidgetTester tester, String token, int seconds, {String serverUrl = _server}) async {
    settings = _Settings(token, serverUrl);
    await tester.pumpWidget(ProviderScope(
      retry: disableProviderRetry,
      overrides: [
        settingsProvider.overrideWith(() => settings),
        localDTProvider.overrideWith(_LocalDT.new),
        storePlacesProvider.overrideWith((ref) async => StorePlaces(dataDir: '${dir.path}/data', mediaDir: '${dir.path}/media')),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const MediaListViewRiverpod(),
      ),
    ));
    await pass(tester, seconds);
  }

  Future<void> run(WidgetTester tester, Future<void> Function() body) => http.runWithClient(body, () => server.client);

  testWidgets('with no token the server is not polled, and a refresh the user asks for still goes out', (tester) async {
    await run(tester, () async {
      await show(tester, '', 150);
      expect(server.requests, isEmpty, reason: 'five refresh intervals with no token');
      expect(find.text(_unauthorized), findsOneWidget);

      await tester.tap(find.byTooltip('Refresh list'));
      await pass(tester, 1);
      expect(server.of('/api/recordings'), hasLength(1));
      await pass(tester, 90);
      expect(server.requests, hasLength(1), reason: 'the refresh asked for does not start polling with no token');
    });
  });

  testWidgets('after a 401 the periodic refresh stops until the token changes, and the user is told', (tester) async {
    await run(tester, () async {
      await show(tester, 'refused', 150);
      expect(server.of('/api/recordings'), [0], reason: 'only the pull as the list is shown');
      expect(server.of('/api/tenant'), anyOf(isEmpty, [0]), reason: 'asked for at most as the list is shown: the 401 of the list may come first');
      expect(find.text(_unauthorized), findsOneWidget);

      server.requests.clear();
      final changed = server.now;
      settings.setToken(_good);
      await pass(tester, 65);
      expect(server.requests.first.$1 - changed, lessThan(const Duration(seconds: 1)), reason: 'a new token is tried at once');
      expect(server.of('/api/recordings'), hasLength(greaterThanOrEqualTo(3)), reason: 'and polled again: at once, then every 30 s');
      expect(find.text(_unauthorized), findsNothing);
    });
  });

  testWidgets('after a 401 a refresh the user asks for goes out, and polling resumes once the token is accepted', (tester) async {
    await run(tester, () async {
      server.accepted = 'not yet';
      await show(tester, _good, 60);
      expect(server.of('/api/recordings'), hasLength(1));

      server.accepted = _good; // the token was registered on the server meanwhile
      await tester.tap(find.byTooltip('Refresh list'));
      await pass(tester, 65);
      expect(server.of('/api/recordings'), hasLength(greaterThanOrEqualTo(4)), reason: 'the refresh asked for, then polling again');
      expect(find.text(_unauthorized), findsNothing);
    });
  });

  testWidgets('with a token the server accepts the list and the tenant are pulled every 30 s, as before', (tester) async {
    await run(tester, () async {
      await show(tester, _good, 151);
      final pulls = [for (var s = 0; s <= 150; s += 30) s];
      expect(server.of('/api/recordings'), pulls);
      expect(server.of('/api/tenant'), pulls);
    });
  });

  testWidgets('after a 401 a new server URL with the same token is tried at once, and polled', (tester) async {
    await run(tester, () async {
      server.acceptingHost = 'right.test';
      await show(tester, _good, 60, serverUrl: 'https://wrong.test');
      expect(server.of('/api/recordings', host: 'wrong.test'), [0], reason: 'refused: no more polling of the wrong server');
      expect(find.text(_unauthorized), findsOneWidget);

      final changed = server.now;
      settings.setServerUrl('https://right.test');
      await pass(tester, 65);
      final right = server.of('/api/recordings', host: 'right.test');
      expect(right.first - changed.inSeconds, lessThanOrEqualTo(1), reason: 'the new server is tried at once');
      expect(right, hasLength(greaterThanOrEqualTo(3)), reason: 'and polled: at once, then every 30 s');
      expect(server.of('/api/recordings', host: 'wrong.test'), [0]);
      expect(find.text(_unauthorized), findsNothing);
    });
  });

  testWidgets('a 401 to a request sent to the former server URL says nothing about the new one', (tester) async {
    await run(tester, () async {
      server
        ..acceptingHost = 'right.test'
        ..hold = Completer<void>()
        ..heldHost = 'wrong.test';
      await show(tester, _good, 1, serverUrl: 'https://wrong.test');
      expect(server.of('/api/recordings', host: 'wrong.test'), [0], reason: 'sent, its answer held');

      settings.setServerUrl('https://right.test');
      await pass(tester, 1);
      server.hold!.complete(); // the former server refuses the token now, after the change
      await pass(tester, 65);
      expect(server.of('/api/recordings', host: 'right.test'), hasLength(greaterThanOrEqualTo(3)), reason: 'polling goes on');
      expect(find.text(_unauthorized), findsNothing);
    });
  });
}
