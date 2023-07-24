import 'dart:ui';

import 'package:ilovlya/src/media/media_add_view.dart';
import 'package:ilovlya/src/media/media_details_view.dart';
import 'package:ilovlya/src/media/media_list_view.dart';
import 'package:ilovlya/src/api/api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'settings/settings_controller.dart';
import 'settings/settings_view.dart';

/// The Widget that configures your application.
class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.settingsController,
  });

  final SettingsController settingsController;

  @override
  Widget build(BuildContext context) {
    // Glue the SettingsController to the MaterialApp.
    //
    // The AnimatedBuilder Widget listens to the SettingsController for changes.
    // Whenever the user updates their settings, the MaterialApp is rebuilt.
    return AnimatedBuilder(
      animation: settingsController,
      builder: (BuildContext context, Widget? child) {
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
          ],

          // Use AppLocalizations to configure the correct application title
          // depending on the user's locale.
          //
          // The appTitle is defined in .arb files found in the localization
          // directory.
          onGenerateTitle: (BuildContext context) {
            return "${AppLocalizations.of(context)!.appTitle} • ${Uri.base.host}";
          },

          // Define a light and dark color theme. Then, read the user's
          // preferred ThemeMode (light, dark, or system default) from the
          // SettingsController to display the correct theme.
          theme: ThemeData(),
          darkTheme: ThemeData.dark(),
          themeMode: settingsController.themeMode,

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
                return const MediaListView();
              },
            );
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
      print(uri.queryParameters);

      if (uri.queryParameters.containsKey("add")) {
        return MediaAddView(forcePaste: uri.queryParameters.containsKey("paste"));
      } else if (uri.pathSegments.length < 2) {
        return const MediaListView();
      } else {
        return MediaDetailsView(id: uri.pathSegments[1]);
      }
    } else if (uri.pathSegments[0] == pathSettings) {
      return SettingsView(controller: settingsController);
    } else {
      return null;
    }
  }
}
