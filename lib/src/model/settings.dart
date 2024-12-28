import 'package:flutter/material.dart';
import 'package:ilovlya/src/api/api.dart';

class Settings {
  final ThemeMode theme;
  final String token; // an empty token means that user has no token yet
  final String serverUrl;
  final bool debugMode;
  final double volume;
  final String sortBy;
  final bool showHidden;
  final bool showSeen;
  final bool withServerFile;
  final bool withLocalFile;
  final double playerSpeed;
  final bool autoViewed;

  Settings({
    this.theme = ThemeMode.system,
    this.token = "",
    this.serverUrl = serverBaseURL,
    this.debugMode = false,
    this.volume = 50.0,
    this.sortBy = "created_at",
    this.showHidden = false,
    this.showSeen = false,
    this.withServerFile = false,
    this.withLocalFile = false,
    this.playerSpeed = 1.0,
    this.autoViewed = false,
  });

  Settings copyWith({
    ThemeMode? theme,
    String? token,
    String? serverUrl,
    bool? debugMode,
    double? volume,
    String? sortBy,
    bool? showHidden,
    bool? showSeen,
    bool? withServerFile,
    bool? withLocalFile,
    double? playerSpeed,
    bool? autoViewed,
  }) =>
      Settings(
        theme: theme ?? this.theme,
        token: token ?? this.token,
        serverUrl: serverUrl ?? this.serverUrl,
        debugMode: debugMode ?? this.debugMode,
        volume: volume ?? this.volume,
        sortBy: sortBy ?? this.sortBy,
        showHidden: showHidden ?? this.showHidden,
        showSeen: showSeen ?? this.showSeen,
        withServerFile: withServerFile ?? this.withServerFile,
        playerSpeed: playerSpeed ?? this.playerSpeed,
        autoViewed: autoViewed ?? this.autoViewed,
      );
}
