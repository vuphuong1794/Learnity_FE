import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomSnackbar {
  static void show({
    required String title,
    required String message,
    Color backgroundColor = Colors.blue,
    Color textColor = Colors.white,
    Duration duration = const Duration(seconds: 2),
  }) {
    Get.snackbar(
      title,
      message,
      backgroundColor: backgroundColor.withOpacity(0.9),
      colorText: textColor,
      duration: duration,
      snackPosition: SnackPosition.TOP, // hoặc TOP tùy ý
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      borderRadius: 12,
    );
  }
}
