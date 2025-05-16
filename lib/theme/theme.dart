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

  static const Color darkBackground = Color(0xFF0F2A19);
  static const Color darkBackgroundSecond = Color(0xFFA0EACF);
  static const Color darkButtonBg = Color(0xFF2C2C2C);
  static const Color darkButtonBgProfile = Color(0xFF3A3A3A);
  static const Color darkTextPrimary = Color(0xFFFFFFFF); //chữ chính( trắng)
  static const Color darkTextSecondary = Color(0xFFB0B0B0);// chữu phụ(xám trắng)
  static const Color darkTextThird = Color(0xFF8E8E8E);
  static const Color darkButtonText = Color(0xFF00FFB3);
  static const Color black = Color(0xFF000000);
}

class AppTextStyles {
  static TextStyle title (isDarkMode) => TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.w900,
    color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
  );
  static TextStyle username (isDarkMode) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
  );
  static TextStyle fullname (isDarkMode) => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary,
  );
  static TextStyle subtitle (isDarkMode) => TextStyle(
    fontSize: 25,
    fontWeight: FontWeight.w900,
    color: isDarkMode ? AppColors.darkTextPrimary: AppColors.textPrimary,
  );
  static TextStyle subtitle_2 (isDarkMode) => TextStyle(
    fontSize: 25,
    fontWeight: FontWeight.w900,
    color: isDarkMode ? AppColors.darkTextThird : AppColors.textThird,
  );
  static TextStyle textButton (isDarkMode) => TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
  ); 
}
