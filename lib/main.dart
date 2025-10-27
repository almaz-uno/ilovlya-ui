import 'package:audio_session/audio_session.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';

import 'src/app.dart';
import 'src/media/media_kit/audio_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());

  // media_kit
  MediaKit.ensureInitialized();

  MKPlayerHandler.init();

  // Configure FileDownloader globally
  await FileDownloader().configure(
    globalConfig: [
      (Config.checkAvailableSpace, 200), // 200 MB minimum free space
    ],
  );

  runApp(const ProviderScope(child: MyApp()));
}

