import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:learnity/api/user_apis.dart';
import 'package:learnity/navigation_menu.dart';
import 'package:learnity/screen/createPostPage/post_upload_controller.dart';
import 'package:learnity/screen/groupPage/group_content_screen.dart';
import 'package:learnity/screen/groupPage/group_screen.dart';
import 'package:learnity/screen/homePage/social_feed_page.dart';
import 'package:learnity/widgets/common/check_bad_words.dart';

class PostViewmodel {
  // Danh sách các từ cấm (tùy bạn mở rộng)
  // final List<String> _badWords = [
  //   'chửi', 'đm', 'vkl', 'vl', 'cc', 'shit', 'fuck', 'bitch', 'ngu', 'đần',
  //   'dốt', 'địt', 'lồn', 'cặc', 'đụ', 'đéo', 'má', 'mẹ', 'cút', 'clm'
  // ];

  // // Hàm kiểm tra có chứa từ cấm hay không
  // bool _containsBadWords(String text) {
  //   final lowerText = text.toLowerCase();
  //   return _badWords.any((word) => lowerText.contains(word));
  // }

  Future<void> submitPost(
    BuildContext context,
    List<File> imageFiles,
    String content,
    List<String> tagList,
  ) async {
    if (tagList.isEmpty) {
      Get.snackbar(
        "Lỗi",
        "Vui lòng chọn ít nhất một chủ đề để đăng bài viết.",
        backgroundColor: Colors.blue.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    if (content.trim().isEmpty && imageFiles.isEmpty) {
      Get.snackbar(
        "Lỗi",
        "Vui lòng nhập ít nhất một nội dung để đăng bài viết.",
        backgroundColor: Colors.blue.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    // Kiểm tra từ bậy trong title và content
    if (CheckBadWords.containsBadWords(content)) {
      Get.snackbar(
        "Không thể đăng bài",
        "Nội dung bài viết chứa từ ngữ không phù hợp.",
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    // chuyển hướng về trang SocialFeedPage
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => NavigationMenu()),
      (route) => false,
    );

    // Khởi tạo PostUploadController
    final PostUploadController uploadController = Get.put(
      PostUploadController(),
    );

    // bắt đầu quá trình tải lên
    await uploadController.uploadPost(
      content: content,
      imageFiles: imageFiles,
      tagList: tagList
    );
  }

  Future<void> submitGroupPost(
    BuildContext context,
    List<File> imageFiles,
    String title,
    String content,
    String groupId,
    String groupName,
  ) async {
    if (title
        .trim()
        .isEmpty && content
        .trim()
        .isEmpty && imageFiles.isEmpty) {
      Get.snackbar(
        "Lỗi",
        "Vui lòng nhập ít nhất một nội dung để đăng bài viết.",
        backgroundColor: Colors.blue.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    // Kiểm tra từ bậy trong title và content
    if (CheckBadWords.containsBadWords(title) ||
        CheckBadWords.containsBadWords(content)) {
      Get.snackbar(
        "Không thể đăng bài",
        "Nội dung bài viết chứa từ ngữ không phù hợp.",
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    final PostUploadController uploadController = Get.find<
        PostUploadController>();

    uploadController.uploadGroupPost(
      title: title,
      content: content,
      imageFiles: imageFiles,
      groupId: groupId,
    );

    Navigator.of(context).pop();
  }
}
