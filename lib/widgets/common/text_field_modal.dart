import 'package:flutter/material.dart';
import 'package:learnity/theme/theme.dart';
import 'package:get/get.dart';

Future<void> showTextFieldModal({
  required BuildContext context,
  required bool isDarkMode,
  required String title,
  required String hintText,
  required String confirmText,
  required void Function(String content) onConfirm,
  String initialText = '', // Add this parameter with default empty string
}) async {
  final TextEditingController controller = TextEditingController(text: initialText);

  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppBackgroundStyles.modalBackground(isDarkMode),
      title: Text(
        title,
        style: TextStyle(color: AppTextStyles.normalTextColor(isDarkMode)),
      ),
      content: TextField(
        controller: controller, // Use the controller with initial text
        style: TextStyle(color: AppTextStyles.normalTextColor(isDarkMode)),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: AppTextStyles.normalTextColor(isDarkMode).withOpacity(0.5),
          ),
          border: const OutlineInputBorder(),
        ),
        maxLines: null, // Allow multiple lines for comments
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Hủy',
            style: TextStyle(color: AppTextStyles.subTextColor(isDarkMode)),
          ),
        ),
        TextButton(
          style: TextButton.styleFrom(
            backgroundColor: AppBackgroundStyles.buttonBackground(isDarkMode),
            foregroundColor: AppTextStyles.buttonTextColor(isDarkMode),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onPressed: () {
            if (controller.text.trim().isNotEmpty) {
              Navigator.pop(context);
              onConfirm(controller.text.trim());
            } else {
              Get.snackbar(
                "Lỗi",
                "Vui lòng nhập nội dung.",
                backgroundColor: Colors.blue.withOpacity(0.9),
                colorText: Colors.white,
                duration: const Duration(seconds: 2),
              );
            }
          },
          child: Text(
            confirmText,
            style: TextStyle(color: AppTextStyles.buttonTextColor(isDarkMode)),
          ),
        ),
      ],
    ),
  );
}