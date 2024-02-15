import 'dart:io';

import 'package:flutter/material.dart';
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
  Future<File> build(String thumbnailUrl) async {
    return _getThumbnailFile();
  }

  Future<File> _getThumbnailFile() async {
    final sp = await ref.watch(storePlacesProvider.future);

    final uri = Uri.parse(thumbnailUrl);
    final thumbnailFile = uri.pathSegments[uri.pathSegments.length - 2];
    final fullpath = File(p.join(sp.thumbnails().path, thumbnailFile));
    if (!fullpath.existsSync()) {
      await _downloadThumbnail(uri, fullpath);
    }
    return Future.value(fullpath);
  }

  Future<void> _downloadThumbnail(Uri url, File target) async {
    final res = await http.get(url, headers: getAuthHeader(ref)).timeout(requestTimeoutLong);
    if (res.statusCode >= 400) {
      throw HttpStatusError.by("Unable to download thumbnail $url", res);
    }
    target.writeAsBytesSync(res.bodyBytes);
  }
}
