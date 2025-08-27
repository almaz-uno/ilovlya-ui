import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:ilovlya/src/localization/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ilovlya/src/settings/settings_provider.dart';

import 'api/api.dart';
import 'media/media_add.dart';
import 'media/media_details.dart';
import 'media/media_list.dart';
import 'settings/settings_view.dart';
import 'theme/warm_theme.dart';

/// Parse locale string to Locale object
/// Returns null for empty string (system locale)
Locale? _parseLocale(String? localeString) {
  if (localeString == null || localeString.isEmpty) {
    return null; // Use system locale
  }

  final parts = localeString.split('_');
  if (parts.length == 2) {
    return Locale(parts[0], parts[1]);
  } else if (parts.length == 1) {
    return Locale(parts[0]);
  }

  return null; // Fallback to system locale for invalid format
}

/// The Widget that configures your application.
class MyApp extends ConsumerWidget {
  const MyApp({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsNotifierProvider);

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Theme.of(context).colorScheme.surface,
    ));

    return MaterialApp(
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.mouse,
          PointerDeviceKind.touch,
          PointerDeviceKind.stylus,
          PointerDeviceKind.unknown,
        },
      ),
      // Providing a restorationScopeId allows the Navigator built by the
      // MaterialApp to restore the navigation stack when a user leaves and
      // returns to the app after it has been killed while running in the
      // background.
      restorationScopeId: 'app',
      debugShowCheckedModeBanner: false,

      // Provide the generated AppLocalizations to the MaterialApp. This
      // allows descendant Widgets to display the correct translations
      // depending on the user's locale.
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), // English, no country code
        Locale('ru', ''), // Russian, no country code
      ],

      // Use locale from settings, fallback to system locale
      locale: _parseLocale(settings.value?.locale),

      // Use AppLocalizations to configure the correct application title
      // depending on the user's locale.
      //
      // The appTitle is defined in .arb files found in the localization
      // directory.
      onGenerateTitle: (BuildContext context) {
        return "${AppLocalizations.of(context)!.appTitle} • ${Uri.base.host}";
      },

      theme: WarmTheme.lightTheme,
      darkTheme: WarmTheme.darkTheme,

      themeMode: settings.value?.theme,

      // Define a function to handle named routes in order to support
      // Flutter web url navigation and deep linking.
      onGenerateRoute: (RouteSettings routeSettings) {
        var w = widgetByRoute(routeSettings);
        if (w == null) return null;
        return MaterialPageRoute<void>(
          settings: routeSettings,
          builder: (BuildContext context) {
            return w;
          },
        );
      },
      onUnknownRoute: (RouteSettings routeSettings) {
        return MaterialPageRoute<void>(
          settings: const RouteSettings(
            name: "/",
            arguments: null,
          ),
          builder: (BuildContext context) {
            return const MediaListViewRiverpod();
          },
        );
      },
    );
  }

  Widget? widgetByRoute(RouteSettings routeSettings) {
    if (routeSettings.name == null) return null;

    var uri = Uri.parse(routeSettings.name!);
    if (uri.pathSegments.isEmpty) return null;

    if (uri.pathSegments[0] == pathRecordings) {
      if (uri.queryParameters.containsKey("add")) {
        return MediaAddView(forcePaste: uri.queryParameters.containsKey("paste"));
      } else if (uri.pathSegments.length < 2) {
        return const MediaListViewRiverpod();
      } else {
        return MediaDetailsView(id: uri.pathSegments[1]);
      }
    } else if (uri.pathSegments[0] == pathSettings) {
      return const SettingsView();
    } else {
      return null;
    }
  }
}
