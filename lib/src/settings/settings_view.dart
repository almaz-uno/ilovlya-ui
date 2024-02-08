import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ilovlya/src/api/persistent_riverpod.dart';

import '../api/api.dart';
import '../api/api_riverpod.dart';
import 'settings_provider.dart';

/// Displays the various settings that can be customized by the user.
///
/// Color theme, server URL, token and other settings.
class SettingsView extends ConsumerWidget {
  const SettingsView({
    super.key,
  });

  static String routeName = "/$pathSettings";

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsNotifierProvider);

    final tokenController = TextEditingController(text: settings.requireValue.token);
    final serverUrlController = TextEditingController(text: settings.requireValue.serverUrl);
    final recordingsDir = ref.watch(recordingsDirProvider);
    final mediaDir = ref.watch(mediaDirProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        // Glue the SettingsController to the theme selection DropdownButton.
        //
        // When a user selects a theme from the dropdown list, the
        // SettingsController is updated, which rebuilds the MaterialApp.
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                  DropdownButton<ThemeMode>(
                    // Read the selected themeMode from the controller
                    value: settings.requireValue.theme,
                    // Call the updateThemeMode method any time the user selects a theme.
                    onChanged: (ThemeMode? theme) {
                      ref.read(settingsNotifierProvider.notifier).updateTheme(theme ?? ThemeMode.system);
                    },
                    items: const [
                      DropdownMenuItem(
                        value: ThemeMode.system,
                        child: Text('System Theme'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.light,
                        child: Text('Light Theme'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.dark,
                        child: Text('Dark Theme'),
                      )
                    ],
                  ),
                  TextField(
                    controller: tokenController,
                    decoration: const InputDecoration(labelText: "Your token, provided by the bot"),
                    textInputAction: TextInputAction.next,
                    onSubmitted: (String value) {
                      ref.read(settingsNotifierProvider.notifier).updateToken(value);
                    },
                  ),
                  TextField(
                    controller: serverUrlController,
                    decoration: const InputDecoration(labelText: "Server URL, provided by the bot"),
                    textInputAction: TextInputAction.next,
                    onSubmitted: (String value) {
                      ref.read(settingsNotifierProvider.notifier).updateServerUrl(value);
                    },
                  ),
                  CheckboxListTile(
                    title: const Text("Show additional technical info. For advanced users only!"),
                    value: settings.value?.debugMode,
                    onChanged: (bool? debugMode) {
                      ref.read(settingsNotifierProvider.notifier).updateDebugMode(debugMode);
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ] +
                tenantInfo(ref) +
                [
                  if (recordingsDir.hasValue) Text("Recordings local path: ${recordingsDir.requireValue.path}"),
                  if (mediaDir.hasValue) Text("Downloaded local media path: ${mediaDir.requireValue.path}"),
                ]),
      ),
    );
  }

  List<Widget> tenantInfo(WidgetRef ref) {
    final tenant = ref.watch(getTenantProvider);
    final w = <Widget>[];
    if (tenant.isLoading) w.add(const CircularProgressIndicator());
    if (tenant.hasError) w.add(Text("${tenant.error}"));
    if (tenant.hasValue) {
      final t = tenant.requireValue;
      w.add(Text("${t.firstName} ${t.lastName} (${t.username})"));
      if (t.blockedAt != null) {
        w.add(Text("Blocked at ${tenant.requireValue.blockedAt}"));
      }
      w.add(Text("Quota: ${t.quotaStr()}"));
      w.add(Text("Used: ${t.usageStr()}"));
      w.add(Text("Free: ${t.freeStr()}"));
      w.add(Text("Files: ${t.files}"));
    }
    return w;
  }
}

class _TenantInfoView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenant = ref.watch(getTenantProvider);

    return Column(
      children: [
        if (tenant.isLoading) const CircularProgressIndicator(),
        if (tenant.hasError) Text("${tenant.error}"),
        if (tenant.hasValue) Text("${tenant.requireValue.firstName} ${tenant.requireValue.lastName} (${tenant.requireValue.username})"),
        if (tenant.hasValue && tenant.requireValue.blockedAt != null) Text("Blocked at ${tenant.requireValue.blockedAt}")
      ],
    );
  }
}
