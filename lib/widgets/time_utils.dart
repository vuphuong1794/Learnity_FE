String formatTime(DateTime? time) {
  if (time == null) return "";
  final now = DateTime.now();
  final diff = now.difference(time);

  if (diff.inMinutes < 1) return "Vừa xong";
  if (diff.inMinutes < 60) return "${diff.inMinutes} phút trước";
  if (diff.inHours < 24) return "${diff.inHours} giờ trước";
  return "${time.hour}:${time.minute.toString().padLeft(2, '0')} ${time.day}/${time.month}";
}
