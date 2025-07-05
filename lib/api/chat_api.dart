import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_sdk/cloudinary_sdk.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:learnity/api/notification_api.dart';
import 'package:learnity/config.dart';

import '../enum/message_type.dart';
import '../models/app_user.dart';
import '../models/message.dart';
import '../screen/menuPage/setting/enum/post_privacy_enum.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'notification_access_token.dart';

class ChatApi {
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

  // for adding an user to my user when first message is send
  static Future<void> sendFirstMessage(
    AppUser chatUser,
    String msg,
    MessageType type,
  ) async {
    await firestore
        .collection('users')
        .doc(user.uid)
        .collection('my_users')
        .doc(chatUser.id)
        .set({});

    await firestore
        .collection('users')
        .doc(chatUser.id)
        .collection('my_users')
        .doc(user.uid)
        .set({})
        .then((value) => sendMessage(chatUser, msg, type));
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

    await updateLastMessageTime(chatUser.id, user.uid, time);
    await updateLastMessageTime(user.uid, chatUser.id, time);
    await Notification_API.sendChatNotification(me.name, chatUser.id, msg, type);
  }

  static Future<void> updateLastMessageTime(String userId, String myUserId, String lastMessageTime) async {
    final lastMsgUpdate = {
      'lastMessageTime': lastMessageTime,
    };

    await firestore
      .collection('users')
      .doc(userId)
      .collection('my_users')
      .doc(myUserId)
      .update(lastMsgUpdate);
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

  Future<String?> _uploadToCloudinary(File imageFile) async {
    try {
      final response = await cloudinary.uploadFile(
        filePath: imageFile.path,
        resourceType: CloudinaryResourceType.image,
        folder:
            'Learnity/Users/${FirebaseAuth.instance.currentUser?.uid}', // thư mục lưu trữ trên Cloudinary
        fileName:
            'avatar_${FirebaseAuth.instance.currentUser?.uid}', // tên file
        progressCallback: (count, total) {
          debugPrint('Uploading image: $count/$total');
        },
      );

      if (response.isSuccessful && response.secureUrl != null) {
        return response.secureUrl;
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
} 


