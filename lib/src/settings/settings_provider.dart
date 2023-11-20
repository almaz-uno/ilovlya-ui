import 'package:flutter/material.dart';
import 'package:ilovlya/src/api/api.dart';
import 'package:ilovlya/src/model/settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'settings_provider.g.dart';

@riverpod
class SettingsNotifier extends _$SettingsNotifier {
  @override
  Future<Settings> build() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return Settings(
      theme: switch (prefs.getString("theme")) {
        "light" => ThemeMode.light,
        "dark" => ThemeMode.dark,
        _ => ThemeMode.system,
      },
      token: prefs.getString("token") ?? "",
      serverUrl: prefs.getString("server_url") ?? serverBaseURL,
      debugMode: prefs.getBool("debug_mode") ?? false,
      volume: prefs.getDouble("volume") ?? 50.0,
      sortBy: prefs.getString("sort_by") ?? "created_at",
    );
  }

  Future<void> save() async {
    if (!state.hasValue) return;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(
        "theme",
        switch (state.value?.theme) {
          ThemeMode.light => "light",
          ThemeMode.dark => "dark",
          _ => "system",
        });

    prefs.setString("token", state.value?.token ?? "");
    prefs.setString("server_url", state.value?.serverUrl ?? serverBaseURL);
    prefs.setBool("debug_mode", state.value?.debugMode ?? false);
    prefs.setDouble("volume", state.value?.volume ?? 50.0);
    prefs.setString("sort_by", state.value?.sortBy ?? "created_at");
  }

  void updateTheme(ThemeMode theme) {
    final old = state.value ?? Settings();
    state = AsyncData(old.copy(theme: theme));
    save();
  }

  void updateToken(String token) {
    final old = state.value ?? Settings();
    state = AsyncData(old.copy(token: token));
    save();
  }

  void updateServerUrl(String serverUrl) {
    final old = state.value ?? Settings();
    state = AsyncData(old.copy(serverUrl: serverUrl));
    save();
  }

  void updateDebugMode(bool? debugMode) {
    final old = state.value ?? Settings();
    state = AsyncData(old.copy(debugMode: debugMode));
    save();
  }

  void updateVolume(double volume) {
    final old = state.value ?? Settings();
    state = AsyncData(old.copy(volume: volume));
    save();
  }

  void updateSortBy(String sortBy) {
    final old = state.value ?? Settings();
    state = AsyncData(old.copy(sortBy: sortBy));
    save();
  }
}
