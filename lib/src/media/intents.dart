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

class SelectPreviousIntent extends Intent {
  const SelectPreviousIntent();
}

class SelectNextIntent extends Intent {
  const SelectNextIntent();
}

class OpenSelectedIntent extends Intent {
  const OpenSelectedIntent();
}

class AddMediaIntent extends Intent {
  const AddMediaIntent();
}

class PasteMediaIntent extends Intent {
  const PasteMediaIntent();
}

class OpenSettingsIntent extends Intent {
  const OpenSettingsIntent();
}

class FocusMediaListIntent extends Intent {
  const FocusMediaListIntent();
}

class PlayRecordingIntent extends Intent {
  const PlayRecordingIntent();
}

class DownloadRecordingIntent extends Intent {
  const DownloadRecordingIntent();
}

class DeleteLocalRecordingIntent extends Intent {
  const DeleteLocalRecordingIntent();
}

class OpenInBrowserIntent extends Intent {
  const OpenInBrowserIntent();
}

class CastRecordingIntent extends Intent {
  const CastRecordingIntent();
}
