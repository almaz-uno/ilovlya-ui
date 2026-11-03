import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../settings/settings_provider.dart';

part 'server_access_riverpod.g.dart';

/// How the server takes the token of the settings: what the periodic refresh of the list asks before it polls.
class ServerAccess {
  /// The token of the settings; `null` while they load.
  final String? token;

  /// The server answered 401 to this token. Cleared by another token, or by a request it answers with this one.
  final bool rejected;

  const ServerAccess({required this.token, this.rejected = false});

  /// There is no token to send: the settings have loaded, and it is empty.
  bool get noToken => token != null && token!.isEmpty;

  /// The client may poll the server: it has a token, and the server has not refused it.
  bool get canPoll => token != null && token!.isNotEmpty && !rejected;
}

/// Whether the server accepts the token of the settings, as the requests that poll it have found (#211). A new token
/// starts afresh, not rejected: the user has changed it to be tried.
@Riverpod(keepAlive: true)
class ServerAccessNotifier extends _$ServerAccessNotifier {
  @override
  ServerAccess build() => ServerAccess(token: ref.watch(settingsProvider.select((s) => s.value?.token)));

  /// The server has answered a request sent with [token] with [statusCode]: 401 rejects the token, an answer below
  /// 400 accepts it. A token other than the current one, sent before it changed, says nothing about the current one.
  void answered(String token, int statusCode) {
    if (token != state.token) return;
    if (statusCode == 401 && !state.rejected) {
      state = ServerAccess(token: token, rejected: true);
    } else if (statusCode < 400 && state.rejected) {
      state = ServerAccess(token: token);
    }
  }
}
