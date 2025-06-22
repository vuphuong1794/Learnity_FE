import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:gallery_saver_plus/files.dart';
import 'package:http/http.dart' as http;

class Notification_API {
  static Future<void> sendFollowNotification(
    String senderName,
    String receiverId,
  ) async {
    print('Gửi thông báo theo dõi từ $senderName đến $receiverId');

    // Lấy FCM token của người nhận
    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(receiverId)
            .get();
    final deviceId = userDoc.data()?['fcmTokens'];

    if (deviceId == null || deviceId.isEmpty) {
      print('FCM token của người nhận không tồn tại');
      return;
    }

    const apiUrl = 'http://192.168.1.6:3000/notification';

    final body = {
      'title': 'Bạn có người theo dõi mới!',
      'body': '$senderName vừa theo dõi bạn.',
      'deviceId': deviceId,
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        print('Gửi thông báo thất bại: ${response.body}');
      }
    } catch (e) {
      print('Lỗi khi gửi thông báo: $e');
    }
  }

  static Future<void> saveFollowNotificationToFirestore({
    required String receiverId,
    required String senderId,
    required String senderName,
  }) async {
    final notificationData = {
      'receiverId': receiverId,
      'senderId': senderId,
      'senderName': senderName,
      'type': 'follow',
      'message': '$senderName vừa theo dõi bạn.',
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false, // tuỳ bạn xử lý đã đọc/chưa đọc
    };

    await FirebaseFirestore.instance
        .collection('notifications')
        .add(notificationData);
  }

  static Future<void> sendInviteMemberNotification(
    String senderName,
    String receiverId,
    String groupId,
    String groupName,
  ) async {
    print('Gửi thông báo tham gia nhóm từ $senderName đến $receiverId');

    // Lấy FCM token của người nhận
    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(receiverId)
            .get();
    final deviceId = userDoc.data()?['fcmTokens'];

    if (deviceId == null || deviceId.isEmpty) {
      print('FCM token của người nhận không tồn tại');
      return;
    }

    const apiUrl = 'http://192.168.1.6:3000/notification';

    final body = {
      'title': 'Bạn có lời mời tham gia nhóm mới!',
      'body': '$senderName đã mời bạn tham gia nhóm.',
      'deviceId': deviceId,
      'groupId': groupId,
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        print('Gửi thông báo thất bại: ${response.body}');
      }
    } catch (e) {
      print('Lỗi khi gửi thông báo: $e');
    }
  }

  static Future<void> saveInviteMemberNotificationToFirestore({
    required String receiverId,
    required String senderId,
    required String senderName,
    required String groupId,
    required String groupName,
  }) async {
    final notificationData = {
      'receiverId': receiverId,
      'senderId': senderId,
      'senderName': senderName,
      'type': 'invite_member',
      'message': '$senderName đã mời bạn tham gia nhóm.',
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false, // tuỳ bạn xử lý đã đọc/chưa đọc
      'groupId': groupId,
      'groupName': groupName,
    };

    await FirebaseFirestore.instance
        .collection('invite_member_notifications')
        .add(notificationData);
  }
}
