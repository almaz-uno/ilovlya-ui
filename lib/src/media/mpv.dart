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
