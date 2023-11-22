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
      showHidden: prefs.getBool("show_hidden") ?? false,
      showSeen: prefs.getBool("show_seen") ?? false,
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
    prefs.setBool("show_hidden", state.value?.showHidden ?? false);
    prefs.setBool("show_seen", state.value?.showSeen ?? false);
  }

  void updateTheme(ThemeMode theme) {
    state = AsyncData(state.requireValue.copy(theme: theme));
    save();
  }

  void updateToken(String token) {
    state = AsyncData(state.requireValue.copy(token: token));
    save();
  }

  void updateServerUrl(String serverUrl) {
    state = AsyncData(state.requireValue.copy(serverUrl: serverUrl));
    save();
  }

  void updateDebugMode(bool? debugMode) {
    state = AsyncData(state.requireValue.copy(debugMode: debugMode));
    save();
  }

  void updateVolume(double volume) {
    state = AsyncData(state.requireValue.copy(volume: volume));
    save();
  }

  void updateSortBy(String sortBy) {
    state = AsyncData(state.requireValue.copy(sortBy: sortBy));
    save();
  }

  void toggleShowHidden() {
    state = AsyncData(
        state.requireValue.copy(showHidden: !state.requireValue.showHidden));
    save();
  }

  void toggleShowSeen() {
    state = AsyncData(
        state.requireValue.copy(showSeen: !state.requireValue.showSeen));
    save();
  }
}
