import 'dart:io';

import 'package:open_filex/open_filex.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:path/path.dart' as p;

import 'logger_provider.dart';

/// Utility class for opening files in external applications
class FileOpener {
  /// Opens a local file in an external application
  ///
  /// Returns true if the file was opened successfully
  static Future<bool> openFile(String filePath) async {
    try {
      final result = await OpenFilex.open(filePath);

      AppLoggers.media.d('Opening file: $filePath, result: ${result.type}');

      switch (result.type) {
        case ResultType.done:
          return true;
        case ResultType.noAppToOpen:
          AppLoggers.media.w('No app found to open file: $filePath');
          return false;
        case ResultType.fileNotFound:
          AppLoggers.media.e('File not found: $filePath');
          return false;
        case ResultType.permissionDenied:
          AppLoggers.media.e('Permission denied to open file: $filePath');
          return false;
        case ResultType.error:
          AppLoggers.media.e('Error opening file: $filePath, message: ${result.message}');
          return false;
      }
    } catch (e, stackTrace) {
      AppLoggers.media.e('Exception opening file: $filePath', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Opens a file with MIME type hint
  static Future<bool> openFileWithType(String filePath, String mimeType) async {
    try {
      final result = await OpenFilex.open(
        filePath,
        type: mimeType,
      );

      AppLoggers.media.d('Opening file: $filePath with type: $mimeType, result: ${result.type}');
      return result.type == ResultType.done;
    } catch (e, stackTrace) {
      AppLoggers.media.e('Exception opening file with type', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Gets MIME type for common media files
  static String? getMimeType(String filePath) {
    final ext = filePath.split('.').last.toLowerCase();

    return switch (ext) {
      'mp3' || 'm4a' || 'aac' || 'wav' || 'flac' || 'ogg' => 'audio/*',
      'mp4' || 'mkv' || 'avi' || 'mov' || 'webm' || 'flv' => 'video/*',
      'jpg' || 'jpeg' || 'png' || 'gif' || 'webp' => 'image/*',
      'pdf' => 'application/pdf',
      'txt' => 'text/plain',
      _ => null,
    };
  }

  /// Opens the folder containing the file in the system file manager
  ///
  /// Returns true if the folder was opened successfully
  static Future<bool> openFileLocation(String filePath) async {
    try {
      final directory = p.dirname(filePath);

      AppLoggers.media.d('Opening file location: $directory');

      if (UniversalPlatform.isLinux) {
        // Use xdg-open to open the folder and select the file if possible
        final result = await Process.run('xdg-open', [directory]);
        return result.exitCode == 0;
      } else if (UniversalPlatform.isMacOS) {
        // Use open with -R flag to reveal file in Finder
        final result = await Process.run('open', ['-R', filePath]);
        return result.exitCode == 0;
      } else if (UniversalPlatform.isWindows) {
        // Use explorer with /select flag to select the file
        final result = await Process.run('explorer', ['/select,', filePath]);
        return result.exitCode == 0;
      } else if (UniversalPlatform.isAndroid) {
        // On Android, try to open the directory using a file manager
        // Note: This may not work on all devices/file managers
        // Some file managers don't support opening folders via Intent
        final result = await OpenFilex.open(directory);
        if (result.type == ResultType.done) {
          return true;
        }

        // Fallback: try to open the file itself
        AppLoggers.media.d('Opening directory failed, trying to open the file instead');
        final fileResult = await OpenFilex.open(filePath);
        return fileResult.type == ResultType.done;
      } else if (UniversalPlatform.isIOS) {
        // On iOS, we can't directly open a folder in Files app
        // Best we can do is open the file itself
        final result = await OpenFilex.open(filePath);
        return result.type == ResultType.done;
      }

      AppLoggers.media.w('Unsupported platform for opening file location');
      return false;
    } catch (e, stackTrace) {
      AppLoggers.media.e('Exception opening file location', error: e, stackTrace: stackTrace);
      return false;
    }
  }
}
