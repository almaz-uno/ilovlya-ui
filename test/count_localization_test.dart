import 'package:flutter_test/flutter_test.dart';
import 'package:ilovlya/src/localization/app_localizations_en.dart';
import 'package:ilovlya/src/localization/app_localizations_ru.dart';

void main() {
  final ru = AppLocalizationsRu();
  final en = AppLocalizationsEn();
  const size = '1.0Mb';

  const russianForms = <int, List<String>>{
    0: ['файлов', 'записей', 'форматов'],
    1: ['файл', 'запись', 'формат'],
    2: ['файла', 'записи', 'формата'],
    5: ['файлов', 'записей', 'форматов'],
    11: ['файлов', 'записей', 'форматов'],
    12: ['файлов', 'записей', 'форматов'],
    14: ['файлов', 'записей', 'форматов'],
    21: ['файл', 'запись', 'формат'],
    22: ['файла', 'записи', 'формата'],
    25: ['файлов', 'записей', 'форматов'],
    101: ['файл', 'запись', 'формат'],
    111: ['файлов', 'записей', 'форматов'],
  };

  for (final entry in russianForms.entries) {
    final count = entry.key;
    final [file, recording, format] = entry.value;
    test('Russian count messages use the correct forms for $count', () {
      expect(ru.filesCleanedMessage(count, size), '${file == 'файл' ? 'Очищен' : 'Очищено'} $count $file, $size');
      expect(ru.recordingsCleanedMessage(count), '${recording == 'запись' ? 'Очищена' : 'Очищено'} $count $recording');
      expect(ru.files(count), '$count $file');
      expect(ru.filesLabel(count), '$count $file');
      expect(ru.recordings(count), '$count $recording');
      expect(ru.recordingsLabel(count), '$count $recording');
      expect(ru.filesWithSize(count, size), '$count $file, общий размер: $size');
      expect(ru.filesTotalSizeLabel(count, size), '$count $file, общий размер: $size');
      expect(ru.formatsCount(count), '$count $format');
      final genitive = recording == 'запись' ? 'записи' : 'записей';
      expect(ru.cleanAllMetadataForRecordings(count), 'Очистить ВСЕ метаданные для $count $genitive');
      expect(ru.deleteAllMetadataMessage(count), 'Это удалит ВСЕ метаданные для $count $genitive,\nзагруженные медиафайлы будут сохранены.\nЭти данные можно загрузить с сервера.');
      expect(ru.quotaUsageInfo('10Gb', '1Gb', count, '9Gb', ''), 'квота: 10Gb использовано: 1Gb ($count $file) свободно: 9Gb');
    });
  }

  for (final count in [0, 1, 2, 5, 21]) {
    test('English count messages use the correct forms for $count', () {
      final file = count == 1 ? 'file' : 'files';
      final recording = count == 1 ? 'recording' : 'recordings';
      final format = count == 1 ? 'format' : 'formats';
      expect(en.filesCleanedMessage(count, size), 'Cleaned $count $file, $size');
      expect(en.recordingsCleanedMessage(count), 'Cleaned $count $recording');
      expect(en.files(count), '$count $file');
      expect(en.filesLabel(count), '$count $file');
      expect(en.recordings(count), '$count $recording');
      expect(en.recordingsLabel(count), '$count $recording');
      expect(en.filesWithSize(count, size), '$count $file, total size: $size');
      expect(en.filesTotalSizeLabel(count, size), '$count $file, total size: $size');
      expect(en.formatsCount(count), '$count $format');
      expect(en.cleanAllMetadataForRecordings(count), 'Clean ALL metadata for $count $recording');
      expect(en.deleteAllMetadataMessage(count), 'This will delete ALL metadata for $count $recording,\ndownloaded media files will be retained.\nThis data can be downloaded from the server.');
      expect(en.quotaUsageInfo('10Gb', '1Gb', count, '9Gb', ''), 'quota: 10Gb usage: 1Gb ($count $file) free: 9Gb');
    });
  }

  test('deduplicated parameterized messages retain their arguments', () {
    expect(ru.blockedAt('2026-10-23'), 'Заблокирован 2026-10-23');
    expect(ru.createdAt('2026-10-23', '1 час'), 'Создано: 2026-10-23 (1 час назад)');
    expect(ru.updatedAt('2026-10-23', '1 час'), 'Обновлено: 2026-10-23 (1 час назад)');
    expect(ru.preparationStarting('audio'), 'Подготовка audio начинается');
    expect(ru.copiedToClipboard('URL'), 'URL скопировано в буфер обмена');
    expect(en.blockedAt('2026-10-23'), 'Blocked at 2026-10-23');
    expect(en.preparationStarting('audio'), 'Preparation for audio is starting');
    expect(en.copiedToClipboard('URL'), 'URL copied to clipboard');
  });
}
