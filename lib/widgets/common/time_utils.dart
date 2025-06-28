import 'package:intl/intl.dart';

String formatTime(DateTime? time) {
  if (time == null) return "";
  final now = DateTime.now();
  final difference = now.difference(time);

    if (difference.inSeconds < 60) {
      return 'Vừa xong';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays == 1) {
      return 'Hôm qua';
    } else if (difference.inDays < 365 && time.year == now.year) {
      return DateFormat('dd/MM').format(time);
    } else {
      return DateFormat('dd/MM/yyyy').format(time);
    }
  // return "${time.hour}:${time.minute.toString().padLeft(2, '0')} ${time.day}/${time.month}";
}

bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
