import 'package:intl/intl.dart';

String formatMessageTime(DateTime time) {
  final now = DateTime.now();
  if (now.difference(time).inDays > 0) {
    return '${now.difference(time).inDays}d ago';
  } else if (now.difference(time).inHours > 0) {
    return '${now.difference(time).inHours}h ago';
  } else if (now.difference(time).inMinutes > 0) {
    return '${now.difference(time).inMinutes}m ago';
  }
  return 'Just now';
}

String formatTime12Hr(DateTime time) {
  return DateFormat('hh:mm a').format(time);
}
