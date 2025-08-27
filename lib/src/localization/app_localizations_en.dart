// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Ilovlya';

  @override
  String get settings => 'Settings';

  @override
  String get addNewMedia => 'Add new media';

  @override
  String get search => 'Search...';

  @override
  String get language => 'Language';

  @override
  String get systemLanguage => 'System language';

  @override
  String get english => 'English';

  @override
  String get russian => 'Русский';

  @override
  String get refreshList => 'Refresh list';

  @override
  String get moreOptions => 'More options';

  @override
  String get showSeen => 'show seen';

  @override
  String get showHidden => 'show hidden';

  @override
  String get sortByCreated => 'sort by created';

  @override
  String get sortByUpdated => 'sort by updated';

  @override
  String get showOnlyWithServerFile => 'show only with server file';

  @override
  String get showOnlyWithLocalFile => 'show only with local file';

  @override
  String get pasteFromClipboard => 'Paste from clipboard';

  @override
  String get enterMediaUrl => 'Enter media URL';

  @override
  String get lookupMediaInfo => 'Lookup media info';

  @override
  String get toViewInfoPressLookup => 'To view info press lookup button above';

  @override
  String get successfullyAdded => 'successfully added';

  @override
  String get addingUrl => 'Adding url';

  @override
  String get noRecordingsInUrl => 'There is no recordings in the url';

  @override
  String get mediaInfoAcquiring => 'Media info acquiring in progress...';

  @override
  String get systemTheme => 'System Theme';

  @override
  String get lightTheme => 'Light Theme';

  @override
  String get darkTheme => 'Dark Theme';

  @override
  String get autoMarkViewedWhenPlayed =>
      'Auto mark recording as viewed when fully played';

  @override
  String get updateThumbnailProgress =>
      'Update thumbnail according to video viewing progress';

  @override
  String get showTechnicalInfo =>
      'Show additional technical info. For advanced users only!';

  @override
  String quota(String quota) {
    return 'Quota: $quota';
  }

  @override
  String used(String used) {
    return 'Used: $used';
  }

  @override
  String free(String free) {
    return 'Free: $free';
  }

  @override
  String files(String files) {
    return 'Files: $files';
  }

  @override
  String local(String local) {
    return 'Local: $local';
  }

  @override
  String storage(String storage) {
    return 'Storage: $storage';
  }

  @override
  String get localMediaInfo => 'Local media info';

  @override
  String recordings(String count) {
    return 'Recordings: $count';
  }

  @override
  String get totalSize => 'total size';

  @override
  String get cleanStaleMedia => 'Clean stale downloaded media';

  @override
  String get cleanAllMedia => 'Clean ALL downloaded media';

  @override
  String get cleanAllMetadata => 'Clean ALL metadata for recordings';

  @override
  String get cleaned => 'cleaned';

  @override
  String get recordingsCleaned => 'recordings cleaned';

  @override
  String dataLocalPath(String path) {
    return 'Data local path: $path';
  }

  @override
  String downloadedLocalMediaPath(String path) {
    return 'Downloaded local media path: $path';
  }

  @override
  String get cleaningStaleFiles => 'cleaning stale media local files...';

  @override
  String get loading => 'loading...';

  @override
  String get loadingInfo => 'Loading info...';

  @override
  String get downloadsInfoLoading => 'Downloads info is loading...';

  @override
  String get noFormatsForRecord => 'No formats for the record';

  @override
  String createdAt(String date, String time) {
    return 'Created at: $date ($time ago)';
  }

  @override
  String get noRecordingsCheckFilterOrToken =>
      'No recordings. Check you filter settings or API token value.';

  @override
  String get unauthorizedCheckTokenAndServer =>
      'Unauthorized: please check and specify token and server URL in settings';

  @override
  String get errorCheckTokenAndServer =>
      'please check and specify token and server URL in settings';

  @override
  String get loadingInProgress => 'Loading in progress...';

  @override
  String get addArbitraryMedia => 'Add an arbitrary media';

  @override
  String get addFromClipboard => 'Add from clipboard';

  @override
  String quotaUsageInfo(
      String quota, String usage, String files, String free, String store) {
    return 'quote: $quota usage: $usage ($files) free: $free$store';
  }

  @override
  String get waitingDataFromServer => 'waiting data from the server...';

  @override
  String get withAudioHandler => 'With audio handler!';

  @override
  String get seenAt => 'seen at';

  @override
  String get duration => 'Duration';

  @override
  String get hours => 'Hours';

  @override
  String get minutes => 'Minutes';

  @override
  String get seconds => 'Seconds';

  @override
  String updatedAt(String date, String time) {
    return 'Updated at: $date ($time ago)';
  }

  @override
  String get ago => 'ago';

  @override
  String get localDownloading => 'Local downloading';

  @override
  String get copyFileLinkToClipboard => 'Copy file link to clipboard';

  @override
  String get copyCurlCommandToClipboard => 'Copy curl command to clipboard';

  @override
  String get playWithEmbeddedMpvPlayer => 'Play with embedded mpv player';

  @override
  String get playWithEmbeddedMpvPlayerHorizontalFlip =>
      'Play with embedded mpv player with horizontal flip';

  @override
  String get openInDefaultApplication => 'Open in default application';

  @override
  String get deleteFileOnServerAndFreeQuota =>
      'Delete file on the server and free server usage quota';

  @override
  String get deleteLocalFile => 'Delete local file';

  @override
  String get shareDownloadUrlIn => 'Share the download URL in...';

  @override
  String get downloadLocalFile => 'Download local file';

  @override
  String preparationStarting(String formatId) {
    return 'Preparation for $formatId is starting';
  }

  @override
  String get downloadServerFormat =>
      'Download this format again on the server (prepare for viewing)';

  @override
  String get openMediaKit => 'Open with MediaKit with handler';

  @override
  String get doWithIt => 'Do with it...';

  @override
  String get areYouSure => 'Are you sure?';

  @override
  String get deleteServerMediaFile => 'Delete server media file?';

  @override
  String get deleteLocalDownloadedMediaFile =>
      'Delete local downloaded media file?';

  @override
  String unexpectedDownloadStatus(String status) {
    return 'Unexpected download status $status';
  }

  @override
  String get localFileDownloaded => 'Local file is downloaded. Click to play.';

  @override
  String get downloadToLocalStorage => 'Download media to local storage';

  @override
  String get markAsSeen => 'Mark this recording as seen';

  @override
  String get markAsUnseen => 'Mark this recording as unseen';

  @override
  String get hideRecording => 'Hide this recording (archive it)';

  @override
  String get showRecording => 'Show this recording (unarchive it)';

  @override
  String get scrollUp => 'Scroll to top';

  @override
  String get scrollDown => 'Scroll to bottom';

  @override
  String get debugCreatedAt => 'created at';

  @override
  String get debugUpdatedAt => 'updated at';

  @override
  String get debugDuration => 'duration';

  @override
  String get debugPosition => 'position';

  @override
  String get debugBuffered => 'buffered';

  @override
  String get debugBuffering => 'buffering';

  @override
  String get debugVolume => 'volume';

  @override
  String get debugAudioBitrate => 'audio bitrate';

  @override
  String get debugAudioDevice => 'audio device';

  @override
  String get debugSize => 'size';

  @override
  String get debugVideoParams => 'video params';

  @override
  String get debugAudioParams => 'audio params';

  @override
  String get playingFrom => 'Playing from';

  @override
  String get sizeLabel => 'Size';

  @override
  String get copyVideoUrl => 'Copy video URL to the clipboard';

  @override
  String get cleanServerContent => 'Clean all downloaded content on the server';

  @override
  String get cleanDeviceMedia => 'Clean all downloaded media from the device';

  @override
  String get refreshRecord => 'Refresh record (reread from the server)';

  @override
  String get copyFileLink => 'Copy file link to clipboard';

  @override
  String get copyCurlCommand => 'Copy curl command to clipboard';

  @override
  String get playEmbeddedMpv => 'Play with embedded mpv player';

  @override
  String get playEmbeddedMpvFlipped =>
      'Play with embedded mpv player with horizontal flip';

  @override
  String get openDefaultApp => 'Open in default application';

  @override
  String get deleteServerFile =>
      'Delete file on the server and free server usage quota';

  @override
  String get shareDownloadUrl => 'Share the download URL in...';

  @override
  String copiedToClipboard(String text) {
    return '$text copied to clipboard';
  }

  @override
  String get preparing => 'preparing...';

  @override
  String get acquiringInfo => 'Acquiring info...';

  @override
  String get seekToPosition => 'Seek to Position';

  @override
  String get cancel => 'Cancel';

  @override
  String get seek => 'Seek';

  @override
  String get positionExceedsDuration => 'Position exceeds video duration';

  @override
  String get duration_ => 'duration';

  @override
  String get position => 'position';

  @override
  String get buffered => 'buffered';

  @override
  String get buffering => 'buffering';

  @override
  String get volume => 'volume';

  @override
  String get audioBitrate => 'audio bitrate';

  @override
  String get audioDevice => 'audio device';

  @override
  String get size => 'size';

  @override
  String get videoParams => 'video params';

  @override
  String get audioParams => 'audio params';

  @override
  String blockedAt(String date) {
    return 'Blocked at $date';
  }

  @override
  String get unauthorized =>
      'Unauthorized: please check and specify token and server URL in settings';

  @override
  String get noRecordings =>
      'No recordings. Check you filter settings or API token value.';

  @override
  String get userProfile => 'User profile';

  @override
  String get housekeeping => 'Housekeeping';

  @override
  String get yourTokenProvidedByBot => 'Your token, provided by the bot';

  @override
  String get serverUrlProvidedByBot => 'Server URL, provided by the bot';

  @override
  String get applicationColorTheme => 'Application color theme';

  @override
  String get playerSpeedRate => 'Player speed rate';

  @override
  String get mediaDirectory => 'Media directory';

  @override
  String get deleteAllDownloadedMediaFiles =>
      'This will delete ALL downloaded media files';

  @override
  String deleteAllMetadataMessage(int count) {
    return 'This will delete ALL metadata for $count recordings,\ndownloaded media files will be retained.\nThis data can be downloaded from the server.';
  }

  @override
  String get deleteAllFilesOnServer => 'Delete all files on the server?';

  @override
  String get deleteAllLocalFilesOnDevice =>
      'Delete all local files on the device?';

  @override
  String get continueButton => 'Continue';

  @override
  String get downloadThisFormatOnServer =>
      'Download this format and the best audio on the server (prepare for viewing)';

  @override
  String get copyUrlFragmentToClipboard =>
      'Copy URL this fragment into clipboard';

  @override
  String get bestAudio => 'Best audio (ba)';

  @override
  String get commonAvailableFormats => 'Common available formats:';

  @override
  String get availableFormats => 'Available formats:';

  @override
  String get downloadExactFormat =>
      'Download exact this format (prepare this format for viewing)';

  @override
  String selectedPosition(String position) {
    return 'Selected position: $position';
  }

  @override
  String get positionExceedsVideoDuration => 'Position exceeds video duration';

  @override
  String get cleanAllDownloadedContentOnServer =>
      'Clean all downloaded content on the server';

  @override
  String get cleanAllDownloadedMediaFromDevice =>
      'Clean all downloaded media from the device';

  @override
  String get downloadsInfoIsLoading => 'Downloads info is loading...';

  @override
  String get copyVideoUrlToClipboard => 'Copy video URL to the clipboard';

  @override
  String get downloadThisFormatAgainOnServer =>
      'Download this format again on the server (prepare for viewing)';

  @override
  String get openWithMediaKitHandler => 'Open with MediaKit with handler';

  @override
  String get playWithEmbeddedMpvPlayerWithHorizontalFlip =>
      'Play with embedded mpv player with horizontal flip';

  @override
  String get localFileDownloadedClickToPlay =>
      'Local file is downloaded. Click to play.';

  @override
  String get downloadMediaToLocalStorage => 'Download media to local storage';

  @override
  String get markRecordingAsSeen => 'Mark this recording as seen';

  @override
  String get markRecordingAsUnseen => 'Mark this recording as unseen';

  @override
  String filesWithSize(String number, String size) {
    return 'Files: $number, total size: $size';
  }

  @override
  String get cleanStaleDownloadedMedia => 'Clean stale downloaded media';

  @override
  String filesCleanedMessage(int count, String size) {
    return '$count files, $size cleaned';
  }

  @override
  String get cleanAllDownloadedMedia => 'Clean ALL downloaded media';

  @override
  String cleanAllMetadataForRecordings(String count) {
    return 'Clean ALL metadata for $count recordings';
  }

  @override
  String get cleaningStaleMediaLocalFiles =>
      'cleaning stale media local files...';

  @override
  String tapToPlayInEmbeddingPlayer(String filename) {
    return '$filename tap to play in embedding player';
  }

  @override
  String get noDownloadsForRecording => 'No downloads for recording';

  @override
  String get filesForThisRecording => 'Files for this recording';

  @override
  String get formatHeader => 'format';

  @override
  String get resolutionHeader => 'resolution';

  @override
  String get fpsHeader => 'fps';

  @override
  String get sizeHeader => 'size';

  @override
  String get id => 'id';

  @override
  String get url => 'URL';

  @override
  String get ext => 'ext';

  @override
  String get resolution => 'resolution';

  @override
  String get fps => 'fps';

  @override
  String get format => 'format';

  @override
  String get preparingEllipsis => 'preparing...';

  @override
  String successfullyAddedMessage(String title) {
    return '$title successfully added';
  }

  @override
  String addingUrlWithVariable(String url) {
    return 'Adding url $url...';
  }

  @override
  String createdAtWithDate(String date, String timeAgo) {
    return 'Created at: $date ($timeAgo)';
  }

  @override
  String updatedAtWithDate(String date, String timeAgo) {
    return 'Updated at: $date ($timeAgo)';
  }

  @override
  String localDownloadingStatus(
      String status, String filename, String estimate) {
    return 'Local downloading $status: $filename $estimate';
  }

  @override
  String recordingsCleanedMessage(int count) {
    return '$count recordings cleaned';
  }

  @override
  String copiedToClipboardMessage(String text) {
    return '$text copied to clipboard';
  }

  @override
  String quotaLabel(String quota) {
    return 'Quota: $quota';
  }

  @override
  String usedLabel(String used) {
    return 'Used: $used';
  }

  @override
  String freeLabel(String free) {
    return 'Free: $free';
  }

  @override
  String filesLabel(int files) {
    return 'Files: $files';
  }

  @override
  String localLabel(String local) {
    return 'Local: $local';
  }

  @override
  String storageLabel(String storage) {
    return 'Storage: $storage';
  }

  @override
  String recordingsLabel(int recordings) {
    return 'Recordings: $recordings';
  }

  @override
  String filesTotalSizeLabel(int count, String size) {
    return 'Files: $count, total size: $size';
  }

  @override
  String blockedAtLabel(String date) {
    return 'Blocked at $date';
  }

  @override
  String get speedSlow => 'slow';

  @override
  String get speedNormal => 'normal';

  @override
  String get speedMedium => 'medium';

  @override
  String get speedFast => 'fast';

  @override
  String get speedVeryFast => 'very fast';

  @override
  String get speedSuperFast => 'super fast';
}
