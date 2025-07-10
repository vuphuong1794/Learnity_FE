import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:learnity/config.dart';
import 'package:learnity/enum/message_type.dart';
import 'package:learnity/models/app_user.dart';

class Notification_API {
  // for authentication
  static FirebaseAuth get auth => FirebaseAuth.instance;
    // for storing self information
  static AppUser me = AppUser(
    id: user.uid,
    name: user.displayName.toString(),
    email: user.email.toString(),
    bio: "Hey, I'm using We Chat!",
    avatarUrl: user.photoURL.toString(),
    createdAt: DateTime.now(),
    isOnline: false,
    lastActive: DateTime.now(),
  );

  // to return current user
  static User get user => auth.currentUser!;

  static final String notificationApiUrl =
      '${Config.apiUrl}/notification';
  static String _truncateText(String text, {int length = 30}) {
    if (text.length <= length) {
      return text;
    }
    return '${text.substring(0, length)}...';
  }

  // Outside app
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

    final body = {
      'title': 'Bạn có người theo dõi mới!',
      'body': '$senderName vừa theo dõi bạn.',
      'deviceId': deviceId,
    };

    try {
      final response = await http.post(
        Uri.parse(notificationApiUrl),
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

  static Future<void> sendChatNotification(
    String senderName,
    String receiverId,
    String msg,
    MessageType msgType,
  ) async {
    print('Gửi thông báo tin nhắn từ $senderName đến $receiverId');

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(receiverId)
          .get();

      if (!userDoc.exists) {
        print('Tài khoản người nhận không tồn tại.');
        return;
      }

      final deviceId = userDoc.data()?['fcmTokens'];
      if (deviceId == null || deviceId.isEmpty) {
        print('FCM token của người nhận không tồn tại');
        return;
      }

      final Map<String, dynamic> body = {
        'title': 'Tin nhắn mới!',
        'body': msgType == MessageType.text
            ? '$senderName: $msg'
            : '$senderName đã gửi hình ảnh',
        'deviceId': deviceId,
      };

      final response = await http.post(
        Uri.parse(notificationApiUrl),
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

  static Future<void> sendGroupChatNotification(
    String senderName,
    String groupId,
    String msg,
    MessageType msgType,
  ) async {
    print('Gửi thông báo tin nhắn từ $senderName đến $groupId');

    try {
      final groupDoc = await FirebaseFirestore.instance
          .collection('groupChats')
          .doc(groupId)
          .get();

      final members = groupDoc.data()?['members'] as List<dynamic>?;

      if (members == null) {
        print('Không có thành viên trong nhóm');
        return;
      }

      final memberUids = members
          .map((member) => member['uid'] as String)
          .toList();

      print('Danh sách UID: $memberUids');
      
      final fcmTokens = await getAllFcmTokensFromUserIds(memberUids);

      final Map<String, dynamic> body = {
        'title': 'Tin nhắn mới từ nhóm $groupId!',
        'body': msgType == MessageType.text
            ? '$senderName: $msg'
            : '$senderName đã gửi hình ảnh',
        'deviceId': fcmTokens,
      };

      final response = await http.post(
        Uri.parse(notificationApiUrl),
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

  static Future<List<String>> getAllFcmTokensFromUserIds(List<String> userIds) async {
    final List<String> allTokens = [];

    if (userIds.isEmpty) return allTokens;

    final filteredUserIds = userIds.where((id) => id != me.id).toList();

  if (filteredUserIds.isEmpty) return allTokens;

    // Lấy tất cả document theo uid
    final userDocs = await FirebaseFirestore.instance
        .collection('users')
        .where(FieldPath.documentId, whereIn: userIds)
        .get();

    for (final doc in userDocs.docs) {
      final tokens = doc.data()['fcmTokens'];

      if (tokens != null && tokens is List) {
        allTokens.addAll(
          tokens.whereType<String>(), // lọc các phần tử dạng String
        );
      }
    }

    return allTokens;
  }

  // Inside app
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

    final body = {
      'title': 'Bạn có lời mời tham gia nhóm mới!',
      'body': '$senderName đã mời bạn tham gia nhóm.',
      'deviceId': deviceId,
      'groupId': groupId,
    };

    try {
      final response = await http.post(
        Uri.parse(notificationApiUrl),
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

  static Future<void> sendMessageNotification(
    String senderName,
    String receiverId,
  ) async {
    print('Gửi thông báo tin nhắn từ $senderName đến $receiverId');

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

    final body = {
      'title': 'Bạn có tin nhắn mới!',
      'body': '$senderName gửi bạn tin nhắn mới.',
      'deviceId': deviceId,
    };

    try {
      final response = await http.post(
        Uri.parse(notificationApiUrl),
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

  static Future<void> saveMessageNotificationToFirestore({
    required String receiverId,
    required String senderId,
    required String senderName,
  }) async {
    final notificationData = {
      'receiverId': receiverId,
      'senderId': senderId,
      'senderName': senderName,
      'type': 'follow',
      'message': '$senderName gửi tin đến bạn.',
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false, // tuỳ bạn xử lý đã đọc/chưa đọc
    };

    await FirebaseFirestore.instance
        .collection('notifications')
        .add(notificationData);
  }

  static Future<void> sendLikeNotification(
    String senderName,
    String receiverId,
    String postContent,
    String postId,
  ) async {
    if (senderName.isEmpty || receiverId.isEmpty) return;
    print('Gửi thông báo lượt thích từ $senderName đến $receiverId');

    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(receiverId)
            .get();
    final deviceId = userDoc.data()?['fcmTokens'];

    if (deviceId == null || deviceId.isEmpty) return;

    final body = {
      'title': 'Bài viết của bạn có lượt thích mới!',
      'body':
          '$senderName đã thích bài viết của bạn: "${_truncateText(postContent)}"',
      'deviceId': deviceId,
      'data': {'type': 'like', 'postId': postId},
    };

    try {
      await http.post(
        Uri.parse(notificationApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
    } catch (e) {
      print('Lỗi khi gửi thông báo lượt thích: $e');
    }
  }

  static Future<void> saveLikeNotificationToFirestore({
    required String receiverId,
    required String senderId,
    required String senderName,
    required String postId,
    required String postContent,
  }) async {
    final notificationData = {
      'receiverId': receiverId,
      'senderId': senderId,
      'senderName': senderName,
      'type': 'like',
      'message':
          '$senderName đã thích bài viết của bạn: "${_truncateText(postContent)}"',
      'postId': postId,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    };
    await FirebaseFirestore.instance
        .collection('notifications')
        .add(notificationData);
  }

  static Future<void> sendCommentNotification(
    String senderName,
    String receiverId,
    String commentText,
    String postId,
  ) async {
    if (senderName.isEmpty || receiverId.isEmpty) return;
    print('Gửi thông báo bình luận từ $senderName đến $receiverId');

    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(receiverId)
            .get();
    final deviceId = userDoc.data()?['fcmTokens'];

    if (deviceId == null || deviceId.isEmpty) return;

    final body = {
      'title': 'Bài viết của bạn có bình luận mới!',
      'body': '$senderName đã bình luận: "${_truncateText(commentText)}"',
      'deviceId': deviceId,
      'data': {'type': 'comment', 'postId': postId},
    };

    try {
      await http.post(
        Uri.parse(notificationApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
    } catch (e) {
      print('Lỗi khi gửi thông báo bình luận: $e');
    }
  }

  static Future<void> saveCommentNotificationToFirestore({
    required String receiverId,
    required String senderId,
    required String senderName,
    required String postId,
    required String commentText,
  }) async {
    final notificationData = {
      'receiverId': receiverId,
      'senderId': senderId,
      'senderName': senderName,
      'type': 'comment',
      'message': '$senderName đã bình luận: "${_truncateText(commentText)}"',
      'postId': postId,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    };
    await FirebaseFirestore.instance
        .collection('notifications')
        .add(notificationData);
  }

  static Future<void> sendShareNotification(
    String senderName,
    String receiverId,
    String postContent,
    String postId,
  ) async {
    if (senderName.isEmpty || receiverId.isEmpty) return;
    print('Gửi thông báo chia sẻ từ $senderName đến $receiverId');

    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(receiverId)
            .get();
    final deviceId = userDoc.data()?['fcmTokens'];

    if (deviceId == null || deviceId.isEmpty) return;

    final body = {
      'title': 'Bài viết của bạn đã được chia sẻ!',
      'body':
          '$senderName đã chia sẻ bài viết của bạn: "${_truncateText(postContent)}"',
      'deviceId': deviceId,
      'data': {'type': 'share', 'postId': postId},
    };

    try {
      await http.post(
        Uri.parse(notificationApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
    } catch (e) {
      print('Lỗi khi gửi thông báo chia sẻ: $e');
    }
  }

  static Future<void> saveShareNotificationToFirestore({
    required String receiverId,
    required String senderId,
    required String senderName,
    required String postId,
    required String postContent,
  }) async {
    final notificationData = {
      'receiverId': receiverId,
      'senderId': senderId,
      'senderName': senderName,
      'type': 'share',
      'message':
          '$senderName đã chia sẻ bài viết của bạn: "${_truncateText(postContent)}"',
      'postId': postId,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    };
    await FirebaseFirestore.instance
        .collection('notifications')
        .add(notificationData);
  }

  // static Future<void> sendMessageNotification({
  //   required String senderName,
  //   required String receiverId,
  //   required String message,
  // }) async {
  //   print('Gửi thông báo tin nhắn từ $senderName đến $receiverId');
  //
  //   // Lấy FCM token của người nhận
  //   final userDoc = await FirebaseFirestore.instance
  //       .collection('users')
  //       .doc(receiverId)
  //       .get();
  //   final deviceId = userDoc.data()?['fcmTokens'];
  //
  //   if (deviceId == null || deviceId.isEmpty) {
  //     print('FCM token của người nhận không tồn tại');
  //     return;
  //   }
  //
  //   const apiUrl = 'http://192.168.1.9:3000/notification';
  //
  //   final body = {
  //     'title': '$senderName đã gửi một tin nhắn',
  //     'body': message,
  //     'deviceId': deviceId,
  //   };
  //
  //   try {
  //     final response = await http.post(
  //       Uri.parse(apiUrl),
  //       headers: {'Content-Type': 'application/json'},
  //       body: jsonEncode(body),
  //     );
  //
  //     if (response.statusCode != 200 && response.statusCode != 201) {
  //       print('Gửi thông báo thất bại: ${response.body}');
  //     }
  //   } catch (e) {
  //     print('Lỗi khi gửi thông báo: $e');
  //   }
  // }
  //
  // static Future<void> saveMessageNotificationToFirestore({
  //   required String receiverId,
  //   required String senderId,
  //   required String senderName,
  //   required String message,
  // }) async {
  //   final notificationData = {
  //     'receiverId': receiverId,
  //     'senderId': senderId,
  //     'senderName': senderName,
  //     'type': 'message',
  //     'message': message,
  //     'timestamp': FieldValue.serverTimestamp(),
  //     'isRead': false,
  //   };
  //
  //   await FirebaseFirestore.instance
  //       .collection('notifications')
  //       .add(notificationData);
  // }
}
