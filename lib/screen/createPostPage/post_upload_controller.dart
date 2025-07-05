import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:learnity/api/user_apis.dart';

class PostUploadController extends GetxController {
  final RxBool isUploading = false.obs;
  final RxDouble uploadProgress = 0.0.obs;
  final RxString uploadStatus = ''.obs;
  final RxBool uploadSuccess = false.obs;
  final RxString uploadError = ''.obs;

  Future<void> uploadPost({
    required String title,
    required String content,
    required List<File> imageFiles,
  }) async {
    try {
      // Reset state
      isUploading.value = true;
      uploadProgress.value = 0.0;
      uploadStatus.value = 'Đang chuẩn bị...';
      uploadSuccess.value = false;
      uploadError.value = '';

      // mô phỏng quá trình tải lên
      uploadStatus.value = 'Đang tải ảnh lên...';
      uploadProgress.value = 0.3;
      await Future.delayed(Duration(milliseconds: 500));

      uploadStatus.value = 'Đang xử lý nội dung...';
      uploadProgress.value = 0.6;
      await Future.delayed(Duration(milliseconds: 500));

      uploadStatus.value = 'Đang đăng bài viết...';
      uploadProgress.value = 0.9;

      final APIs _userApi = APIs();
      final success = await _userApi.createPostOnHomePage(
        title: title,
        text: content,
        imageFiles: imageFiles,
      );

      if (success != null) {
        uploadProgress.value = 1.0;
        uploadStatus.value = 'Đăng bài thành công!';
        uploadSuccess.value = true;

        // ẩn thông báo sau 2 giây
        await Future.delayed(Duration(seconds: 2));
        _resetUploadState();
      } else {
        throw Exception('Không thể đăng bài viết');
      }
    } catch (e) {
      uploadError.value = e.toString();
      uploadStatus.value = 'Đăng bài thất bại';

      await Future.delayed(Duration(seconds: 3));
      _resetUploadState();
    }
  }

  void _resetUploadState() {
    isUploading.value = false;
    uploadProgress.value = 0.0;
    uploadStatus.value = '';
    uploadSuccess.value = false;
    uploadError.value = '';
  }

  // Hủy quá trình tải lên
  void cancelUpload() {
    _resetUploadState();
  }
}
