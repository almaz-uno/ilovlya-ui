import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ilovlya/src/api/api.dart';
import 'package:ilovlya/src/settings/settings_provider.dart';

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
    final serverUrlController =
        TextEditingController(text: settings.requireValue.serverUrl);

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
                ref
                    .read(settingsNotifierProvider.notifier)
                    .updateTheme(theme ?? ThemeMode.system);
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
              decoration: const InputDecoration(
                  labelText: "Your token, provided by the bot"),
              textInputAction: TextInputAction.next,
              onSubmitted: (String value) {
                ref.read(settingsNotifierProvider.notifier).updateToken(value);
              },
            ),
            TextField(
              controller: serverUrlController,
              decoration: const InputDecoration(
                  labelText: "Server URL, provided by the bot"),
              textInputAction: TextInputAction.next,
              onSubmitted: (String value) {
                ref
                    .read(settingsNotifierProvider.notifier)
                    .updateServerUrl(value);
              },
            ),
            CheckboxListTile(
              title: const Text("Show additional technical info. For advanced users only!"),
              value: settings.value?.debugMode,
              onChanged: (bool? debugMode) {
                ref
                    .read(settingsNotifierProvider.notifier)
                    .updateDebugMode(debugMode);
              },
              controlAffinity: ListTileControlAffinity.leading,
            )
          ],
        ),
      ),
    );
  }
}
