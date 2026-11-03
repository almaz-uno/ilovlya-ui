import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../settings/settings_provider.dart';

part 'server_access_riverpod.g.dart';

/// How the server of the settings takes their token: what the periodic refresh of the list asks before it polls.
class ServerAccess {
  /// The server URL of the settings; `null` while they load.
  final String? serverUrl;

  /// The token of the settings; `null` while they load.
  final String? token;

  /// The server answered 401 to this token. Cleared by another token or server URL, or by a request this server
  /// answers with this token.
  final bool rejected;

  const ServerAccess({required this.serverUrl, required this.token, this.rejected = false});

  /// There is no token to send: the settings have loaded, and it is empty.
  bool get noToken => token != null && token!.isEmpty;

  /// The client may poll the server: it has a token, and the server has not refused it.
  bool get canPoll => token != null && token!.isNotEmpty && !rejected;
}

/// Whether the server of the settings accepts their token, as the requests that poll it have found (#211). A new token
/// or server URL starts afresh, not rejected: the user has changed it to be tried, and what another server answered
/// says nothing about this one.
@Riverpod(keepAlive: true)
class ServerAccessNotifier extends _$ServerAccessNotifier {
  @override
  ServerAccess build() {
    final (serverUrl, token) = ref.watch(settingsProvider.select((s) => (s.value?.serverUrl, s.value?.token)));
    return ServerAccess(serverUrl: serverUrl, token: token);
  }

  /// [serverUrl] has answered a request sent with [token] with [statusCode]: 401 rejects the token, an answer below
  /// 400 accepts it. A request sent before the server URL or the token changed says nothing about the current pair.
  void answered(String serverUrl, String token, int statusCode) {
    if (serverUrl != state.serverUrl || token != state.token) return;
    if (statusCode == 401 && !state.rejected) {
      state = ServerAccess(serverUrl: serverUrl, token: token, rejected: true);
    } else if (statusCode < 400 && state.rejected) {
      state = ServerAccess(serverUrl: serverUrl, token: token);
    }
  }
}
