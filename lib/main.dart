import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:fvp/fvp.dart';

import 'src/app.dart';
import 'src/media/media_kit/media_kit_audio_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // media_kit
  MediaKit.ensureInitialized();

  MKPlayerHandler.init();

  // fvp
  registerWith();

  runApp(const ProviderScope(child: MyApp()));
}
