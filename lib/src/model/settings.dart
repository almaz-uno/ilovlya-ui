import 'package:flutter/material.dart';
import 'package:ilovlya/src/api/api.dart';

class Settings {
  final ThemeMode theme;
  final String token; // an empty token means that user has no token yet
  final String serverUrl;
  final bool debugMode;
  final double volume;
  final String sortBy;

  Settings({
    this.theme = ThemeMode.system,
    this.token = "",
    this.serverUrl = serverBaseURL,
    this.debugMode = false,
    this.volume = 50.0,
    this.sortBy = "created_at",
  });

  Settings copy({
    ThemeMode? theme,
    String? token,
    String? serverUrl,
    bool? debugMode,
    double? volume,
    String? sortBy,
  }) =>
      Settings(
        theme: theme ?? this.theme,
        token: token ?? this.token,
        serverUrl: serverUrl ?? this.serverUrl,
        debugMode: debugMode ?? this.debugMode,
        volume: volume ?? this.volume,
        sortBy: sortBy ?? this.sortBy,
      );
}
