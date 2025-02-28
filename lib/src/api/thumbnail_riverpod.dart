import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:http/http.dart' as http;

import 'api.dart';
import 'api_riverpod.dart';
import 'directories_riverpod.dart';
import 'exceptions.dart';

part 'thumbnail_riverpod.g.dart';

@riverpod
class ThumbnailDataNotifier extends _$ThumbnailDataNotifier {
  @override
  Future<Uint8List> build(String thumbnailUrl) async {
    return _getThumbnailFile();
  }

  Future<Uint8List> _getThumbnailFile() async {

    final uri = Uri.parse(thumbnailUrl);
    final fullpath = await _fullPath();
    if (!fullpath.existsSync()) {
      await _downloadThumbnail(uri, fullpath);
    }
    return fullpath.readAsBytes();
  }

  Future<void> _downloadThumbnail(Uri url, File target) async {
    final res = await http.get(url, headers: getAuthHeader(ref)).timeout(requestTimeoutLong);
    if (res.statusCode >= 400) {
      throw HttpStatusError.by("Unable to download thumbnail $url", res);
    }
    target.writeAsBytesSync(res.bodyBytes);
  }

  Future<void> updateThumbnailImg(Uint8List? thumbnailImg) async {
    if (thumbnailImg == null) {
      return;
    }
    final fullpath = await _fullPath();
    fullpath.writeAsBytesSync(thumbnailImg, flush: true);

    ref.invalidateSelf();
  }

  Future<File> _fullPath() async {
    final sp = await ref.watch(storePlacesProvider.future);
    final uri = Uri.parse(thumbnailUrl);
    final thumbnailFile = uri.pathSegments[uri.pathSegments.length - 2];
    return File(p.join(sp.thumbnails().path, thumbnailFile));
  }

  Future<Uri> getThumbnailUri() async {
    final fullpath = await _fullPath();
    if (fullpath.existsSync()) {
      return fullpath.uri;
    }
    return Uri.parse(thumbnailUrl);
  }
}
