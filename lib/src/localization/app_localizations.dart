import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'localization/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru')
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Ilovlya'**
  String get appTitle;

  /// Settings button tooltip
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Title for adding new media
  ///
  /// In en, this message translates to:
  /// **'Add new media'**
  String get addNewMedia;

  /// Search field placeholder
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get search;

  /// Language setting label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// System language option
  ///
  /// In en, this message translates to:
  /// **'System language'**
  String get systemLanguage;

  /// English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// Russian language option
  ///
  /// In en, this message translates to:
  /// **'Русский'**
  String get russian;

  /// Tooltip for refresh list button
  ///
  /// In en, this message translates to:
  /// **'Refresh list'**
  String get refreshList;

  /// Tooltip for more options menu
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get moreOptions;

  /// Option to show seen recordings
  ///
  /// In en, this message translates to:
  /// **'show seen'**
  String get showSeen;

  /// Option to show hidden recordings
  ///
  /// In en, this message translates to:
  /// **'show hidden'**
  String get showHidden;

  /// Option to sort by creation date
  ///
  /// In en, this message translates to:
  /// **'sort by created'**
  String get sortByCreated;

  /// Option to sort by update date
  ///
  /// In en, this message translates to:
  /// **'sort by updated'**
  String get sortByUpdated;

  /// Option to show only recordings with server file
  ///
  /// In en, this message translates to:
  /// **'show only with server file'**
  String get showOnlyWithServerFile;

  /// Option to show only recordings with local file
  ///
  /// In en, this message translates to:
  /// **'show only with local file'**
  String get showOnlyWithLocalFile;

  /// Tooltip for paste from clipboard button
  ///
  /// In en, this message translates to:
  /// **'Paste from clipboard'**
  String get pasteFromClipboard;

  /// Hint text for media URL input field
  ///
  /// In en, this message translates to:
  /// **'Enter media URL'**
  String get enterMediaUrl;

  /// Tooltip for lookup media info button
  ///
  /// In en, this message translates to:
  /// **'Lookup media info'**
  String get lookupMediaInfo;

  /// Message about how to view media info
  ///
  /// In en, this message translates to:
  /// **'To view info press lookup button above'**
  String get toViewInfoPressLookup;

  /// Message about successful media addition
  ///
  /// In en, this message translates to:
  /// **'successfully added'**
  String get successfullyAdded;

  /// Message about URL adding process
  ///
  /// In en, this message translates to:
  /// **'Adding url'**
  String get addingUrl;

  /// No recordings found in URL message
  ///
  /// In en, this message translates to:
  /// **'There is no recordings in the url'**
  String get noRecordingsInUrl;

  /// Media info acquisition progress message
  ///
  /// In en, this message translates to:
  /// **'Media info acquiring in progress...'**
  String get mediaInfoAcquiring;

  /// System theme option
  ///
  /// In en, this message translates to:
  /// **'System Theme'**
  String get systemTheme;

  /// Light theme option
  ///
  /// In en, this message translates to:
  /// **'Light Theme'**
  String get lightTheme;

  /// Dark theme option
  ///
  /// In en, this message translates to:
  /// **'Dark Theme'**
  String get darkTheme;

  /// Setting for auto marking recordings as viewed
  ///
  /// In en, this message translates to:
  /// **'Auto mark recording as viewed when fully played'**
  String get autoMarkViewedWhenPlayed;

  /// Setting for updating thumbnail by viewing progress
  ///
  /// In en, this message translates to:
  /// **'Update thumbnail according to video viewing progress'**
  String get updateThumbnailProgress;

  /// Setting for showing technical info
  ///
  /// In en, this message translates to:
  /// **'Show additional technical info. For advanced users only!'**
  String get showTechnicalInfo;

  /// User quota information
  ///
  /// In en, this message translates to:
  /// **'Quota: {quota}'**
  String quota(String quota);

  /// Used storage information
  ///
  /// In en, this message translates to:
  /// **'Used: {used}'**
  String used(String used);

  /// Free storage information
  ///
  /// In en, this message translates to:
  /// **'Free: {free}'**
  String free(String free);

  /// Number of files
  ///
  /// In en, this message translates to:
  /// **'Files: {files}'**
  String files(String files);

  /// Local storage information
  ///
  /// In en, this message translates to:
  /// **'Local: {local}'**
  String local(String local);

  /// Storage information
  ///
  /// In en, this message translates to:
  /// **'Storage: {storage}'**
  String storage(String storage);

  /// Header for local media information
  ///
  /// In en, this message translates to:
  /// **'Local media info'**
  String get localMediaInfo;

  /// Number of recordings
  ///
  /// In en, this message translates to:
  /// **'Recordings: {count}'**
  String recordings(String count);

  /// Total files size
  ///
  /// In en, this message translates to:
  /// **'total size'**
  String get totalSize;

  /// Button for cleaning stale media
  ///
  /// In en, this message translates to:
  /// **'Clean stale downloaded media'**
  String get cleanStaleMedia;

  /// Button for cleaning all media
  ///
  /// In en, this message translates to:
  /// **'Clean ALL downloaded media'**
  String get cleanAllMedia;

  /// Button for cleaning all metadata
  ///
  /// In en, this message translates to:
  /// **'Clean ALL metadata for recordings'**
  String get cleanAllMetadata;

  /// Cleaning completion message
  ///
  /// In en, this message translates to:
  /// **'cleaned'**
  String get cleaned;

  /// Recordings cleaning completion message
  ///
  /// In en, this message translates to:
  /// **'recordings cleaned'**
  String get recordingsCleaned;

  /// Local data path information
  ///
  /// In en, this message translates to:
  /// **'Data local path: {path}'**
  String dataLocalPath(String path);

  /// Local media path information
  ///
  /// In en, this message translates to:
  /// **'Downloaded local media path: {path}'**
  String downloadedLocalMediaPath(String path);

  /// Stale files cleaning process
  ///
  /// In en, this message translates to:
  /// **'cleaning stale media local files...'**
  String get cleaningStaleFiles;

  /// Loading text
  ///
  /// In en, this message translates to:
  /// **'loading...'**
  String get loading;

  /// Loading text for media info
  ///
  /// In en, this message translates to:
  /// **'Loading info...'**
  String get loadingInfo;

  /// Downloads info loading message
  ///
  /// In en, this message translates to:
  /// **'Downloads info is loading...'**
  String get downloadsInfoLoading;

  /// Text when no formats available
  ///
  /// In en, this message translates to:
  /// **'No formats for the record'**
  String get noFormatsForRecord;

  /// Created date text
  ///
  /// In en, this message translates to:
  /// **'Created at: {date} ({time} ago)'**
  String createdAt(String date, String time);

  /// Message when no recordings found
  ///
  /// In en, this message translates to:
  /// **'No recordings. Check you filter settings or API token value.'**
  String get noRecordingsCheckFilterOrToken;

  /// Unauthorized error message
  ///
  /// In en, this message translates to:
  /// **'Unauthorized: please check and specify token and server URL in settings'**
  String get unauthorizedCheckTokenAndServer;

  /// General error message for token/server issues
  ///
  /// In en, this message translates to:
  /// **'please check and specify token and server URL in settings'**
  String get errorCheckTokenAndServer;

  /// Loading indicator message
  ///
  /// In en, this message translates to:
  /// **'Loading in progress...'**
  String get loadingInProgress;

  /// Tooltip for add media button
  ///
  /// In en, this message translates to:
  /// **'Add an arbitrary media'**
  String get addArbitraryMedia;

  /// Tooltip for add from clipboard button
  ///
  /// In en, this message translates to:
  /// **'Add from clipboard'**
  String get addFromClipboard;

  /// Quota and usage information
  ///
  /// In en, this message translates to:
  /// **'quote: {quota} usage: {usage} ({files}) free: {free}{store}'**
  String quotaUsageInfo(
      String quota, String usage, String files, String free, String store);

  /// Message about waiting data from server
  ///
  /// In en, this message translates to:
  /// **'waiting data from the server...'**
  String get waitingDataFromServer;

  /// Technical info about audio handler
  ///
  /// In en, this message translates to:
  /// **'With audio handler!'**
  String get withAudioHandler;

  /// Seen time
  ///
  /// In en, this message translates to:
  /// **'seen at'**
  String get seenAt;

  /// Video duration
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// Hours in seek dialog
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get hours;

  /// Minutes in seek dialog
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get minutes;

  /// Seconds in seek dialog
  ///
  /// In en, this message translates to:
  /// **'Seconds'**
  String get seconds;

  /// Updated date text
  ///
  /// In en, this message translates to:
  /// **'Updated at: {date} ({time} ago)'**
  String updatedAt(String date, String time);

  /// Time suffix 'ago'
  ///
  /// In en, this message translates to:
  /// **'ago'**
  String get ago;

  /// Local downloading status
  ///
  /// In en, this message translates to:
  /// **'Local downloading'**
  String get localDownloading;

  /// Menu item text
  ///
  /// In en, this message translates to:
  /// **'Copy file link to clipboard'**
  String get copyFileLinkToClipboard;

  /// Menu item text
  ///
  /// In en, this message translates to:
  /// **'Copy curl command to clipboard'**
  String get copyCurlCommandToClipboard;

  /// Menu item text
  ///
  /// In en, this message translates to:
  /// **'Play with embedded mpv player'**
  String get playWithEmbeddedMpvPlayer;

  /// Button text to play with embedded player with horizontal flip
  ///
  /// In en, this message translates to:
  /// **'Play with embedded mpv player with horizontal flip'**
  String get playWithEmbeddedMpvPlayerHorizontalFlip;

  /// Menu item text
  ///
  /// In en, this message translates to:
  /// **'Open in default application'**
  String get openInDefaultApplication;

  /// Menu item text
  ///
  /// In en, this message translates to:
  /// **'Delete file on the server and free server usage quota'**
  String get deleteFileOnServerAndFreeQuota;

  /// Menu item text
  ///
  /// In en, this message translates to:
  /// **'Delete local file'**
  String get deleteLocalFile;

  /// Button text to share download URL
  ///
  /// In en, this message translates to:
  /// **'Share the download URL in...'**
  String get shareDownloadUrlIn;

  /// Menu item text
  ///
  /// In en, this message translates to:
  /// **'Download local file'**
  String get downloadLocalFile;

  /// Snackbar text when preparation starts
  ///
  /// In en, this message translates to:
  /// **'Preparation for {formatId} is starting'**
  String preparationStarting(String formatId);

  /// Tooltip for downloading server format
  ///
  /// In en, this message translates to:
  /// **'Download this format again on the server (prepare for viewing)'**
  String get downloadServerFormat;

  /// Tooltip for opening with MediaKit
  ///
  /// In en, this message translates to:
  /// **'Open with MediaKit with handler'**
  String get openMediaKit;

  /// Tooltip for actions menu
  ///
  /// In en, this message translates to:
  /// **'Do with it...'**
  String get doWithIt;

  /// Confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get areYouSure;

  /// Confirmation dialog for deleting server file
  ///
  /// In en, this message translates to:
  /// **'Delete server media file?'**
  String get deleteServerMediaFile;

  /// Confirmation dialog for deleting local file
  ///
  /// In en, this message translates to:
  /// **'Delete local downloaded media file?'**
  String get deleteLocalDownloadedMediaFile;

  /// Error message for unexpected status
  ///
  /// In en, this message translates to:
  /// **'Unexpected download status {status}'**
  String unexpectedDownloadStatus(String status);

  /// Tooltip for playing downloaded file
  ///
  /// In en, this message translates to:
  /// **'Local file is downloaded. Click to play.'**
  String get localFileDownloaded;

  /// Tooltip for downloading to local storage
  ///
  /// In en, this message translates to:
  /// **'Download media to local storage'**
  String get downloadToLocalStorage;

  /// Tooltip for marking as seen
  ///
  /// In en, this message translates to:
  /// **'Mark this recording as seen'**
  String get markAsSeen;

  /// Tooltip for marking as unseen
  ///
  /// In en, this message translates to:
  /// **'Mark this recording as unseen'**
  String get markAsUnseen;

  /// Tooltip for hide recording
  ///
  /// In en, this message translates to:
  /// **'Hide this recording (archive it)'**
  String get hideRecording;

  /// Tooltip for show recording
  ///
  /// In en, this message translates to:
  /// **'Show this recording (unarchive it)'**
  String get showRecording;

  /// Scroll up button tooltip
  ///
  /// In en, this message translates to:
  /// **'Scroll to top'**
  String get scrollUp;

  /// Scroll down button tooltip
  ///
  /// In en, this message translates to:
  /// **'Scroll to bottom'**
  String get scrollDown;

  /// Debug: Creation timestamp
  ///
  /// In en, this message translates to:
  /// **'created at'**
  String get debugCreatedAt;

  /// Debug: Update timestamp
  ///
  /// In en, this message translates to:
  /// **'updated at'**
  String get debugUpdatedAt;

  /// Debug: Media duration
  ///
  /// In en, this message translates to:
  /// **'duration'**
  String get debugDuration;

  /// Debug: Current position
  ///
  /// In en, this message translates to:
  /// **'position'**
  String get debugPosition;

  /// Debug: Buffered amount
  ///
  /// In en, this message translates to:
  /// **'buffered'**
  String get debugBuffered;

  /// Debug: Buffering status
  ///
  /// In en, this message translates to:
  /// **'buffering'**
  String get debugBuffering;

  /// Debug: Volume level
  ///
  /// In en, this message translates to:
  /// **'volume'**
  String get debugVolume;

  /// Debug: Audio bitrate
  ///
  /// In en, this message translates to:
  /// **'audio bitrate'**
  String get debugAudioBitrate;

  /// Debug: Audio device
  ///
  /// In en, this message translates to:
  /// **'audio device'**
  String get debugAudioDevice;

  /// Debug: Video dimensions
  ///
  /// In en, this message translates to:
  /// **'size'**
  String get debugSize;

  /// Debug: Video parameters
  ///
  /// In en, this message translates to:
  /// **'video params'**
  String get debugVideoParams;

  /// Debug: Audio parameters
  ///
  /// In en, this message translates to:
  /// **'audio params'**
  String get debugAudioParams;

  /// Playback source
  ///
  /// In en, this message translates to:
  /// **'Playing from'**
  String get playingFrom;

  /// File size label
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get sizeLabel;

  /// Tooltip for copying video URL
  ///
  /// In en, this message translates to:
  /// **'Copy video URL to the clipboard'**
  String get copyVideoUrl;

  /// Tooltip for cleaning server content
  ///
  /// In en, this message translates to:
  /// **'Clean all downloaded content on the server'**
  String get cleanServerContent;

  /// Tooltip for cleaning device media
  ///
  /// In en, this message translates to:
  /// **'Clean all downloaded media from the device'**
  String get cleanDeviceMedia;

  /// Tooltip for refresh button
  ///
  /// In en, this message translates to:
  /// **'Refresh record (reread from the server)'**
  String get refreshRecord;

  /// Action to copy file link
  ///
  /// In en, this message translates to:
  /// **'Copy file link to clipboard'**
  String get copyFileLink;

  /// Action to copy curl command
  ///
  /// In en, this message translates to:
  /// **'Copy curl command to clipboard'**
  String get copyCurlCommand;

  /// Action to play with mpv
  ///
  /// In en, this message translates to:
  /// **'Play with embedded mpv player'**
  String get playEmbeddedMpv;

  /// Action to play with mpv flipped
  ///
  /// In en, this message translates to:
  /// **'Play with embedded mpv player with horizontal flip'**
  String get playEmbeddedMpvFlipped;

  /// Action to open in default app
  ///
  /// In en, this message translates to:
  /// **'Open in default application'**
  String get openDefaultApp;

  /// Action to delete server file
  ///
  /// In en, this message translates to:
  /// **'Delete file on the server and free server usage quota'**
  String get deleteServerFile;

  /// Menu item text
  ///
  /// In en, this message translates to:
  /// **'Share the download URL in...'**
  String get shareDownloadUrl;

  /// Snackbar text when copied to clipboard
  ///
  /// In en, this message translates to:
  /// **'{text} copied to clipboard'**
  String copiedToClipboard(String text);

  /// Preparing message
  ///
  /// In en, this message translates to:
  /// **'preparing...'**
  String get preparing;

  /// Acquiring info message
  ///
  /// In en, this message translates to:
  /// **'Acquiring info...'**
  String get acquiringInfo;

  /// Title for seek dialog
  ///
  /// In en, this message translates to:
  /// **'Seek to Position'**
  String get seekToPosition;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Seek button text
  ///
  /// In en, this message translates to:
  /// **'Seek'**
  String get seek;

  /// Error message for position exceeding duration
  ///
  /// In en, this message translates to:
  /// **'Position exceeds video duration'**
  String get positionExceedsDuration;

  /// Technical info about duration
  ///
  /// In en, this message translates to:
  /// **'duration'**
  String get duration_;

  /// Technical info about position
  ///
  /// In en, this message translates to:
  /// **'position'**
  String get position;

  /// Technical info about buffering
  ///
  /// In en, this message translates to:
  /// **'buffered'**
  String get buffered;

  /// Technical info about buffering process
  ///
  /// In en, this message translates to:
  /// **'buffering'**
  String get buffering;

  /// Technical info about volume
  ///
  /// In en, this message translates to:
  /// **'volume'**
  String get volume;

  /// Technical info about audio bitrate
  ///
  /// In en, this message translates to:
  /// **'audio bitrate'**
  String get audioBitrate;

  /// Technical info about audio device
  ///
  /// In en, this message translates to:
  /// **'audio device'**
  String get audioDevice;

  /// File or video size
  ///
  /// In en, this message translates to:
  /// **'size'**
  String get size;

  /// Technical info about video parameters
  ///
  /// In en, this message translates to:
  /// **'video params'**
  String get videoParams;

  /// Technical info about audio parameters
  ///
  /// In en, this message translates to:
  /// **'audio params'**
  String get audioParams;

  /// User blocked date
  ///
  /// In en, this message translates to:
  /// **'Blocked at {date}'**
  String blockedAt(String date);

  /// Unauthorized error message
  ///
  /// In en, this message translates to:
  /// **'Unauthorized: please check and specify token and server URL in settings'**
  String get unauthorized;

  /// No recordings message
  ///
  /// In en, this message translates to:
  /// **'No recordings. Check you filter settings or API token value.'**
  String get noRecordings;

  /// User profile tab title
  ///
  /// In en, this message translates to:
  /// **'User profile'**
  String get userProfile;

  /// Housekeeping tab title
  ///
  /// In en, this message translates to:
  /// **'Housekeeping'**
  String get housekeeping;

  /// Token input field label
  ///
  /// In en, this message translates to:
  /// **'Your token, provided by the bot'**
  String get yourTokenProvidedByBot;

  /// Server URL input field label
  ///
  /// In en, this message translates to:
  /// **'Server URL, provided by the bot'**
  String get serverUrlProvidedByBot;

  /// Theme selection dropdown label
  ///
  /// In en, this message translates to:
  /// **'Application color theme'**
  String get applicationColorTheme;

  /// Player speed selection dropdown label
  ///
  /// In en, this message translates to:
  /// **'Player speed rate'**
  String get playerSpeedRate;

  /// Media directory selection dropdown label
  ///
  /// In en, this message translates to:
  /// **'Media directory'**
  String get mediaDirectory;

  /// Confirmation message for deleting all media files
  ///
  /// In en, this message translates to:
  /// **'This will delete ALL downloaded media files'**
  String get deleteAllDownloadedMediaFiles;

  /// Confirmation message for deleting all metadata
  ///
  /// In en, this message translates to:
  /// **'This will delete ALL metadata for {count} recordings,\ndownloaded media files will be retained.\nThis data can be downloaded from the server.'**
  String deleteAllMetadataMessage(int count);

  /// Confirmation dialog text for server cleanup
  ///
  /// In en, this message translates to:
  /// **'Delete all files on the server?'**
  String get deleteAllFilesOnServer;

  /// Confirmation dialog text for device cleanup
  ///
  /// In en, this message translates to:
  /// **'Delete all local files on the device?'**
  String get deleteAllLocalFilesOnDevice;

  /// Continue button in dialogs
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// Tooltip for downloading format on server
  ///
  /// In en, this message translates to:
  /// **'Download this format and the best audio on the server (prepare for viewing)'**
  String get downloadThisFormatOnServer;

  /// Tooltip for copying URL fragment
  ///
  /// In en, this message translates to:
  /// **'Copy URL this fragment into clipboard'**
  String get copyUrlFragmentToClipboard;

  /// Best audio format option
  ///
  /// In en, this message translates to:
  /// **'Best audio (ba)'**
  String get bestAudio;

  /// Header for common available formats section
  ///
  /// In en, this message translates to:
  /// **'Common available formats:'**
  String get commonAvailableFormats;

  /// Header for the available formats section
  ///
  /// In en, this message translates to:
  /// **'Available formats:'**
  String get availableFormats;

  /// Tooltip for downloading exact format
  ///
  /// In en, this message translates to:
  /// **'Download exact this format (prepare this format for viewing)'**
  String get downloadExactFormat;

  /// Shows selected time position
  ///
  /// In en, this message translates to:
  /// **'Selected position: {position}'**
  String selectedPosition(String position);

  /// Error message when seek position is too long
  ///
  /// In en, this message translates to:
  /// **'Position exceeds video duration'**
  String get positionExceedsVideoDuration;

  /// Tooltip for cleaning server content
  ///
  /// In en, this message translates to:
  /// **'Clean all downloaded content on the server'**
  String get cleanAllDownloadedContentOnServer;

  /// Tooltip for cleaning device content
  ///
  /// In en, this message translates to:
  /// **'Clean all downloaded media from the device'**
  String get cleanAllDownloadedMediaFromDevice;

  /// Loading text for downloads
  ///
  /// In en, this message translates to:
  /// **'Downloads info is loading...'**
  String get downloadsInfoIsLoading;

  /// Tooltip for copying video URL
  ///
  /// In en, this message translates to:
  /// **'Copy video URL to the clipboard'**
  String get copyVideoUrlToClipboard;

  /// Tooltip for re-downloading format
  ///
  /// In en, this message translates to:
  /// **'Download this format again on the server (prepare for viewing)'**
  String get downloadThisFormatAgainOnServer;

  /// Tooltip for opening with MediaKit
  ///
  /// In en, this message translates to:
  /// **'Open with MediaKit with handler'**
  String get openWithMediaKitHandler;

  /// Menu item text
  ///
  /// In en, this message translates to:
  /// **'Play with embedded mpv player with horizontal flip'**
  String get playWithEmbeddedMpvPlayerWithHorizontalFlip;

  /// Tooltip for downloaded file
  ///
  /// In en, this message translates to:
  /// **'Local file is downloaded. Click to play.'**
  String get localFileDownloadedClickToPlay;

  /// Tooltip for download button
  ///
  /// In en, this message translates to:
  /// **'Download media to local storage'**
  String get downloadMediaToLocalStorage;

  /// Tooltip for mark as seen
  ///
  /// In en, this message translates to:
  /// **'Mark this recording as seen'**
  String get markRecordingAsSeen;

  /// Tooltip for mark as unseen
  ///
  /// In en, this message translates to:
  /// **'Mark this recording as unseen'**
  String get markRecordingAsUnseen;

  /// Files count and total size
  ///
  /// In en, this message translates to:
  /// **'Files: {number}, total size: {size}'**
  String filesWithSize(String number, String size);

  /// Button text for cleaning stale media
  ///
  /// In en, this message translates to:
  /// **'Clean stale downloaded media'**
  String get cleanStaleDownloadedMedia;

  /// Files cleaned message
  ///
  /// In en, this message translates to:
  /// **'{count} files, {size} cleaned'**
  String filesCleanedMessage(int count, String size);

  /// Button text for cleaning all media
  ///
  /// In en, this message translates to:
  /// **'Clean ALL downloaded media'**
  String get cleanAllDownloadedMedia;

  /// Button text for cleaning metadata
  ///
  /// In en, this message translates to:
  /// **'Clean ALL metadata for {count} recordings'**
  String cleanAllMetadataForRecordings(String count);

  /// Progress message when cleaning stale files
  ///
  /// In en, this message translates to:
  /// **'cleaning stale media local files...'**
  String get cleaningStaleMediaLocalFiles;

  /// Tooltip message for playing media
  ///
  /// In en, this message translates to:
  /// **'{filename} tap to play in embedding player'**
  String tapToPlayInEmbeddingPlayer(String filename);

  /// Message when there are no downloads
  ///
  /// In en, this message translates to:
  /// **'No downloads for recording'**
  String get noDownloadsForRecording;

  /// Header for downloads table
  ///
  /// In en, this message translates to:
  /// **'Files for this recording'**
  String get filesForThisRecording;

  /// Table header for format column
  ///
  /// In en, this message translates to:
  /// **'format'**
  String get formatHeader;

  /// Table header for resolution column
  ///
  /// In en, this message translates to:
  /// **'resolution'**
  String get resolutionHeader;

  /// Table header for fps column
  ///
  /// In en, this message translates to:
  /// **'fps'**
  String get fpsHeader;

  /// Table header for size column
  ///
  /// In en, this message translates to:
  /// **'size'**
  String get sizeHeader;

  /// ID column header
  ///
  /// In en, this message translates to:
  /// **'id'**
  String get id;

  /// URL column header
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get url;

  /// Extension column header
  ///
  /// In en, this message translates to:
  /// **'ext'**
  String get ext;

  /// Resolution column header
  ///
  /// In en, this message translates to:
  /// **'resolution'**
  String get resolution;

  /// FPS column header
  ///
  /// In en, this message translates to:
  /// **'fps'**
  String get fps;

  /// Format column header
  ///
  /// In en, this message translates to:
  /// **'format'**
  String get format;

  /// Preparing message with ellipsis
  ///
  /// In en, this message translates to:
  /// **'preparing...'**
  String get preparingEllipsis;

  /// Successfully added message
  ///
  /// In en, this message translates to:
  /// **'{title} successfully added'**
  String successfullyAddedMessage(String title);

  /// Adding URL message
  ///
  /// In en, this message translates to:
  /// **'Adding url {url}...'**
  String addingUrlWithVariable(String url);

  /// Created at with date and time ago
  ///
  /// In en, this message translates to:
  /// **'Created at: {date} ({timeAgo})'**
  String createdAtWithDate(String date, String timeAgo);

  /// Updated at with date and time ago
  ///
  /// In en, this message translates to:
  /// **'Updated at: {date} ({timeAgo})'**
  String updatedAtWithDate(String date, String timeAgo);

  /// Local downloading status with details
  ///
  /// In en, this message translates to:
  /// **'Local downloading {status}: {filename} {estimate}'**
  String localDownloadingStatus(
      String status, String filename, String estimate);

  /// Recordings cleaned message
  ///
  /// In en, this message translates to:
  /// **'{count} recordings cleaned'**
  String recordingsCleanedMessage(int count);

  /// Copied to clipboard message
  ///
  /// In en, this message translates to:
  /// **'{text} copied to clipboard'**
  String copiedToClipboardMessage(String text);

  /// Quota label with value
  ///
  /// In en, this message translates to:
  /// **'Quota: {quota}'**
  String quotaLabel(String quota);

  /// Used label with value
  ///
  /// In en, this message translates to:
  /// **'Used: {used}'**
  String usedLabel(String used);

  /// Free label with value
  ///
  /// In en, this message translates to:
  /// **'Free: {free}'**
  String freeLabel(String free);

  /// Files label with count
  ///
  /// In en, this message translates to:
  /// **'Files: {files}'**
  String filesLabel(int files);

  /// Local label with value
  ///
  /// In en, this message translates to:
  /// **'Local: {local}'**
  String localLabel(String local);

  /// Storage label with value
  ///
  /// In en, this message translates to:
  /// **'Storage: {storage}'**
  String storageLabel(String storage);

  /// Recordings label with count
  ///
  /// In en, this message translates to:
  /// **'Recordings: {recordings}'**
  String recordingsLabel(int recordings);

  /// Files count and total size label
  ///
  /// In en, this message translates to:
  /// **'Files: {count}, total size: {size}'**
  String filesTotalSizeLabel(int count, String size);

  /// Blocked at label with date
  ///
  /// In en, this message translates to:
  /// **'Blocked at {date}'**
  String blockedAtLabel(String date);

  /// Slow playback speed label
  ///
  /// In en, this message translates to:
  /// **'slow'**
  String get speedSlow;

  /// Normal playback speed label
  ///
  /// In en, this message translates to:
  /// **'normal'**
  String get speedNormal;

  /// Medium playback speed label
  ///
  /// In en, this message translates to:
  /// **'medium'**
  String get speedMedium;

  /// Fast playback speed label
  ///
  /// In en, this message translates to:
  /// **'fast'**
  String get speedFast;

  /// Very fast playback speed label
  ///
  /// In en, this message translates to:
  /// **'very fast'**
  String get speedVeryFast;

  /// Super fast playback speed label
  ///
  /// In en, this message translates to:
  /// **'super fast'**
  String get speedSuperFast;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
