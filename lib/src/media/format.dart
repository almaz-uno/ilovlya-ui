import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

var metrics = <String, int>{
  "Kb": 1024,
  "Mb": 1024 * 1024,
  "Gb": 1024 * 1024 * 1024,
  "Tb": 1024 * 1024 * 1024 * 1024,
};

String fileSizeHumanReadable(int size) {
  final sign = size < 0 ? -1 : 1;
  final ss = sign < 0 ? '-' : '';
  size = size * sign;
  for (var m in ["Tb", "Gb", "Mb", "Kb"]) {
    if (size >= metrics[m]!) {
      return "$ss${(size / metrics[m]!).toStringAsFixed(1)}$m";
    }
  }
  return "$ss${size}b";
}

String formatDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, "0");
  String hoursString = duration.inHours == 0 ? '' : "${duration.inHours}:";
  String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
  String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
  return "$hoursString$twoDigitMinutes:$twoDigitSeconds";
}

final _formatDate = DateFormat('yyyy-MM-dd');
final _formatDateLong = DateFormat('yyyy-MM-dd HH:mm');
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

String since(DateTime? dt, bool short, [String? locale]) {
  if (dt == null) {
    return "";
  }

  // Set locale if provided, otherwise use default (English)
  if (locale != null) {
    timeago.setLocaleMessages(locale, locale == 'ru' ? timeago.RuMessages() : timeago.EnMessages());
  }

  return timeago.format(dt, locale: locale);
}
