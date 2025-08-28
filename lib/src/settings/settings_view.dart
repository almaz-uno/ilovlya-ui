import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../alert_dialog.dart';
import '../api/api.dart';
import '../api/api_riverpod.dart';
import '../api/directories_riverpod.dart';
import '../api/housekeeper_riverpod.dart';
import '../localization/app_localizations.dart';
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
          bottom: TabBar(
            tabs: [
              Tab(icon: const Icon(Icons.person), text: AppLocalizations.of(context)!.userProfile),
              Tab(icon: const Icon(Icons.settings), text: AppLocalizations.of(context)!.settings),
              Tab(icon: const Icon(Icons.cleaning_services), text: AppLocalizations.of(context)!.housekeeping),
            ],
          ),
          title: Text(AppLocalizations.of(context)!.settings),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: TabBarView(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8.0,
                children: <Widget>[
                      const SizedBox(height:0),
                      TextField(
                        controller: tokenController,
                        decoration: InputDecoration(labelText: AppLocalizations.of(context)!.yourTokenProvidedByBot),
                        textInputAction: TextInputAction.next,
                        onSubmitted: (String value) {
                          ref.read(settingsNotifierProvider.notifier).updateToken(value);
                        },
                      ),
                      TextField(
                        controller: serverUrlController,
                        decoration: InputDecoration(labelText: AppLocalizations.of(context)!.serverUrlProvidedByBot),
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
                children: [
                  const SizedBox(height: 0),
                  ..._commonSettings(),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8.0,
                children: [
                  const SizedBox(height: 0),
                  ..._housekeeping(context),
                ],
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
        decoration: InputDecoration(labelText: AppLocalizations.of(context)!.applicationColorTheme),
        initialValue: ref.watch(settingsNotifierProvider.select((s) => s.value?.theme)),
        alignment: AlignmentDirectional.topStart,
        onChanged: (ThemeMode? theme) {
          ref.read(settingsNotifierProvider.notifier).updateTheme(theme ?? ThemeMode.system);
        },
        items: [
          DropdownMenuItem(
            value: ThemeMode.system,
            child: Text(AppLocalizations.of(context)!.systemTheme),
          ),
          DropdownMenuItem(
            value: ThemeMode.light,
            child: Text(AppLocalizations.of(context)!.lightTheme),
          ),
          DropdownMenuItem(
            value: ThemeMode.dark,
            child: Text(AppLocalizations.of(context)!.darkTheme),
          )
        ],
      ),
      DropdownButtonFormField<String>(
        decoration: InputDecoration(labelText: AppLocalizations.of(context)!.language),
        initialValue: ref.watch(settingsNotifierProvider.select((s) => s.value?.locale)),
        alignment: AlignmentDirectional.topStart,
        onChanged: (String? locale) {
          ref.read(settingsNotifierProvider.notifier).updateLocale(locale ?? "");
        },
        items: [
          DropdownMenuItem<String>(
            value: "",
            child: Text(AppLocalizations.of(context)!.systemLanguage),
          ),
          const DropdownMenuItem<String>(
            value: "en",
            child: Text('English'),
          ),
          const DropdownMenuItem<String>(
            value: "ru",
            child: Text('Русский'),
          ),
        ],
      ),
      DropdownButtonFormField<double>(
        decoration: InputDecoration(labelText: AppLocalizations.of(context)!.playerSpeedRate),
        initialValue: ref.watch(settingsNotifierProvider.select((s) => s.value?.playerSpeed)),
        onChanged: (value) {
          ref.read(settingsNotifierProvider.notifier).updatePlayerSpeed(value ?? 1.0);
        },
        items: [
          for (final e in getSpeedRates(AppLocalizations.of(context)!).entries)
            DropdownMenuItem(value: e.key, child: Text(e.value)),
        ],
      ),
      CheckboxListTile(
        title: Text(AppLocalizations.of(context)!.autoMarkViewedWhenPlayed),
        value: ref.watch(settingsNotifierProvider.select((s) => s.value?.autoViewed)),
        onChanged: (bool? autoViewed) {
          ref.read(settingsNotifierProvider.notifier).updateAutoViewed(autoViewed);
        },
        controlAffinity: ListTileControlAffinity.leading,
      ),
      CheckboxListTile(
        title: Text(AppLocalizations.of(context)!.updateThumbnailProgress),
        value: ref.watch(settingsNotifierProvider.select((s) => s.value?.updateThumbnails)),
        onChanged: (bool? updateThumbnails) {
          ref.read(settingsNotifierProvider.notifier).updateUpdateThumbnails(updateThumbnails);
        },
        controlAffinity: ListTileControlAffinity.leading,
      ),
      CheckboxListTile(
        title: Text(AppLocalizations.of(context)!.showTechnicalInfo),
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
        w.add(Text(AppLocalizations.of(context)!.blockedAt("${tenant.requireValue.blockedAt}")));
      }
      w.add(Text(AppLocalizations.of(context)!.quota(t.quotaStr())));
      w.add(Text(AppLocalizations.of(context)!.used(t.usageStr())));
      w.add(Text(AppLocalizations.of(context)!.free(t.freeStr())));
      w.add(Text(AppLocalizations.of(context)!.files("${t.files}")));
      w.add(Text(AppLocalizations.of(context)!.local(t.localUsageStr())));
      w.add(Text(AppLocalizations.of(context)!.storage(t.storeUsageStr())));
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

    return [
      Text(AppLocalizations.of(context)!.localMediaInfo, style: Theme.of(context).textTheme.bodyLarge),
      Text(AppLocalizations.of(context)!.recordings("${data.requireValue}")),
      Text(AppLocalizations.of(context)!.filesWithSize("$number", fileSizeHumanReadable(size))),
      OutlinedButton(
        child: Text(AppLocalizations.of(context)!.cleanStaleDownloadedMedia),
        onPressed: () async {
          if (_cleaningStaleMedia) return;
          try {
            setState(() {
              _cleaningStaleMedia = true;
            });
            final (number, size) = await ref.read(localMediaHousekeeperProvider.notifier).cleanStale();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(AppLocalizations.of(context)!.filesCleanedMessage(number, fileSizeHumanReadable(size))),
            ));
          } finally {
            setState(() {
              _cleaningStaleMedia = false;
            });
          }
        },
      ),
      OutlinedButton(
        child: Text(AppLocalizations.of(context)!.cleanAllDownloadedMedia),
        onPressed: () async {
          confirmDialog(context, AppLocalizations.of(context)!.areYouSure, AppLocalizations.of(context)!.deleteAllDownloadedMediaFiles, () async {
            final (number, size) = await ref.read(localMediaHousekeeperProvider.notifier).cleanAll();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(AppLocalizations.of(context)!.filesCleanedMessage(number, fileSizeHumanReadable(size))),
            ));
            Navigator.pop(context);
          });
        },
      ),
      OutlinedButton(
        child: Text(AppLocalizations.of(context)!.cleanAllMetadataForRecordings("${data.requireValue}")),
        onPressed: () async {
          confirmDialog(
              context, AppLocalizations.of(context)!.areYouSure, AppLocalizations.of(context)!.deleteAllMetadataMessage(data.requireValue),
              () async {
            final number = await ref.read(localDataNotifierProvider.notifier).cleanMetadata();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(AppLocalizations.of(context)!.recordingsCleanedMessage(number)),
            ));
            Navigator.pop(context);
          });
        },
      ),
      if (mediaDirs.hasValue)
        DropdownButtonFormField<String>(
          decoration: InputDecoration(labelText: AppLocalizations.of(context)!.mediaDirectory),
          initialValue: ref.watch(settingsNotifierProvider.select((s) => s.value?.mediaStorageDirectory)),
          alignment: AlignmentDirectional.topStart,
          onChanged: (String? directory) {
            ref.read(settingsNotifierProvider.notifier).updateMediaStorageDirectory(directory ?? "");
          },
          items: [for (final d in mediaDirs.requireValue) DropdownMenuItem(value: d, child: Text(d))],
        ),
      if (sp.hasValue) Text(AppLocalizations.of(context)!.dataLocalPath(sp.requireValue.data().path)),
      if (sp.hasValue) Text(AppLocalizations.of(context)!.downloadedLocalMediaPath(sp.requireValue.media().path)),
      if (_cleaningStaleMedia)
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Wrap(spacing: 8.0, crossAxisAlignment: WrapCrossAlignment.center, children: [
            const CircularProgressIndicator(),
            Text(AppLocalizations.of(context)!.cleaningStaleMediaLocalFiles),
          ]),
        ),
    ];
  }
}
