import 'package:flutter/widgets.dart';

class PlayPauseIntent extends Intent {
  const PlayPauseIntent();
}

class BackIntent extends Intent {
  const BackIntent();
}

class ChangePositionIntent extends Intent {
  const ChangePositionIntent(this.duration);
  final Duration duration;
}

class ChangeVolumeIntent extends Intent {
  const ChangeVolumeIntent(this.change);
  final int change;
}
