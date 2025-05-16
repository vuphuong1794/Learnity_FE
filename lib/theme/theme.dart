import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFFA0EACF); //background
  static const Color background_second = Color(0xFF0F2A19); // Màu nền sidebar
  static const Color button_bg = Color(0xFF0F2A19); // Màu nền button
  static const Color button_bg_profile = Color(0xFF9EB9A8); //màu xánh lá nhạt
  static const Color textPrimary = Color(0xFF000000); // Màu chữ chính (đen)
  static const Color textSecondary = Color(0xFF6C6C6C); // Màu chữ phụ (xám)
  static const Color textThird  = Color(0xFFA5AFA8); // Màu xám đậm
  static const Color buttonText = Color(0xFFA0EACF); // Chữ trên button
  static const Color white = Color(0xFFFFFFFF); // Màu trắng
}

class AppTextStyles {
  static const TextStyle title = TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.w900,
    color: AppColors.textPrimary,
  );
  static const TextStyle username = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
  static const TextStyle fullname = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );
  static const TextStyle subtitle = TextStyle(
    fontSize: 25,
    fontWeight: FontWeight.w900,
    color: AppColors.textPrimary,
  );
  static const TextStyle subtitle_2 = TextStyle(
    fontSize: 25,
    fontWeight: FontWeight.w900,
    color: AppColors.textThird,
  );
  static const TextStyle textButton = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  ); 
}