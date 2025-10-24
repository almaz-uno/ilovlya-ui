import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;

import '../../model/download.dart';

/// Maximum number of retry attempts for failed downloads
const int _maxRetryAttempts = 5;

/// Initial delay in milliseconds before first retry
const int _initialRetryDelayMs = 1000;

/// Minimum bytes between progress updates (5 MB)
const int _progressUpdateThreshold = 5 * 1024 * 1024;

/// Local HTTP proxy server that caches media files during streaming
///
/// This server intercepts media requests, downloads content to cache,
/// and serves it to MPV player while supporting Range requests for seeking.
class CachingProxyServer {
  HttpServer? _server;
  final String mediaDirectory;

  /// Maps download ID to active download info
  final Map<String, _ActiveDownload> _activeDownloads = {};

  /// Stream controller for download progress updates
  /// Map format: {downloadId: {downloaded: bytes, total: bytes}}
  final _progressController = StreamController<Map<String, Map<String, int>>>.broadcast();

  /// Port on which the server is running
  int get port => _server?.port ?? 0;

  /// Whether the server is running
  bool get isRunning => _server != null;

  /// Get stream of download progress updates
  Stream<Map<String, Map<String, int>>> get progressStream => _progressController.stream;

  CachingProxyServer({required this.mediaDirectory});

  /// Start the proxy server on localhost
  Future<void> start() async {
    if (_server != null) {
      debugPrint('CachingProxyServer already running on port $port');
      return;
    }

    try {
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      debugPrint('CachingProxyServer started on http://127.0.0.1:$port');

      _server!.listen(_handleRequest, onError: (error) {
        debugPrint('CachingProxyServer error: $error');
      });
    } catch (e, s) {
      debugPrint('Failed to start CachingProxyServer: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  /// Stop the proxy server
  Future<void> stop() async {
    if (_server == null) return;

    // Cancel all active downloads
    for (final download in _activeDownloads.values) {
      await download.cancel();
    }
    _activeDownloads.clear();

    await _server!.close(force: true);
    _server = null;

    await _progressController.close();

    debugPrint('CachingProxyServer stopped');
  }

  /// Get proxied URL for a download
  ///
  /// Format: http://127.0.0.1:PORT/?url=<original-url>&id=<download-id>&filename=<filename>
  String getProxiedUrl(Download download) {
    if (!isRunning) {
      throw StateError('CachingProxyServer is not running');
    }

    final params = {
      'url': download.url,
      'id': download.id,
      'filename': download.filename,
    };

    final query = params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return 'http://127.0.0.1:$port/?$query';
  }

  /// Handles incoming HTTP requests
  Future<void> _handleRequest(HttpRequest request) async {
    try {
      final uri = request.uri;
      final originalUrl = uri.queryParameters['url'];
      final downloadId = uri.queryParameters['id'];
      final filename = uri.queryParameters['filename'];

      if (originalUrl == null || downloadId == null || filename == null) {
        request.response.statusCode = HttpStatus.badRequest;
        request.response.write('Missing required parameters: url, id, filename');
        await request.response.close();
        return;
      }

      final targetFile = File(p.join(mediaDirectory, filename));
      final partFile = File('${targetFile.path}.part');

      // If final file exists, serve from it
      if (targetFile.existsSync()) {
        await _serveFromFile(request, targetFile);
        return;
      }

      // Check if download is already in progress
      var activeDownload = _activeDownloads[downloadId];

      if (activeDownload == null) {
        // Start new download in background
        activeDownload = _ActiveDownload(
          url: originalUrl,
          partFile: partFile,
          targetFile: targetFile,
          onProgress: (downloaded, total) {
            // Emit progress update
            _progressController.add({
              downloadId: {
                'downloaded': downloaded,
                'total': total,
              },
            });
          },
        );
        _activeDownloads[downloadId] = activeDownload;

        unawaited(_startDownloadWithRetry(activeDownload, downloadId, filename));
      }

      // While downloading, proxy directly to server
      await _proxyToServer(request, originalUrl);

    } catch (e, s) {
      debugPrint('Error handling request: $e');
      debugPrintStack(stackTrace: s);

      request.response.statusCode = HttpStatus.internalServerError;
      request.response.write('Internal server error');
      await request.response.close();
    }
  }

  /// Start download with retry logic
  Future<void> _startDownloadWithRetry(
    _ActiveDownload activeDownload,
    String downloadId,
    String filename,
  ) async {
    int attempt = 0;

    while (attempt < _maxRetryAttempts) {
      try {
        await activeDownload.start();
        _activeDownloads.remove(downloadId);
        debugPrint('Download completed and finalized: $filename');
        return;
      } catch (error) {
        attempt++;

        if (attempt >= _maxRetryAttempts) {
          debugPrint('Download failed for $downloadId after $attempt attempts: $error');
          _activeDownloads.remove(downloadId);
          return;
        }

        // Exponential backoff: 1s, 2s, 4s, 8s, 16s
        final delayMs = _initialRetryDelayMs * (1 << (attempt - 1));
        debugPrint('Download failed for $downloadId (attempt $attempt/$_maxRetryAttempts), retrying in ${delayMs}ms: $error');

        await Future.delayed(Duration(milliseconds: delayMs));

        // Reset the download state before retry
        await activeDownload.reset();
      }
    }
  }

  /// Serve content from a complete file
  Future<void> _serveFromFile(HttpRequest request, File file) async {
    try {
      final fileSize = await file.length();
      final range = request.headers.value('range');

      if (range != null) {
        // Handle Range request
        final match = RegExp(r'bytes=(\d+)-(\d*)').firstMatch(range);
        if (match != null) {
          final start = int.parse(match.group(1)!);
          final end = match.group(2)!.isEmpty ? fileSize - 1 : int.parse(match.group(2)!);

          request.response.statusCode = HttpStatus.partialContent;
          request.response.headers.set('Content-Range', 'bytes $start-$end/$fileSize');
          request.response.headers.set('Content-Length', end - start + 1);
          request.response.headers.set('Accept-Ranges', 'bytes');
          request.response.headers.set('Content-Type', 'video/mp4');

          await request.response.addStream(file.openRead(start, end + 1));
        }
      } else {
        // Serve full file
        request.response.statusCode = HttpStatus.ok;
        request.response.headers.set('Content-Length', fileSize);
        request.response.headers.set('Accept-Ranges', 'bytes');
        request.response.headers.set('Content-Type', 'video/mp4');

        await request.response.addStream(file.openRead());
      }

      await request.response.close();
    } catch (e) {
      debugPrint('Error serving file: $e');
      request.response.statusCode = HttpStatus.internalServerError;
      await request.response.close();
    }
  }

  /// Proxy request directly to server
  Future<void> _proxyToServer(HttpRequest request, String url) async {
    try {
      final client = http.Client();
      final range = request.headers.value('range');

      final serverRequest = http.Request('GET', Uri.parse(url));
      if (range != null) {
        serverRequest.headers['range'] = range;
      }

      final serverResponse = await client.send(serverRequest);

      // Copy status code and headers
      request.response.statusCode = serverResponse.statusCode;

      serverResponse.headers.forEach((name, value) {
        request.response.headers.set(name, value);
      });

      // Stream response from server to client
      await request.response.addStream(serverResponse.stream);
      await request.response.close();

    } catch (e) {
      debugPrint('Error proxying to server: $e');
      request.response.statusCode = HttpStatus.badGateway;
      await request.response.close();
    }
  }
}

/// Represents an active download
class _ActiveDownload {
  final String url;
  final File partFile;
  final File targetFile;
  final Function(int downloaded, int total)? onProgress;

  http.StreamedResponse? _response;
  IOSink? _sink;
  int _downloadedBytes = 0;
  int _totalBytes = 0;
  int _lastProgressUpdate = 0;
  final _completer = Completer<void>();

  _ActiveDownload({
    required this.url,
    required this.partFile,
    required this.targetFile,
    this.onProgress,
  });

  /// Start downloading the file
  Future<void> start() async {
    try {
      debugPrint('Starting download: $url -> ${partFile.path}');

      // Ensure directory exists
      await partFile.parent.create(recursive: true);

      // Start HTTP request
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(url));
      _response = await client.send(request);

      if (_response!.statusCode != HttpStatus.ok) {
        throw HttpException('Failed to download: ${_response!.statusCode}');
      }

      // Get total size from Content-Length header
      _totalBytes = _response!.contentLength ?? 0;

      // Open file for writing
      _sink = partFile.openWrite();

      // Stream to file
      await for (final chunk in _response!.stream) {
        _sink!.add(chunk);
        _downloadedBytes += chunk.length;

        // Notify progress only every 5MB or on first update
        if (_downloadedBytes - _lastProgressUpdate >= _progressUpdateThreshold || _lastProgressUpdate == 0) {
          onProgress?.call(_downloadedBytes, _totalBytes);
          _lastProgressUpdate = _downloadedBytes;
        }
      }

      await _sink!.flush();
      await _sink!.close();
      _sink = null;

      // Final progress update to ensure 100% is shown
      if (_lastProgressUpdate != _downloadedBytes) {
        onProgress?.call(_downloadedBytes, _totalBytes);
      }

      // Finalize: rename .part to final file
      await partFile.rename(targetFile.path);
      _completer.complete();

      debugPrint('Download completed: ${targetFile.path} ($_downloadedBytes bytes)');

    } catch (e, s) {
      debugPrint('Download error: $e');
      debugPrintStack(stackTrace: s);

      await _sink?.close();
      _sink = null;

      // Clean up partial file on error
      if (partFile.existsSync()) {
        partFile.deleteSync();
      }

      _completer.completeError(e);
      rethrow;
    }
  }

  /// Cancel the download
  Future<void> cancel() async {
    await _sink?.close();
    _sink = null;

    if (partFile.existsSync()) {
      partFile.deleteSync();
    }
  }

  /// Reset download state for retry
  Future<void> reset() async {
    await _sink?.close();
    _sink = null;
    _downloadedBytes = 0;
    _lastProgressUpdate = 0;
    _response = null;

    // Clean up partial file
    if (partFile.existsSync()) {
      partFile.deleteSync();
    }
  }
}
