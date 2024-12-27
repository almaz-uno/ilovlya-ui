import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:universal_platform/universal_platform.dart';
part 'directories_riverpod.g.dart';

const _desktopDir = "ilovlya";

class StorePlaces {
  final Directory _dataDir;
  final Directory _mediaDir;

  Directory recordings() {
    return Directory(p.join(_dataDir.path, "recordings"))..createSync(recursive: true);
  }

  Directory downloads() {
    return Directory(p.join(_dataDir.path, "downloads"))..createSync(recursive: true);
  }

  Directory thumbnails() {
    return Directory(p.join(_dataDir.path, "thumbnails"))..createSync(recursive: true);
  }

  Directory media() {
    return _mediaDir;
  }

  Directory data() {
    return _dataDir;
  }

  StorePlaces(
    Directory documentsDir,
  )   : _dataDir = Directory(p.join(documentsDir.path, "data")),
        _mediaDir = Directory(p.join(documentsDir.path, "media")) {
    _dataDir.createSync(recursive: true);
    _mediaDir.createSync(recursive: true);
  }
}

@riverpod
Future<StorePlaces> storePlaces(StorePlacesRef ref) async {
  final dd = await getApplicationDocumentsDirectory();
  if (UniversalPlatform.isDesktop) {
    return StorePlaces(Directory(p.join(dd.path, _desktopDir)));
  }
  return StorePlaces(dd);
}
