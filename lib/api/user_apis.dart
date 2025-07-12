import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_sdk/cloudinary_sdk.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:learnity/config.dart';
import 'package:learnity/models/user_info_model.dart';

import '../enum/message_type.dart';
import '../models/app_user.dart';
import '../models/message.dart';
import '../screen/menuPage/setting/enum/post_privacy_enum.dart';
// import 'notification_access_token.dart';

// .env
import 'package:flutter_dotenv/flutter_dotenv.dart';

class APIs {
  // for authentication
  static FirebaseAuth get auth => FirebaseAuth.instance;

  // for accessing cloud firestore database
  static FirebaseFirestore firestore = FirebaseFirestore.instance;
  String? get _currentUserId => auth.currentUser?.uid;
  User? get _currentUser => auth.currentUser;
  // for accessing firebase storage
  static FirebaseStorage storage = FirebaseStorage.instance;

  static final Cloudinary cloudinary = Cloudinary.full(
    // apiKey: dotenv.env['CLOUDINARY_API_KEY1']!,
    // apiSecret: dotenv.env['CLOUDINARY_API_SECRET1']!,
    // cloudName: dotenv.env['CLOUDINARY_CLOUD_NAME1']!,
    apiKey: Config.cloudinaryApiKey1,
    apiSecret: Config.cloudinaryApiSecret1,
    cloudName: Config.cloudinaryCloudName1,
  );

  /// Tải avatar từ người gửi
  static Future<String?> fetchSenderAvatar(String senderId) async {
    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(senderId)
            .get();
    return userDoc.data()?['avatarUrl'];
  }

  /// Lấy stream thông báo có kèm theo `docId` để cập nhật trạng thái đọc
  static Stream<List<Map<String, dynamic>>> getNotificationsStream(
    String currentUserId,
  ) {
    return FirebaseFirestore.instance
        .collection('notifications')
        .where('receiverId', isEqualTo: currentUserId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => {...doc.data(), 'docId': doc.id})
                  .toList(),
        );
  }

  // for storing self information
  static AppUser me = AppUser(
    id: user.uid,
    name: user.displayName.toString(),
    email: user.email.toString(),
    role: '',
    bio: "Hey, I'm using We Chat!",
    avatarUrl: user.photoURL.toString(),
    createdAt: DateTime.now(),
    isOnline: false,
    lastActive: DateTime.now(),
  );

  // to return current user
  static User get user => auth.currentUser!;

  // for accessing firebase messaging (Push Notification)
  static FirebaseMessaging fMessaging = FirebaseMessaging.instance;

  // for getting firebase messaging token
  static Future<void> getFirebaseMessagingToken() async {
    await fMessaging.requestPermission();

    await fMessaging.getToken().then((t) {
      if (t != null) {
        // me.pushToken = t;
        log('Push Token: $t');
      }
    });

    // for handling foreground messages
    // FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    //   log('Got a message whilst in the foreground!');
    //   log('Message data: ${message.data}');

    //   if (message.notification != null) {
    //     log('Message also contained a notification: ${message.notification}');
    //   }
    // });
  }

  // for sending push notification (Updated Codes)
  // static Future<void> sendPushNotification(
  //     AppUser chatUser, String msg) async {
  //   try {
  //     final body = {
  //       "message": {
  //         "token": chatUser.pushToken,
  //         "notification": {
  //           "title": me.name, //our name should be send
  //           "body": msg,
  //         },
  //       }
  //     };

  //     // Firebase Project > Project Settings > General Tab > Project ID
  //     const projectID = 'we-chat-75f13';

  //     // get firebase admin token
  //     final bearerToken = await NotificationAccessToken.getToken;

  //     log('bearerToken: $bearerToken');

  //     // handle null token
  //     if (bearerToken == null) return;

  //     var res = await post(
  //       Uri.parse(
  //           'https://fcm.googleapis.com/v1/projects/$projectID/messages:send'),
  //       headers: {
  //         HttpHeaders.contentTypeHeader: 'application/json',
  //         HttpHeaders.authorizationHeader: 'Bearer $bearerToken'
  //       },
  //       body: jsonEncode(body),
  //     );

  //     log('Response status: ${res.statusCode}');
  //     log('Response body: ${res.body}');
  //   } catch (e) {
  //     log('\nsendPushNotificationE: $e');
  //   }
  // }

  //lấy số lượng thông báo chưa đọc
  static Stream<int> getUnreadNotificationCount(String userId) {
    return FirebaseFirestore.instance
        .collection('notifications')
        .where('receiverId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // for checking if user exists or not?
  static Future<bool> userExists() async {
    return (await firestore.collection('users').doc(user.uid).get()).exists;
  }

  // for adding an chat user for our conversation
  static Future<bool> addChatUser(String email) async {
    final data =
        await firestore
            .collection('users')
            .where('email', isEqualTo: email)
            .get();

    log('data: ${data.docs}');

    if (data.docs.isNotEmpty && data.docs.first.id != user.uid) {
      //user exists

      log('user exists: ${data.docs.first.id}');

      firestore
          .collection('users')
          .doc(user.uid)
          .collection('my_users')
          .doc(data.docs.first.id)
          .set({});

      return true;
    } else {
      //user doesn't exists

      return false;
    }
  }

  // for getting current user info
  static Future<void> getSelfInfo() async {
    await firestore.collection('users').doc(user.uid).get().then((user) async {
      if (user.exists) {
        me = AppUser.fromJson(user.data()!);
        // await getFirebaseMessagingToken();

        //for setting user status to active
        // APIs.updateActiveStatus(true);
        log('My Data: ${user.data()}');
      } else {
        await createUser().then((value) => getSelfInfo());
      }
    });
  }

  // for creating a new user
  static Future<void> createUser() async {
    final time = DateTime.now();

    final chatUser = AppUser(
      id: user.uid,
      name: user.displayName.toString(),
      email: user.email.toString(),
      role: '',
      bio: "Hey, I'm using We Chat!",
      avatarUrl: user.photoURL.toString(),
      createdAt: time,
      isOnline: false,
      lastActive: time,
    );

    return await firestore
        .collection('users')
        .doc(user.uid)
        .set(chatUser.toJson());
  }

  // for getting id's of known users from firestore database
  static Stream<QuerySnapshot<Map<String, dynamic>>> getMyUsersId() {
    return firestore
        .collection('users')
        .doc(user.uid)
        .collection('my_users')
        // .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  // for getting all users from firestore database
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllUsers(
    List<String> userIds,
  ) {
    log('\nUserIds: $userIds');

    return firestore
        .collection('users')
        .where(
          'uid',
          whereIn: userIds.isEmpty ? [''] : userIds,
        ) //because empty list throws an error
        // .where('id', isNotEqualTo: user.uid)
        .snapshots();
  }

  // for updating user information
  static Future<void> updateUserInfo() async {
    await firestore.collection('users').doc(user.uid).update({
      'name': me.name,
      'bio': me.bio,
    });
  }

  // update profile picture of user
  static Future<void> updateProfilePicture(File file) async {
    //getting avatar file extension
    final ext = file.path.split('.').last;
    log('Extension: $ext');

    //storage file ref with path
    final ref = storage.ref().child('profile_pictures/${user.uid}.$ext');

    //uploading avatar
    await ref.putFile(file, SettableMetadata(contentType: 'avatar/$ext')).then((
      p0,
    ) {
      log('Data Transferred: ${p0.bytesTransferred / 1000} kb');
    });

    //updating image in firestore database
    me.avatarUrl = await ref.getDownloadURL();
    await firestore.collection('users').doc(user.uid).update({
      'avatarUrl': me.avatarUrl,
    });
  }

  // for getting specific user info
  static Stream<QuerySnapshot<Map<String, dynamic>>> getUserById(String id) {
    return firestore
        .collection('users')
        .where('uid', isEqualTo: id)
        .snapshots();
  }

  // for getting specific user info
  static Stream<QuerySnapshot<Map<String, dynamic>>> getUserInfo(
    AppUser chatUser,
  ) {
    return firestore
        .collection('users')
        .where('uid', isEqualTo: chatUser.id)
        .snapshots();
  }

  // update online or last active status of user
  static Future<void> updateActiveStatus(bool isOnline) async {
    firestore.collection('users').doc(user.uid).update({
      'is_online': isOnline,
      'last_active': FieldValue.serverTimestamp(),
    });
  }

  ///************** Chat Screen Related APIs **************

  // chats (collection) --> conversation_id (doc) --> messages (collection) --> message (doc)

  // useful for getting conversation id
  static String getConversationID(String id) =>
      user.uid.hashCode <= id.hashCode
          ? '${user.uid}_$id'
          : '${id}_${user.uid}';

  // for getting all messages of a specific conversation from firestore database
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllMessages(
    AppUser user,
  ) {
    return firestore
        .collection('chats/${getConversationID(user.id)}/messages/')
        .orderBy('sent', descending: false)
        .snapshots();
  }

  // for sending message
  static Future<void> sendMessage(
    AppUser chatUser,
    String msg,
    MessageType type,
  ) async {
    //message sending time (also used as id)
    final time = DateTime.now().millisecondsSinceEpoch.toString();

    //message to send
    final Message message = Message(
      toId: chatUser.id,
      msg: msg,
      read: '',
      type: type,
      fromId: user.uid,
      sent: time,
    );

    final ref = firestore.collection(
      'chats/${getConversationID(chatUser.id)}/messages/',
    );
    await ref
        .doc(time)
        .set(message.toJson())
        .then(
          (value) =>
          // sendPushNotification(chatUser, type == MessageType.text ? msg : 'avatarUrl')
          log('No noti'),
        );
  }

  //update read status of message
  static Future<void> updateMessageReadStatus(Message message) async {
    firestore
        .collection('chats/${getConversationID(message.fromId)}/messages/')
        .doc(message.sent)
        .update({'read': DateTime.now().millisecondsSinceEpoch.toString()});
  }

  //get only last message of a specific chat
  static Stream<QuerySnapshot<Map<String, dynamic>>> getLastMessage(
    AppUser user,
  ) {
    return firestore
        .collection('chats/${getConversationID(user.id)}/messages/')
        .orderBy('sent', descending: true)
        .limit(1)
        .snapshots();
  }

  //send chat image
  static Future<void> sendChatImage(AppUser chatUser, File file) async {
    //getting image file extension
    // final ext = file.path.split('.').last;

    // //storage file ref with path
    // final ref = storage.ref().child(
    //     'images/${getConversationID(chatUser.id)}/${DateTime.now().millisecondsSinceEpoch}.$ext');

    // //uploading image
    // await ref
    //     .putFile(file, SettableMetadata(contentType: 'image/$ext'))
    //     .then((p0) {
    //   log('Data Transferred: ${p0.bytesTransferred / 1000} kb');
    // });

    // //updating image in firestore database
    // final imageUrl = await ref.getDownloadURL();
    // await sendMessage(chatUser, imageUrl, MessageType.image);

    try {
      final response = await cloudinary.uploadFile(
        filePath: file.path,
        resourceType: CloudinaryResourceType.image,
        folder:
            'Learnity/Chats/${getConversationID(chatUser.id)}', // thư mục lưu trữ trên Cloudinary
        fileName: '${FirebaseAuth.instance.currentUser?.uid}', // tên file
        progressCallback: (count, total) {
          debugPrint('Uploading image: $count/$total');
        },
      );

      if (response.isSuccessful && response.secureUrl != null) {
        //updating image in firestore database
        final imageUrl = response.secureUrl;
        await sendMessage(chatUser, imageUrl!, MessageType.image);
      } else {
        throw Exception('Upload failed: ${response.error}');
      }
    } catch (e) {
      debugPrint('Error uploading to Cloudinary: $e');
      rethrow;
    }
  }

  //delete message
  static Future<void> deleteMessage(Message message) async {
    await firestore
        .collection('chats/${getConversationID(message.toId)}/messages/')
        .doc(message.sent)
        .delete();

    if (message.type == MessageType.image) {
      await storage.refFromURL(message.msg).delete();
    }
  }

  //update message
  static Future<void> updateMessage(Message message, String updatedMsg) async {
    await firestore
        .collection('chats/${getConversationID(message.toId)}/messages/')
        .doc(message.sent)
        .update({'msg': updatedMsg});
  }

  //Load quyền riêng tư bài viết
  Future<PostPrivacy> loadPostPrivacySetting() async {
    final userId = _currentUserId;
    if (userId == null) {
      return PostPrivacy.everyone;
    }

    try {
      final doc = await firestore.collection('users').doc(userId).get();

      if (doc.exists && doc.data() != null) {
        final setting = doc.data()!['view_permission'] as String?;
        return PostPrivacyExtension.fromFirestoreValue(setting);
      } else {
        return PostPrivacy.everyone;
      }
    } catch (e) {
      print("Lỗi khi tải cài đặt quyền riêng tư: $e");
      return PostPrivacy.everyone;
    }
  }

  // Lưu cài đặt quyền riêng tư mới của bài viết vào Firestore.
  Future<bool> savePostPrivacySetting(PostPrivacy newPrivacy) async {
    final userId = _currentUserId;
    if (userId == null) {
      print("Không thể lưu: Người dùng chưa đăng nhập.");
      return false;
    }

    try {
      await firestore.collection('users').doc(userId).set({
        'view_permission': newPrivacy.firestoreValue,
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      print("Lỗi khi lưu cài đặt quyền riêng tư: $e");
      return false;
    }
  }

  //Load quyền riêng tư chia sẻ
  Future<PostPrivacy> loadSharedPostPrivacySetting() async {
    final userId = _currentUserId;
    if (userId == null) {
      return PostPrivacy.everyone;
    }

    try {
      final doc = await firestore.collection('users').doc(userId).get();

      if (doc.exists && doc.data() != null) {
        final setting = doc.data()!['view_shared_post_permission'] as String?;
        return PostPrivacyExtension.fromFirestoreValue(setting);
      } else {
        return PostPrivacy.everyone;
      }
    } catch (e) {
      print("Lỗi khi tải cài đặt quyền riêng tư: $e");
      return PostPrivacy.everyone;
    }
  }

  // Lưu cài đặt quyền riêng tư mới của bài chia sẻ vào Firestore.
  Future<bool> saveSharedPostPrivacySetting(PostPrivacy newPrivacy) async {
    final userId = _currentUserId;
    if (userId == null) {
      print("Không thể lưu: Người dùng chưa đăng nhập.");
      return false;
    }

    try {
      await firestore.collection('users').doc(userId).set({
        'view_shared_post_permission': newPrivacy.firestoreValue,
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      print("Lỗi khi lưu cài đặt quyền riêng tư: $e");
      return false;
    }
  }

  // Lấy avt user (nhom)
  Future<String?> getCurrentUserAvatarUrl() async {
    final user = _currentUser;
    if (user == null) {
      return null; // Người dùng chưa đăng nhập
    }

    try {
      // Thử lấy URL tùy chỉnh từ Firestore trước
      final userDoc = await firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final customAvatarUrl = userDoc.data()?['avatarUrl'] as String?;
        if (customAvatarUrl != null && customAvatarUrl.isNotEmpty) {
          return customAvatarUrl;
        }
      }
    } catch (e) {
      print("Lỗi khi lấy avatar từ Firestore: $e");
    }
    // Nếu không có URL tùy chỉnh hoặc có lỗi, trả về URL mặc định từ Auth
    return user.photoURL;
  }

  Future<String?> getCurrentUsername() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        return data['username'] as String?;
      } else {
        return null;
      }
    } catch (e) {
      print('Lỗi khi lấy username: $e');
      return null;
    }
  }

  //Hàm đăng bài lên home
  Future<String?> createPostOnHomePage({
    required String text,
    required List<File> imageFiles,
    required List<String> tagList,
  }) async {
    final user = _currentUser;
    if (user == null) {
      print("Lỗi: Người dùng chưa đăng nhập.");
      return null;
    }

    final postId = firestore.collection('posts').doc().id;
    List<String> uploadedImageUrls = [];

    try {
      for (File imageFile in imageFiles) {
        final response = await cloudinary.uploadFile(
          filePath: imageFile.path,
          resourceType: CloudinaryResourceType.image,
          folder: 'Learnity/HomePosts',
          fileName: '${postId}_${DateTime.now().millisecondsSinceEpoch}',
        );
        if (response.isSuccessful && response.secureUrl != null) {
          uploadedImageUrls.add(response.secureUrl!);
        } else {
          print('Cloudinary upload failed: ${response.error}');
          return null;
        }
      }

      String authorUsername =
          user.displayName ?? user.email?.split('@').first ?? 'Người dùng';
      String? authorAvatarUrl = user.photoURL;

      final userDoc = await firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        authorUsername = userData['username'] ?? authorUsername;
        authorAvatarUrl = userData['avatarUrl'] ?? authorAvatarUrl;
      }

      final post = {
        'postId': postId,
        'username': authorUsername,
        'avatarUrl': authorAvatarUrl ?? '',
        'tagList': tagList,
        'content': text,
        'imageUrls': uploadedImageUrls,
        'likes': 0,
        'comments': 0,
        'shares': 0,
        'uid': user.uid,
        'createdAt': DateTime.now(),
      };

      await firestore.collection('posts').doc(postId).set(post);

      return postId;
    } catch (e) {
      print("Lỗi khi đăng bài lên trang chủ: $e");
      return null;
    }
  }

  // Lấy thông tin người
  Future<Map<String, dynamic>?> getUserInfoById(String userId) async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();
      if (doc.exists) {
        return doc.data();
      }
    } catch (e) {
      debugPrint('Lỗi khi lấy thông tin người dùng: $e');
    }
    return null;
  }
}
