import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_platform/universal_platform.dart';

import '../api/api.dart';
import '../model/settings.dart';

part 'settings_provider.g.dart';

Map<double, String> speedRates = {
  0.5: "0.5x slow",
  1.0: "1.0x normal",
  1.25: "1.25x medium",
  1.5: "1.5x fast",
  1.75: "1.75x very fast",
  2.0: "2.0x super fast",
};

Future<String> _dataDir(String srcDir) async {
  if (srcDir == "") {
    final documents = await getApplicationDocumentsDirectory();
    if (UniversalPlatform.isDesktop) {
      srcDir = p.join(documents.path, appName, "data");
    } else {
      srcDir = p.join(documents.path, "data");
    }
  }

  try {
    Directory(srcDir).createSync(recursive: true);
  } catch (e, s) {
    debugPrintStack(stackTrace: s, label: e.toString());
    return _dataDir("");
  }

  return srcDir;
}

Future<String> _mediaDir(String srcDir) async {
  if (srcDir == "") {
    final documents = await getApplicationDocumentsDirectory();
    if (UniversalPlatform.isDesktop) {
      srcDir = p.join(documents.path, appName, "media");
    } else {
      srcDir = p.join(documents.path, "media");
    }
  }
  try {
    Directory(srcDir).createSync(recursive: true);
  } catch (e, s) {
    debugPrintStack(stackTrace: s, label: e.toString());
    return _mediaDir("");
  }
  return srcDir;
}

@riverpod
Future<List<String>> mediaDirs(Ref ref) async {
  final dirs = <String>[await _mediaDir("")];

  try {
    final esDirs = await getExternalStorageDirectories(type: StorageDirectory.movies);
    if (esDirs != null) {
      for (final d in esDirs) {
        dirs.add(d.path);
      }
    }
  } catch (e) {
    // debugPrintStack(stackTrace: s, label: e.toString());
  }

  return dirs;
}

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
      withServerFile: prefs.getBool("with_server_file") ?? false,
      withLocalFile: prefs.getBool("with_local_file") ?? false,
      playerSpeed: prefs.getDouble("player_speed") ?? 1.0,
      autoViewed: prefs.getBool("auto_viewed") ?? false,
      updateThumbnails: prefs.getBool("update_thumbnails") ?? false,
      dataStorageDirectory: await _dataDir(prefs.getString("data_storage_directory") ?? ""),
      mediaStorageDirectory: await _mediaDir(prefs.getString("media_storage_directory") ?? ""),
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
    prefs.setBool("with_server_file", state.value?.withServerFile ?? false);
    prefs.setBool("with_local_file", state.value?.withLocalFile ?? false);
    prefs.setDouble("player_speed", state.value?.playerSpeed ?? 1.0);
    prefs.setBool("auto_viewed", state.value?.autoViewed ?? false);
    prefs.setBool("update_thumbnails", state.value?.updateThumbnails ?? false);
    prefs.setString("data_storage_directory", state.value?.dataStorageDirectory ?? "");
    prefs.setString("media_storage_directory", state.value?.mediaStorageDirectory ?? "");
  }

  void updateTheme(ThemeMode theme) {
    state = AsyncData(state.requireValue.copyWith(theme: theme));
    save();
  }

  void updateToken(String token) {
    state = AsyncData(state.requireValue.copyWith(token: token));
    save();
  }

  void updateServerUrl(String serverUrl) {
    state = AsyncData(state.requireValue.copyWith(serverUrl: serverUrl));
    save();
  }

  void updateDebugMode(bool? debugMode) {
    state = AsyncData(state.requireValue.copyWith(debugMode: debugMode));
    save();
  }

  void updateVolume(double volume) {
    state = AsyncData(state.requireValue.copyWith(volume: volume));
    save();
  }

  void updateSortBy(String sortBy) {
    state = AsyncData(state.requireValue.copyWith(sortBy: sortBy));
    save();
  }

  void toggleShowHidden() {
    state = AsyncData(state.requireValue.copyWith(showHidden: !state.requireValue.showHidden));
    save();
  }

  void toggleShowSeen() {
    state = AsyncData(state.requireValue.copyWith(showSeen: !state.requireValue.showSeen));
    save();
  }

  void toggleWithServerFile() {
    state = AsyncData(state.requireValue.copyWith(withServerFile: !state.requireValue.withServerFile));
    save();
  }

  void toggleWithLocalFile() {
    state = AsyncData(state.requireValue.copyWith(withLocalFile: !state.requireValue.withLocalFile));
    save();
  }

  void updatePlayerSpeed(double playerSpeed) {
    state = AsyncData(state.requireValue.copyWith(playerSpeed: playerSpeed));
    save();
  }

  void updateAutoViewed(bool? autoViewed) {
    state = AsyncData(state.requireValue.copyWith(autoViewed: autoViewed));
    save();
  }

  void updateUpdateThumbnails(bool? updateThumbnails) {
    state = AsyncData(state.requireValue.copyWith(updateThumbnails: updateThumbnails));
    save();
  }

  void updateDataStorageDirectory(String? dataStorageDirectory) {
    state = AsyncData(state.requireValue.copyWith(dataStorageDirectory: dataStorageDirectory));
    save();
  }

  void updateMediaStorageDirectory(String? mediaStorageDirectory) {
    state = AsyncData(state.requireValue.copyWith(mediaStorageDirectory: mediaStorageDirectory));
    save();
  }
}
