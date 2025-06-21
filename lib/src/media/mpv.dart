import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

//const mpvSocketPath = '/tmp/mpvsocket';

void getMpvPlaybackPosition(String socketPath, void Function(double? pos) callback) async {
  try {
    final socket = await Socket.connect(InternetAddress(socketPath, type: InternetAddressType.unix), 0);
    // mpv IPC: {"command": ["get_property", "playback-time"]}
    socket.write('{"command": ["get_property", "playback-time"]}\n');
    await socket.flush();

    socket.listen((data) {
      final json = jsonDecode(utf8.decode(data));
      callback(json['data'] is double ? json['data'] : null);
    });
    await socket.close();
  } catch (e) {
    debugPrint('mpv IPC error: $e');
  }
}
