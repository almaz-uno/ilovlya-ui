var metrics = <String, int>{
  "Kb": 1024,
  "Mb": 1024 * 1024,
  "Gb": 1024 * 1024 * 1024,
  "Tb": 1024 * 1024 * 1024 * 1024,
};

String fileSizeHumanReadable(int size) {
  for (var m in ["Tb", "Gb", "Mb", "Kb"]) {
    if (size >= metrics[m]!) {
      return "${(size / metrics[m]!).toStringAsFixed(1)}$m";
    }
  }
  return "${size}b";
}

String formatDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, "0");
  String hoursString = duration.inHours == 0 ? '' : "${duration.inHours}:";
  String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
  String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
  return "$hoursString$twoDigitMinutes:$twoDigitSeconds";
}
