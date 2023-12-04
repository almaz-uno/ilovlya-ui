import 'package:duration/duration.dart';
import 'package:intl/intl.dart';

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

final _formatDate = DateFormat('yyyy-MM-dd');
final _formatDateLong = DateFormat('yyyy-MM-dd hh:mm');
String formatDate(DateTime? dt) {
  if (dt == null) {
    return "";
  }
  return _formatDate.format(dt.toLocal());
}

String formatDateLong(DateTime? dt) {
  if (dt == null) {
    return "";
  }
  return _formatDateLong.format(dt.toLocal());
}

String since(DateTime? dt, bool short) {
  if (dt == null) {
    return "";
  }
  final dura = DateTime.now().difference(dt);

  var tersity = DurationTersity.hour;

  if (dura < const Duration(days: 1)) {
    tersity = DurationTersity.minute;
  }

  if (dura < const Duration(hours: 1)) {
    tersity = DurationTersity.second;
  }

  return short ? prettyDuration(dura, tersity: tersity, abbreviated: true, delimiter: ' ', spacer: '') : prettyDuration(dura, tersity: tersity, abbreviated: false);
}
