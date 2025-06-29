import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MyDateUtil {
  // for getting formatted time from milliSecondsSinceEpochs String
  // static String getFormattedTime(
  //     {required BuildContext context, required String time}) {
  //   final date = DateTime.fromMillisecondsSinceEpoch(int.parse(time));
  //   final vietnamTime = date.toLocal();
  //   return DateFormat('HH:mm').format(vietnamTime); // 24h format
  // }

  // for getting formatted time for sent & read
  // [Bux Fix] Avoid bug due to context not mounted when keyboard is open in chat & bottom sheet opens
  static String getMessageTime({required String time}) {
    final DateTime sent = DateTime.fromMillisecondsSinceEpoch(int.parse(time));
    final DateTime now = DateTime.now();

    final String formattedTime = DateFormat('hh:mm').format(sent);

    if (now.day == sent.day &&
        now.month == sent.month &&
        now.year == sent.year) {
      return formattedTime;
    }

    final String formattedDate = now.year == sent.year
        ? '${sent.day}/${sent}'
        : '${sent.day}/${sent}/${sent.year}';

    return '$formattedTime - $formattedDate';
  }

  //get last message time (used in chat user card)
  static String getLastMessageTime({
    required BuildContext context,
    required String time,
    bool showYear = false,
  }) {
    try {
      final DateTime sent = DateTime.fromMillisecondsSinceEpoch(int.parse(time));
      final now = DateTime.now();
      final difference = now.difference(sent);

      if (difference.inSeconds < 60) {
        return 'Vừa xong';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} phút trước';
      } else if (difference.inHours < 24 && now.day == sent.day) {
        return '${difference.inHours} giờ trước';
      } else if (difference.inDays == 1 ||
          (now.day - sent.day == 1 && now.month == sent.month)) {
        return 'Hôm qua';
      } else if (!showYear && now.year == sent.year) {
        return DateFormat('dd/MM').format(sent); // vd: 01/06
      } else {
        return DateFormat('dd/MM/yyyy').format(sent); // vd: 01/06/2025
      }
    } catch (e) {
      debugPrint("Error in getLastMessageTime: $e");
      return '';
    }
  }


  //get formatted last active time of user in chat screen
  static String getLastActiveTime({
    required BuildContext context,
    required DateTime lastActive,
  }) {
    if (lastActive == DateTime(0)) return 'Trạng thái không hợp lệ';

    final now = DateTime.now();
    final difference = now.difference(lastActive);

    if (difference.inSeconds < 60) {
      return 'Hoạt động vài giây trước';
    } else if (difference.inMinutes < 60) {
      return 'Hoạt động ${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return 'Hoạt động ${difference.inHours} giờ trước';
    } else {
      return ''; // Hơn 24 giờ -> không hiển thị
    }
  }

  static String getFormattedDateTimeWithDateTime(DateTime currentTime) {
    return "${currentTime.hour.toString().padLeft(2, '0')}:${currentTime.minute.toString().padLeft(2, '0')} ${currentTime.day.toString().padLeft(2, '0')}/${currentTime.month.toString().padLeft(2, '0')}/${currentTime.year}";
  }

  static String getFormattedTimeWithDateTime(DateTime currentTime) {
    return "${currentTime.hour.toString().padLeft(2, '0')}:${currentTime.minute.toString().padLeft(2, '0')}";
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}