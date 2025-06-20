import 'package:flutter/widgets.dart';

class PlayPauseIntent extends Intent {
  const PlayPauseIntent();
}

class BackIntent extends Intent {
  const BackIntent();
}

class RefreshIntent extends Intent {
  const RefreshIntent();
}

class NavigateHomeIntent extends Intent {
  const NavigateHomeIntent();
}

class NavigateEndIntent extends Intent {
  const NavigateEndIntent();
}

class ToggleSeenIntent extends Intent {
  const ToggleSeenIntent();
}

class ToggleHiddenIntent extends Intent {
  const ToggleHiddenIntent();
}

class ChangePositionIntent extends Intent {
  const ChangePositionIntent(this.duration);
  final Duration duration;
}

class ChangeVolumeIntent extends Intent {
  const ChangeVolumeIntent(this.change);
  final int change;
}
