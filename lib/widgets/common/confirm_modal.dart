import 'package:flutter/material.dart';
import 'package:learnity/theme/theme.dart';

Future<bool?> showConfirmModal({
  required String title,
  required String content,
  required String cancelText,
  required String confirmText,
  required BuildContext context,
  required bool isDarkMode,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppBackgroundStyles.modalBackground(isDarkMode),
      title: Text(
        title,
        style: TextStyle(color: AppTextStyles.normalTextColor(isDarkMode)),
      ),
      content: Text(
        content,
        style: TextStyle(color: AppTextStyles.normalTextColor(isDarkMode)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            cancelText,
            style: TextStyle(color: AppTextStyles.subTextColor(isDarkMode)),
          ),
        ),
        TextButton(
          style: TextButton.styleFrom(
            backgroundColor: AppBackgroundStyles.buttonBackground(isDarkMode),
            foregroundColor: AppTextStyles.buttonTextColor(isDarkMode),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            confirmText,
            style: TextStyle(
              color: AppTextStyles.buttonTextColor(isDarkMode),
            ),
          ),
        ),
      ],
    ),
  );
}
