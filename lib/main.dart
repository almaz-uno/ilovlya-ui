import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ilovlya/src/media/media_kit/media_kit_audio_handler.dart';
import 'package:media_kit/media_kit.dart';

import 'src/app.dart';
import 'package:fvp/fvp.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // media_kit
  MediaKit.ensureInitialized();

  MKPlayerHandler.init();

  // fvp
  registerWith();

  runApp(const ProviderScope(child: MyApp()));
}
