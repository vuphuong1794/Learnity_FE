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
import 'package:learnity/config.dart';
import '../enum/message_type.dart';
import '../models/app_user.dart';
import '../models/group_message.dart';
import '../models/message.dart';
import '../screen/menuPage/setting/enum/post_privacy_enum.dart';

// .env
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GroupChatApi {
  static FirebaseAuth get auth => FirebaseAuth.instance;

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

  // to return current user
  static User get user => auth.currentUser!;

  // for accessing firebase messaging (Push Notification)
  static FirebaseMessaging fMessaging = FirebaseMessaging.instance;

  // for getting specific user info
  static Stream<QuerySnapshot<Map<String, dynamic>>> getGroupInfo(
    String groupId,
  ) {
    return firestore
        .collection('groupChats')
        .where('id', isEqualTo: groupId)
        .snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllMessages(
    String groupId,
  ) {
    return firestore
        .collection('groupChats/$groupId/messages/')
        .orderBy('sent', descending: false)
        .snapshots();
  }

  // for sending message
  static Future<void> sendMessage(
    String groupId,
    String msg,
    MessageType type,
  ) async {
    //message sending time (also used as id)
    final time = DateTime.now().millisecondsSinceEpoch.toString();

    //message to send
    final GroupMessage message = GroupMessage(
      toGroupId: groupId,
      msg: msg,
      read: '',
      type: type,
      fromUserId: user.uid,
      sent: time,
    );

    final ref = firestore.collection('groupChats/${groupId}/messages/');
    await ref
        .doc(time)
        .set(message.toJson())
        .then(
          (value) =>
          // sendPushNotification(chatUser, type == MessageType.text ? msg : 'avatarUrl')
          log('No noti'),
        );
  }

  // for sending group notify
  static Future<void> sendGroupNotify(String groupId, String msg) async {
    //message sending time (also used as id)
    final time = DateTime.now().millisecondsSinceEpoch.toString();

    //message to send
    final GroupMessage message = GroupMessage(
      toGroupId: groupId,
      msg: msg,
      read: '',
      type: MessageType.notify,
      fromUserId: '',
      sent: time,
    );

    final ref = firestore.collection('groupChats/${groupId}/messages/');
    await ref
        .doc(time)
        .set(message.toJson())
        .then(
          (value) =>
          // sendPushNotification(chatUser, type == MessageType.text ? msg : 'avatarUrl')
          log('No noti'),
        );
  }

  static Future<void> sendChatImage(String groupId, File file) async {
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
        folder: 'Learnity/Chats/$groupId', // thư mục lưu trữ trên Cloudinary
        fileName: '${FirebaseAuth.instance.currentUser?.uid}', // tên file
        progressCallback: (count, total) {
          debugPrint('Uploading image: $count/$total');
        },
      );

      if (response.isSuccessful && response.secureUrl != null) {
        //updating image in firestore database
        final imageUrl = response.secureUrl;
        await sendMessage(groupId, imageUrl!, MessageType.image);
      } else {
        throw Exception('Upload failed: ${response.error}');
      }
    } catch (e) {
      debugPrint('Error uploading to Cloudinary: $e');
      rethrow;
    }
  }

  // static Future<void> updateMessageReadStatus(GroupMessage message) async {
  //   firestore
  //       .collection('chats/${getConversationID(message.fromId)}/messages/')
  //       .doc(message.sent)
  //       .update({'read': DateTime.now().millisecondsSinceEpoch.toString()});
  // }

  //delete message
  static Future<void> deleteMessage(GroupMessage message) async {
    await firestore
        .collection('groupChats/${message.toGroupId}/messages/')
        .doc(message.sent)
        .delete();

    if (message.type == MessageType.image) {
      await storage.refFromURL(message.msg).delete();
    }
  }

  //update message
  static Future<void> updateMessage(
    GroupMessage message,
    String updatedMsg,
  ) async {
    await firestore
        .collection('groupChats/${message.toGroupId}/messages/')
        .doc(message.sent)
        .update({'msg': updatedMsg});
  }
}
