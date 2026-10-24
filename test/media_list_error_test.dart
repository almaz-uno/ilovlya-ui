import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:ilovlya/src/api/exceptions.dart';
import 'package:ilovlya/src/localization/app_localizations_en.dart';
import 'package:ilovlya/src/localization/app_localizations_ru.dart';
import 'package:ilovlya/src/media/media_list.dart';

void main() {
  for (final l10n in [AppLocalizationsEn(), AppLocalizationsRu()]) {
    test('${l10n.localeName}: only 401 suggests changing credentials', () {
      expect(
          mediaListErrorMessage(
              l10n, HttpStatusError(statusCode: 401, message: 'test')),
          l10n.unauthorizedCheckTokenAndServer);
      expect(l10n.unauthorizedCheckTokenAndServer.toLowerCase(),
          contains(l10n.localeName == 'ru' ? 'токен' : 'token'));
      for (final error in [
        HttpStatusError(statusCode: 403, message: 'test'),
        HttpStatusError(statusCode: 500, message: 'test'),
        const FormatException('empty file'),
        ClientException('offline')
      ]) {
        expect(mediaListErrorMessage(l10n, error),
            startsWith(l10n.recordingsLoadFailed));
        expect(mediaListErrorMessage(l10n, error),
            isNot(contains(l10n.unauthorizedCheckTokenAndServer)));
      }
      expect(l10n.noRecordingsCheckFilters.toLowerCase(),
          isNot(contains('token')));
      expect(l10n.noRecordingsCheckFilters.toLowerCase(),
          isNot(contains('токен')));
    });
  }
}
