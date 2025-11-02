import 'dart:io';
import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;

import '../../model/download.dart';
import '../../utils/logger_provider.dart';

/// Local HTTP proxy server that caches media files during streaming
///
/// This server intercepts media requests and either serves cached files
/// or proxies requests to the original server without starting downloads.
class CachingProxyServer {
  /// Timeout for remote server requests
  static const Duration _remoteServerTimeout = Duration(seconds: 30);

  HttpServer? _server;
  final String mediaDirectory;

  /// Port on which the server is running
  int get port => _server?.port ?? 0;

  /// Whether the server is running
  bool get isRunning => _server != null;

  CachingProxyServer({required this.mediaDirectory});

  /// Start the proxy server on localhost
  Future<void> start() async {
    if (_server != null) {
      AppLoggers.player.w('CachingProxyServer already running on port $port');
      return;
    }

    try {
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      AppLoggers.player.i('CachingProxyServer started: http://127.0.0.1:$port (port=$port)');

      _server!.listen(_handleRequest, onError: (error) {
        AppLoggers.player.e('CachingProxyServer error', error: error);
      });
    } catch (e, s) {
      AppLoggers.player.e('Failed to start CachingProxyServer', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Stop the proxy server
  Future<void> stop() async {
    if (_server == null) return;

    await _server!.close(force: true);
    _server = null;

    AppLoggers.player.i('CachingProxyServer stopped');
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

      // If final file exists, serve from it
      if (targetFile.existsSync()) {
        AppLoggers.player.d('Serving from cached file: ${targetFile.path}');
        await _serveFromFile(request, targetFile);
        return;
      }

      // File doesn't exist - proxy directly to server without starting download
      AppLoggers.player.d('File not cached, proxying to server: $filename');
      await _proxyToServer(request, originalUrl);

    } catch (e, s) {
      AppLoggers.player.e('Error handling proxy request', error: e, stackTrace: s);

      request.response.statusCode = HttpStatus.internalServerError;
      request.response.write('Internal server error');
      await request.response.close();
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
      AppLoggers.player.e('Error serving file', error: e);
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

      final serverResponse = await client.send(serverRequest).timeout(
        _remoteServerTimeout,
        onTimeout: () {
          throw TimeoutException(
            'Server request timeout after ${_remoteServerTimeout.inSeconds} seconds',
          );
        },
      );

      // Copy status code and headers
      request.response.statusCode = serverResponse.statusCode;

      serverResponse.headers.forEach((name, value) {
        request.response.headers.set(name, value);
      });

      // Stream response from server to client
      await request.response.addStream(serverResponse.stream);
      await request.response.close();

    } catch (e) {
      AppLoggers.player.e('Error proxying to server', error: e);
      request.response.statusCode = HttpStatus.badGateway;
      await request.response.close();
    }
  }
}
