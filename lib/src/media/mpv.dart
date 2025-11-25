import 'dart:convert';
import 'dart:io';
import '../utils/logger_provider.dart';

const _timeout = Duration(seconds: 1);

void getMpvPlaybackPosition(String socketPath, void Function(double? pos) callback) async {
  try {
    final socket = await Socket.connect(InternetAddress(socketPath, type: InternetAddressType.unix), 0, timeout: _timeout);
    // mpv IPC: {"command": ["get_property", "playback-time"]}
    AppLoggers.player.d('Connected to mpv IPC socket: $socketPath');
    socket.write('{"command": ["get_property", "playback-time"]}\n');
    await socket.flush();

    socket.listen((data) {
      final json = jsonDecode(utf8.decode(data));
      callback(json['data'] is double ? json['data'] : null);
    }, onDone: () {
      AppLoggers.player.d('MPV socket closed: $socketPath');
    }, onError: (error) {
      AppLoggers.player.e('MPV socket error', error: error);
    });
    await socket.close();
    AppLoggers.player.d('MPV socket connection closed: $socketPath');
  } catch (e) {
    AppLoggers.player.e('MPV IPC error', error: e);
  }
}

/// Sets the playback position in mpv player
/// [socketPath] - path to mpv IPC socket
/// [position] - position in seconds to seek to
/// [callback] - optional callback function called when seek is complete
void setMpvPlaybackPosition(String socketPath, double position, [void Function()? callback]) async {
  try {
    final socket = await Socket.connect(InternetAddress(socketPath, type: InternetAddressType.unix), 0, timeout: _timeout);
    // mpv IPC: {"command": ["set_property", "playback-time", position]}
    AppLoggers.player.d('Connected to mpv IPC socket for seek: path=$socketPath, position=$position');
    socket.write('{"command": ["set_property", "playback-time", $position]}\n');
    await socket.flush();

    if (callback != null) {
      socket.listen((data) {
        final json = jsonDecode(utf8.decode(data));
        if (json['error'] == 'success') {
          callback();
        }
      }, onDone: () {
        AppLoggers.player.d('MPV socket closed after seek: $socketPath');
      }, onError: (error) {
        AppLoggers.player.e('MPV error during seek', error: error);
      });
    }
    await socket.close();
    AppLoggers.player.d('MPV socket connection closed after seek: $socketPath');
  } catch (e) {
    AppLoggers.player.e('MPV IPC seek error', error: e);
  }
}
