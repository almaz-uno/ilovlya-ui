import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

const _timeout = Duration(seconds: 1);

void getMpvPlaybackPosition(String socketPath, void Function(double? pos) callback) async {
  try {
    final socket = await Socket.connect(InternetAddress(socketPath, type: InternetAddressType.unix), 0, timeout: _timeout);
    // mpv IPC: {"command": ["get_property", "playback-time"]}
    debugPrint("Connected to mpv IPC socket at $socketPath");
    socket.write('{"command": ["get_property", "playback-time"]}\n');
    await socket.flush();

    socket.listen((data) {
      final json = jsonDecode(utf8.decode(data));
      callback(json['data'] is double ? json['data'] : null);
    }, onDone: () {
      debugPrint("onDone $socketPath closed");
    }, onError: (error) {
      debugPrint("onError: $error");
    });
    await socket.close();
    debugPrint("$socketPath closed");
  } catch (e) {
    debugPrint('mpv IPC error: $e');
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
    debugPrint("Connected to mpv IPC socket at $socketPath for seek to $position");
    socket.write('{"command": ["set_property", "playback-time", $position]}\n');
    await socket.flush();

    if (callback != null) {
      socket.listen((data) {
        final json = jsonDecode(utf8.decode(data));
        if (json['error'] == 'success') {
          callback();
        }
      }, onDone: () {
        debugPrint("onDone $socketPath closed after seek");
      }, onError: (error) {
        debugPrint("onError during seek: $error");
      });
    }
    await socket.close();
    debugPrint("$socketPath closed after seek");
  } catch (e) {
    debugPrint('mpv IPC seek error: $e');
  }
}
