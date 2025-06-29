import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:learnity/api/user_apis.dart';
import 'package:learnity/navigation_menu.dart';
import 'package:learnity/screen/homePage/social_feed_page.dart';

class PostViewmodel {
  Future<void> submitPost(
    BuildContext context,
    File? _imageToUpload,
    String title,
    String content,
  ) async {
    final APIs _userApi = APIs();

    final success = await _userApi.createPostOnHomePage(
      title: title,
      text: content,
      imageFile: _imageToUpload,
    );

    if (success != null) {
      Get.snackbar(
        "Thành công",
        "Đăng bài thành công!",
        backgroundColor: Colors.blue.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => NavigationMenu()),
        (route) => false, // Xóa toàn bộ các route trước đó
      );
    } else {
      Get.snackbar(
        "Thất bại",
        "Không thể đăng bài!",
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    }
  }
}
