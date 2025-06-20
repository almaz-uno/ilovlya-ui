import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../alert_dialog.dart';
import '../api/api.dart';
import '../api/api_riverpod.dart';
import '../api/directories_riverpod.dart';
import '../api/housekeeper_riverpod.dart';
import '../media/format.dart';
import 'settings_provider.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({
    super.key,
  });

  static String routeName = "/$pathSettings";

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  bool _cleaningStaleMedia = false;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsNotifierProvider);

    final tokenController = TextEditingController(text: settings.requireValue.token);
    final serverUrlController = TextEditingController(text: settings.requireValue.serverUrl);
    final sp = ref.watch(storePlacesProvider);

    return DefaultTabController(
      length: 3,
      initialIndex: 2,
      child: Scaffold(
        appBar: AppBar(
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.person), text: "User profile"),
              Tab(icon: Icon(Icons.settings), text: "Settings"),
              Tab(icon: Icon(Icons.cleaning_services), text: "Housekeeping"),
            ],
          ),
          title: const Text('Settings'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: TabBarView(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8.0,
                children: <Widget>[
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
                    ] +
                    tenantInfo(ref),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8.0,
                children: _commonSettings(),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8.0,
                children: _housekeeping(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _commonSettings() {
    return [
      DropdownButtonFormField<ThemeMode>(
        decoration: const InputDecoration(labelText: "Application color theme"),
        value: ref.watch(settingsNotifierProvider.select((s) => s.value?.theme)),
        alignment: AlignmentDirectional.topStart,
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
      DropdownButtonFormField<double>(
        decoration: const InputDecoration(labelText: "Player speed rate"),
        value: ref.watch(settingsNotifierProvider.select((s) => s.value?.playerSpeed)),
        onChanged: (value) {
          ref.read(settingsNotifierProvider.notifier).updatePlayerSpeed(value ?? 1.0);
        },
        items: [
          for (final e in speedRates.entries) DropdownMenuItem(value: e.key, child: Text(e.value)),
        ],
      ),
      CheckboxListTile(
        title: const Text("Auto mark recording as viewed when fully played"),
        value: ref.watch(settingsNotifierProvider.select((s) => s.value?.autoViewed)),
        onChanged: (bool? autoViewed) {
          ref.read(settingsNotifierProvider.notifier).updateAutoViewed(autoViewed);
        },
        controlAffinity: ListTileControlAffinity.leading,
      ),
      CheckboxListTile(
        title: const Text("Update thumbnail according to video viewing progress"),
        value: ref.watch(settingsNotifierProvider.select((s) => s.value?.updateThumbnails)),
        onChanged: (bool? updateThumbnails) {
          ref.read(settingsNotifierProvider.notifier).updateUpdateThumbnails(updateThumbnails);
        },
        controlAffinity: ListTileControlAffinity.leading,
      ),
      CheckboxListTile(
        title: const Text("Show additional technical info. For advanced users only!"),
        value: ref.watch(settingsNotifierProvider.select((s) => s.value?.debugMode)),
        onChanged: (bool? debugMode) {
          ref.read(settingsNotifierProvider.notifier).updateDebugMode(debugMode);
        },
        controlAffinity: ListTileControlAffinity.leading,
      ),
    ];
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
      w.add(Text("Local: ${t.localUsageStr()}"));
      w.add(Text("Storage: ${t.storeUsageStr()}"));
    }
    return w;
  }

  List<Widget> _housekeeping(BuildContext context) {
    final ref = (context as WidgetRef);
    final media = ref.watch(localMediaHousekeeperProvider);
    final data = ref.watch(localDataNotifierProvider);
    final sp = ref.watch(storePlacesProvider);

    if (!media.hasValue || !data.hasValue || !sp.hasValue) {
      return [const CircularProgressIndicator()];
    }

    final (number, size) = media.requireValue;

    final mediaDirs = ref.watch(mediaDirsProvider);
    final current = ref.watch(settingsNotifierProvider.select((s) => s.value?.mediaStorageDirectory));

    return [
      Text("Local media info", style: Theme.of(context).textTheme.bodyLarge),
      Text("Recordings: ${data.requireValue}"),
      Text("Files: $number, total size: ${fileSizeHumanReadable(size)}"),
      OutlinedButton(
        child: const Text("Clean stale downloaded media"),
        onPressed: () async {
          if (_cleaningStaleMedia) return;
          try {
            setState(() {
              _cleaningStaleMedia = true;
            });
            final (number, size) = await ref.read(localMediaHousekeeperProvider.notifier).cleanStale();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('$number files, ${fileSizeHumanReadable(size)} cleaned'),
            ));
          } finally {
            setState(() {
              _cleaningStaleMedia = false;
            });
          }
        },
      ),
      OutlinedButton(
        child: const Text("Clean ALL downloaded media"),
        onPressed: () async {
          confirmDialog(context, "Are you sure?", "This will delete ALL downloaded media files", () async {
            final (number, size) = await ref.read(localMediaHousekeeperProvider.notifier).cleanAll();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('$number files, ${fileSizeHumanReadable(size)} cleaned'),
            ));
            Navigator.pop(context);
          });
        },
      ),
      OutlinedButton(
        child: Text("Clean ALL metadata for ${data.requireValue} recordings"),
        onPressed: () async {
          confirmDialog(
              context, "Are you sure?", "This will delete ALL metadata for ${data.requireValue} recordings,\ndownloaded media files will be retained.\nThis data can be downloaded from the server.",
              () async {
            final number = await ref.read(localDataNotifierProvider.notifier).cleanMetadata();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('$number recordings cleaned'),
            ));
            Navigator.pop(context);
          });
        },
      ),
      if (mediaDirs.hasValue)
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: "Media directory"),
          value: ref.watch(settingsNotifierProvider.select((s) => s.value?.mediaStorageDirectory)),
          alignment: AlignmentDirectional.topStart,
          onChanged: (String? directory) {
            ref.read(settingsNotifierProvider.notifier).updateMediaStorageDirectory(directory ?? "");
          },
          items: [for (final d in mediaDirs.requireValue) DropdownMenuItem(value: d, child: Text(d))],
        ),
      if (sp.hasValue) Text("Data local path: ${sp.requireValue.data().path}"),
      if (sp.hasValue) Text("Downloaded local media path: ${sp.requireValue.media().path}"),
      if (_cleaningStaleMedia)
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Wrap(spacing: 8.0, crossAxisAlignment: WrapCrossAlignment.center, children: [
            CircularProgressIndicator(),
            Text("cleaning stale media local files..."),
          ]),
        ),
    ];
  }
}
