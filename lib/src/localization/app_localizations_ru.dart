// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Иловля';

  @override
  String get settings => 'Настройки';

  @override
  String get addNewMedia => 'Добавить новое медиа';

  @override
  String get search => 'Поиск...';

  @override
  String appVersion(String version) {
    return 'Версия: v$version';
  }

  @override
  String get language => 'Язык';

  @override
  String get systemLanguage => 'Системный язык';

  @override
  String get english => 'English';

  @override
  String get russian => 'Русский';

  @override
  String get refreshList => 'Обновить список';

  @override
  String get moreOptions => 'Больше опций';

  @override
  String get showSeen => 'показать просмотренные';

  @override
  String get showHidden => 'показать скрытые';

  @override
  String get sortByCreated => 'сортировать по созданию';

  @override
  String get sortByUpdated => 'сортировать по обновлению';

  @override
  String get showOnlyWithServerFile => 'показать только с серверным файлом';

  @override
  String get showOnlyWithLocalFile => 'показать только с локальным файлом';

  @override
  String get pasteFromClipboard => 'Вставить из буфера';

  @override
  String get enterMediaUrl => 'Введите URL медиа';

  @override
  String get lookupMediaInfo => 'Поиск информации о медиа';

  @override
  String get toViewInfoPressLookup =>
      'Для просмотра информации нажмите кнопку поиска выше';

  @override
  String get successfullyAdded => 'успешно добавлено';

  @override
  String get addingUrl => 'Добавление URL';

  @override
  String get noRecordingsInUrl => 'В данном URL нет записей';

  @override
  String get mediaInfoAcquiring => 'Получение информации о медиа...';

  @override
  String get systemTheme => 'Системная тема';

  @override
  String get lightTheme => 'Светлая тема';

  @override
  String get darkTheme => 'Тёмная тема';

  @override
  String get autoMarkViewedWhenPlayed =>
      'Автоматически отмечать запись как просмотренную при полном воспроизведении';

  @override
  String get updateThumbnailProgress =>
      'Обновлять миниатюру в соответствии с прогрессом просмотра видео';

  @override
  String get showTechnicalInfo =>
      'Показывать дополнительную техническую информацию. Только для продвинутых пользователей!';

  @override
  String quota(String quota) {
    return 'Квота';
  }

  @override
  String used(String used) {
    return 'Использовано';
  }

  @override
  String free(String free) {
    return 'Свободно';
  }

  @override
  String files(String files) {
    return 'Файлы';
  }

  @override
  String local(String local) {
    return 'Локально';
  }

  @override
  String storage(String storage) {
    return 'Хранилище';
  }

  @override
  String get localMediaInfo => 'Информация о локальных медиа';

  @override
  String recordings(String count) {
    return 'Записи';
  }

  @override
  String get totalSize => 'общий размер';

  @override
  String get cleanStaleMedia => 'Очистить устаревшие загруженные медиа';

  @override
  String get cleanAllMedia => 'Очистить ВСЕ загруженные медиа';

  @override
  String get cleanAllMetadata => 'Очистить ВСЕ метаданные для записей';

  @override
  String get cleaned => 'очищено';

  @override
  String get recordingsCleaned => 'записей очищено';

  @override
  String dataLocalPath(String path) {
    return 'Локальный путь данных';
  }

  @override
  String downloadedLocalMediaPath(String path) {
    return 'Путь загруженных локальных медиа';
  }

  @override
  String get cleaningStaleFiles =>
      'очистка устаревших локальных медиафайлов...';

  @override
  String get loading => 'загрузка...';

  @override
  String get loadingInfo => 'Загрузка информации...';

  @override
  String get downloadsInfoLoading => 'Информация о загрузках загружается...';

  @override
  String get noFormatsForRecord => 'Нет форматов для записи';

  @override
  String createdAt(String date, String time) {
    return 'Создано';
  }

  @override
  String get noRecordingsCheckFilterOrToken =>
      'Нет записей. Проверьте настройки фильтра или значение API токена.';

  @override
  String get unauthorizedCheckTokenAndServer =>
      'Не авторизован: проверьте и укажите токен и URL сервера в настройках';

  @override
  String get errorCheckTokenAndServer =>
      'проверьте и укажите токен и URL сервера в настройках';

  @override
  String get loadingInProgress => 'Загрузка...';

  @override
  String get addArbitraryMedia => 'Добавить произвольное медиа';

  @override
  String get addFromClipboard => 'Добавить из буфера обмена';

  @override
  String quotaUsageInfo(
      String quota, String usage, String files, String free, String store) {
    return 'квота: $quota использовано: $usage ($files) свободно: $free$store';
  }

  @override
  String get waitingDataFromServer => 'ожидание данных с сервера...';

  @override
  String get withAudioHandler => 'С аудиообработчиком!';

  @override
  String get seenAt => 'просмотрено';

  @override
  String get duration => 'Длительность';

  @override
  String get hours => 'Часы';

  @override
  String get minutes => 'Минуты';

  @override
  String get seconds => 'Секунды';

  @override
  String updatedAt(String date, String time) {
    return 'Обновлено';
  }

  @override
  String get ago => 'назад';

  @override
  String get localDownloading => 'Локальная загрузка';

  @override
  String get copyFileLinkToClipboard =>
      'Скопировать ссылку на файл в буфер обмена';

  @override
  String get copyCurlCommandToClipboard =>
      'Скопировать команду curl в буфер обмена';

  @override
  String get playWithEmbeddedMpvPlayer =>
      'Воспроизвести с помощью встроенного mpv плеера';

  @override
  String get playWithEmbeddedMpvPlayerHorizontalFlip =>
      'Воспроизвести с помощью встроенного mpv плеера с горизонтальным отражением';

  @override
  String get openInDefaultApplication => 'Открыть в приложении по умолчанию';

  @override
  String get deleteFileOnServerAndFreeQuota =>
      'Удалить файл с сервера и освободить квоту';

  @override
  String get deleteLocalFile => 'Удалить локальный файл';

  @override
  String get shareDownloadUrlIn => 'Поделиться ссылкой для скачивания...';

  @override
  String get downloadLocalFile => 'Загрузить локальный файл';

  @override
  String preparationStarting(String formatId) {
    return 'Подготовка $formatId начинается';
  }

  @override
  String get downloadServerFormat =>
      'Загрузить этот формат снова на сервер (подготовить для просмотра)';

  @override
  String get openMediaKit => 'Открыть с MediaKit с обработчиком';

  @override
  String get doWithIt => 'Что с этим делать...';

  @override
  String get areYouSure => 'Вы уверены?';

  @override
  String get deleteServerMediaFile => 'Удалить медиафайл на сервере?';

  @override
  String get deleteLocalDownloadedMediaFile =>
      'Удалить локальный загруженный медиафайл?';

  @override
  String unexpectedDownloadStatus(String status) {
    return 'Неожиданный статус загрузки $status';
  }

  @override
  String get localFileDownloaded =>
      'Локальный файл загружен. Нажмите для воспроизведения.';

  @override
  String get downloadToLocalStorage => 'Загрузить медиа в локальное хранилище';

  @override
  String get markAsSeen => 'Отметить эту запись как просмотренную';

  @override
  String get markAsUnseen => 'Отметить эту запись как непросмотренную';

  @override
  String get hideRecording => 'Скрыть эту запись (архивировать)';

  @override
  String get showRecording => 'Показать эту запись (разархивировать)';

  @override
  String get scrollUp => 'Прокрутить наверх';

  @override
  String get scrollDown => 'Прокрутить вниз';

  @override
  String get debugCreatedAt => 'создано';

  @override
  String get debugUpdatedAt => 'обновлено';

  @override
  String get debugDuration => 'длительность';

  @override
  String get debugPosition => 'позиция';

  @override
  String get debugBuffered => 'буферизовано';

  @override
  String get debugBuffering => 'буферизация';

  @override
  String get debugVolume => 'громкость';

  @override
  String get debugAudioBitrate => 'битрейт аудио';

  @override
  String get debugAudioDevice => 'аудиоустройство';

  @override
  String get debugSize => 'размер';

  @override
  String get debugVideoParams => 'параметры видео';

  @override
  String get debugAudioParams => 'параметры аудио';

  @override
  String get playingFrom => 'Воспроизводится из';

  @override
  String get sizeLabel => 'Размер';

  @override
  String get copyVideoUrl => 'Копировать URL видео в буфер';

  @override
  String get cleanServerContent =>
      'Очистить весь загруженный контент на сервере';

  @override
  String get cleanDeviceMedia => 'Очистить все загруженные медиа с устройства';

  @override
  String get refreshRecord => 'Обновить запись (перечитать с сервера)';

  @override
  String get copyFileLink => 'Копировать ссылку на файл в буфер';

  @override
  String get copyCurlCommand => 'Копировать curl команду в буфер';

  @override
  String get playEmbeddedMpv => 'Воспроизвести во встроенном mpv плеере';

  @override
  String get playEmbeddedMpvFlipped =>
      'Воспроизвести во встроенном mpv плеере с горизонтальным отражением';

  @override
  String get openDefaultApp => 'Открыть в приложении по умолчанию';

  @override
  String get deleteServerFile =>
      'Удалить файл на сервере и освободить серверную квоту';

  @override
  String get shareDownloadUrl => 'Поделиться ссылкой для загрузки в...';

  @override
  String copiedToClipboard(String text) {
    return '$text скопировано в буфер обмена';
  }

  @override
  String get preparing => 'подготовка...';

  @override
  String get acquiringInfo => 'Получение информации...';

  @override
  String get seekToPosition => 'Перейти к позиции';

  @override
  String get cancel => 'Отмена';

  @override
  String get seek => 'Перейти';

  @override
  String get positionExceedsDuration => 'Позиция превышает длительность видео';

  @override
  String get duration_ => 'длительность';

  @override
  String get position => 'позиция';

  @override
  String get buffered => 'буферизовано';

  @override
  String get buffering => 'буферизация';

  @override
  String get volume => 'громкость';

  @override
  String get audioBitrate => 'аудио битрейт';

  @override
  String get audioDevice => 'аудио устройство';

  @override
  String get size => 'размер';

  @override
  String get videoParams => 'параметры видео';

  @override
  String get audioParams => 'параметры аудио';

  @override
  String blockedAt(String date) {
    return 'Заблокирован в';
  }

  @override
  String get unauthorized =>
      'Не авторизован: проверьте и укажите токен и URL сервера в настройках';

  @override
  String get noRecordings =>
      'Нет записей. Проверьте настройки фильтра или значение API токена.';

  @override
  String get userProfile => 'Профиль пользователя';

  @override
  String get housekeeping => 'Управление файлами';

  @override
  String get yourTokenProvidedByBot => 'Ваш токен, предоставленный ботом';

  @override
  String get serverUrlProvidedByBot => 'URL сервера, предоставленный ботом';

  @override
  String get applicationColorTheme => 'Цветовая тема приложения';

  @override
  String get playerSpeedRate => 'Скорость воспроизведения';

  @override
  String get mediaDirectory => 'Директория медиафайлов';

  @override
  String get deleteAllDownloadedMediaFiles =>
      'Это удалит ВСЕ загруженные медиафайлы';

  @override
  String deleteAllMetadataMessage(int count) {
    return 'Это удалит ВСЕ метаданные для $count записей,\nзагруженные медиафайлы будут сохранены.\nЭти данные можно загрузить с сервера.';
  }

  @override
  String get deleteAllFilesOnServer => 'Удалить все файлы на сервере?';

  @override
  String get deleteAllLocalFilesOnDevice =>
      'Удалить все локальные файлы с устройства?';

  @override
  String get continueButton => 'Продолжить';

  @override
  String get downloadThisFormatOnServer =>
      'Загрузить этот формат и лучшее аудио на сервер (подготовить для просмотра)';

  @override
  String get copyUrlFragmentToClipboard =>
      'Скопировать URL этого фрагмента в буфер обмена';

  @override
  String get bestAudio => 'Лучшее аудио (ba)';

  @override
  String get commonAvailableFormats => 'Общие доступные форматы:';

  @override
  String get availableFormats => 'Доступные форматы:';

  @override
  String get downloadExactFormat =>
      'Скачать именно этот формат (подготовить для просмотра)';

  @override
  String selectedPosition(String position) {
    return 'Выбранная позиция: $position';
  }

  @override
  String get positionExceedsVideoDuration =>
      'Позиция превышает длительность видео';

  @override
  String get cleanAllDownloadedContentOnServer =>
      'Очистить все загруженное содержимое на сервере';

  @override
  String get cleanAllDownloadedMediaFromDevice =>
      'Очистить все загруженные медиа с устройства';

  @override
  String get downloadsInfoIsLoading => 'Информация о загрузках загружается...';

  @override
  String get copyVideoUrlToClipboard => 'Копировать URL видео в буфер обмена';

  @override
  String get downloadThisFormatAgainOnServer =>
      'Загрузить этот формат снова на сервере (подготовить для просмотра)';

  @override
  String get openWithMediaKitHandler => 'Открыть с помощью MediaKit';

  @override
  String get playWithEmbeddedMpvPlayerWithHorizontalFlip =>
      'Воспроизвести с помощью встроенного mpv плеера с горизонтальным отражением';

  @override
  String get localFileDownloadedClickToPlay =>
      'Локальный файл загружен. Нажмите для воспроизведения.';

  @override
  String get downloadMediaToLocalStorage =>
      'Загрузить медиа в локальное хранилище';

  @override
  String get markRecordingAsSeen => 'Отметить эту запись как просмотренную';

  @override
  String get markRecordingAsUnseen => 'Отметить эту запись как непросмотренную';

  @override
  String filesWithSize(String number, String size) {
    return 'Файлов: $number, общий размер: $size';
  }

  @override
  String get cleanStaleDownloadedMedia => 'Очистить старые загруженные медиа';

  @override
  String filesCleanedMessage(int count, String size) {
    return '$count файлов, $size очищено';
  }

  @override
  String get cleanAllDownloadedMedia => 'Очистить ВСЕ загруженные медиа';

  @override
  String cleanAllMetadataForRecordings(String count) {
    return 'Очистить ВСЕ метаданные для $count записей';
  }

  @override
  String get cleaningStaleMediaLocalFiles =>
      'очистка старых локальных медиафайлов...';

  @override
  String tapToPlayInEmbeddingPlayer(String filename) {
    return '$filename нажмите для воспроизведения во встроенном плеере';
  }

  @override
  String get noDownloadsForRecording => 'Нет загрузок для записи';

  @override
  String get filesForThisRecording => 'Файлы для этой записи';

  @override
  String get formatHeader => 'формат';

  @override
  String get resolutionHeader => 'разрешение';

  @override
  String get fpsHeader => 'кадр/с';

  @override
  String get sizeHeader => 'размер';

  @override
  String get id => 'ID';

  @override
  String get url => 'URL';

  @override
  String get ext => 'расш.';

  @override
  String get resolution => 'разрешение';

  @override
  String get fps => 'кадр/с';

  @override
  String get format => 'формат';

  @override
  String get preparingEllipsis => 'подготовка...';

  @override
  String successfullyAddedMessage(String title) {
    return '$title успешно добавлено';
  }

  @override
  String addingUrlWithVariable(String url) {
    return 'Добавление URL $url...';
  }

  @override
  String createdAtWithDate(String date, String timeAgo) {
    return 'Создано: $date ($timeAgo)';
  }

  @override
  String updatedAtWithDate(String date, String timeAgo) {
    return 'Обновлено: $date ($timeAgo)';
  }

  @override
  String localDownloadingStatus(
      String status, String filename, String estimate) {
    return 'Локальная загрузка $status: $filename $estimate';
  }

  @override
  String recordingsCleanedMessage(int count) {
    return '$count записей очищено';
  }

  @override
  String copiedToClipboardMessage(String text) {
    return '$text скопировано в буфер обмена';
  }

  @override
  String quotaLabel(String quota) {
    return 'Квота: $quota';
  }

  @override
  String usedLabel(String used) {
    return 'Использовано: $used';
  }

  @override
  String freeLabel(String free) {
    return 'Свободно: $free';
  }

  @override
  String filesLabel(int files) {
    return 'Файлы: $files';
  }

  @override
  String localLabel(String local) {
    return 'Локально: $local';
  }

  @override
  String storageLabel(String storage) {
    return 'Хранилище: $storage';
  }

  @override
  String recordingsLabel(int recordings) {
    return 'Записи: $recordings';
  }

  @override
  String filesTotalSizeLabel(int count, String size) {
    return 'Файлы: $count, общий размер: $size';
  }

  @override
  String blockedAtLabel(String date) {
    return 'Заблокировано $date';
  }

  @override
  String get speedSlow => 'медленно';

  @override
  String get speedNormal => 'нормально';

  @override
  String get speedMedium => 'средне';

  @override
  String get speedFast => 'быстро';

  @override
  String get speedVeryFast => 'очень быстро';

  @override
  String get speedSuperFast => 'супер быстро';
}
