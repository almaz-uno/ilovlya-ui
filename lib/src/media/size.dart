var metrics = <String, int>{
  "Kb": 1024,
  "Mb": 1024 * 1024,
  "Gb": 1024 * 1024 * 1024,
  "Tb": 1024 * 1024 * 1024 * 1024,
};

String fileSizeHumanReadable(int size) {
  for (var m in ["Tb", "Gb", "Mb", "Kb"]) {
    if (size >= metrics[m]!) {
      return "${(size / metrics[m]!).toStringAsFixed(2)}$m";
    }
  }
  return "${size}b";
}
