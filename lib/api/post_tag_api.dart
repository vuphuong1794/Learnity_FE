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

class PostTagApi {
  static Future<List<String>> fetchAvailableTags() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('post_tags')
          .get();

      final tags = snapshot.docs
          .map((doc) => doc['name'] as String)
          .toList();

      return tags;
    } catch (e) {
      print('Error fetching tags: $e');
      return []; // hoặc throw nếu bạn muốn xử lý lỗi phía gọi
    }
  }
} 
