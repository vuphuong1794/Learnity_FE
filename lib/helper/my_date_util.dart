import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MyDateUtil {
  // for getting formatted time from milliSecondsSinceEpochs String
  static String getFormattedTime(
      {required BuildContext context, required String time}) {
    final date = DateTime.fromMillisecondsSinceEpoch(int.parse(time));
    final vietnamTime = date.toLocal();
    return DateFormat('HH:mm').format(vietnamTime); // 24h format
  }

  // // for getting formatted time for sent & read
  // static String getMessageTime(
  //     {required BuildContext context, required String time}) {

  //   final DateTime sent = DateTime.fromMillisecondsSinceEpoch(int.parse(time));
  //   final DateTime now = DateTime.now();

  //   final formattedTime = TimeOfDay.fromDateTime(sent).format(context);
  //   if (now.day == sent.day &&
  //       now.month == sent.month &&
  //       now.year == sent.year) {
  //     return formattedTime;
  //   }

  //   return now.year == sent.year
  //       ? '$formattedTime - ${sent.day} ${_getMonth(sent)}'
  //       : '$formattedTime - ${sent.day} ${_getMonth(sent)} ${sent.year}';
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
        ? '${sent.day} ${_getMonth(sent)}'
        : '${sent.day} ${_getMonth(sent)} ${sent.year}';

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
  static String getLastActiveTime(
      {required BuildContext context, required String lastActive}) {
    final int i = int.tryParse(lastActive) ?? -1;

    //if time is not available then return below statement
    if (i == -1) return 'Trạng thái không hợp lệ';

    DateTime time = DateTime.fromMillisecondsSinceEpoch(i);
    DateTime now = DateTime.now();

    String formattedTime = TimeOfDay.fromDateTime(time).format(context);
    if (time.day == now.day &&
        time.month == now.month &&
        time.year == time.year) {
      return 'Hoạt động lần cuối lúc $formattedTime';
    }

    if ((now.difference(time).inHours / 24).round() == 1) {
      return 'Hoạt động lần cuối hôm qua lúc $formattedTime';
    }

    String month = _getMonth(time);

    return 'Hoạt lần cuối cuối vào ${time.day}/${time.month} lúc $formattedTime';
  }

  // get month name from month no. or index
  static String _getMonth(DateTime date) {
    switch (date.month) {
      case 1:
        return 'Jan';
      case 2:
        return 'Feb';
      case 3:
        return 'Mar';
      case 4:
        return 'Apr';
      case 5:
        return 'May';
      case 6:
        return 'Jun';
      case 7:
        return 'Jul';
      case 8:
        return 'Aug';
      case 9:
        return 'Sept';
      case 10:
        return 'Oct';
      case 11:
        return 'Nov';
      case 12:
        return 'Dec';
    }
    return 'NA';
  }
}