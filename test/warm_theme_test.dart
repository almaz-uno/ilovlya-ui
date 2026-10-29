import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ilovlya/src/theme/warm_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  test('Google Fonts themes preserve Flutter text theme metrics', () {
    for (final (theme, base, fontFamily, bodyColor) in [
      (WarmTheme.lightTheme, ThemeData.light().textTheme, 'PTSansCaption', WarmTheme.lightTheme.colorScheme.onSurface),
      (WarmTheme.darkTheme, ThemeData.dark().textTheme, 'PTSans', WarmTheme.darkTheme.colorScheme.onSurface),
    ]) {
      final textTheme = theme.textTheme;
      final stylePairs = <(TextStyle?, TextStyle?)>[
        (textTheme.displayLarge, base.displayLarge),
        (textTheme.displayMedium, base.displayMedium),
        (textTheme.displaySmall, base.displaySmall),
        (textTheme.headlineLarge, base.headlineLarge),
        (textTheme.headlineMedium, base.headlineMedium),
        (textTheme.headlineSmall, base.headlineSmall),
        (textTheme.titleLarge, base.titleLarge),
        (textTheme.titleMedium, base.titleMedium),
        (textTheme.titleSmall, base.titleSmall),
        (textTheme.bodyLarge, base.bodyLarge),
        (textTheme.bodyMedium, base.bodyMedium),
        (textTheme.bodySmall, base.bodySmall),
        (textTheme.labelLarge, base.labelLarge),
        (textTheme.labelMedium, base.labelMedium),
        (textTheme.labelSmall, base.labelSmall),
      ];

      expect(textTheme, isA<TextTheme>());
      for (final (actual, original) in stylePairs) {
        expect(actual, isNotNull);
        expect(actual!.fontFamily, startsWith(fontFamily));
        expect(actual.fontSize, original!.fontSize);
        expect(actual.fontWeight, original.fontWeight);
        expect(actual.fontStyle, original.fontStyle);
        expect(actual.letterSpacing, original.letterSpacing);
        expect(actual.height, original.height);
      }
      expect(textTheme.bodyMedium!.color, bodyColor);
      expect(textTheme.displayMedium!.color, bodyColor);
    }
  });
}
