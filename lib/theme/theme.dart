import 'package:flutter/material.dart';

class AppColors {
  // --- LIGHT MODE ---
  static const Color background = Color(0xFFA0EACF);
  static const Color backgroundSecond = Color(0xFF0F2A19);

  static const Color buttonBg = Color(0xFF0F2A19);
  static const Color buttonBgProfile = Color(0xFF9EB9A8);

  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF6C6C6C);
  static const Color textThird = Color(0xFFA5AFA8);

  static const Color buttonText = Color(0xFFA0EACF);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color buttonEditProfile = Color(0xFF0F2A19);

  // --- DARK MODE ---
  static const Color darkBackground = Color(0xFF0F2A19);
  static const Color darkBackgroundSecond = Color(0xFFA0EACF);

  static const Color darkButtonBg = Color(0xFF2C2C2C);
  static const Color darkButtonBgProfile = Color(0xFF3A3A3A);

  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);
  static const Color darkTextThird = Color(0xFF8E8E8E);

  static const Color darkButtonText = Color(0xFF00FFB3);
}

class AppTextStyles {
  // Heading lớn, trang chủ, màn chào
  static TextStyle title(bool isDarkMode) => TextStyle(
        fontSize: 40,
        fontWeight: FontWeight.w900,
        color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
      );

  // Heading phụ
  static TextStyle subtitle(bool isDarkMode) => TextStyle(
        fontSize: 25,
        fontWeight: FontWeight.w800,
        color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
      );

  // Heading cấp 3
  static TextStyle subtitle2(bool isDarkMode) => TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: isDarkMode ? AppColors.darkTextThird : AppColors.textThird,
      );

  // Body chính
  static TextStyle body(bool isDarkMode) => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
      );

  // Body phụ
  static TextStyle bodySecondary(bool isDarkMode) => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary,
      );

  // Chú thích nhỏ
  static TextStyle caption(bool isDarkMode) => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: isDarkMode ? AppColors.darkTextThird : AppColors.textThird,
      );

  // Text trong các button
  static TextStyle textButton(bool isDarkMode) => TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: isDarkMode ? AppColors.darkButtonText : AppColors.buttonText,
      );

  // Nhãn label form
  static TextStyle label(bool isDarkMode) => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
      );

  // Hint text trong input
  static TextStyle hint(bool isDarkMode) => TextStyle(
        fontSize: 16,
        fontStyle: FontStyle.italic,
        color: isDarkMode
            ? AppColors.darkTextSecondary.withOpacity(0.6)
            : AppColors.textSecondary.withOpacity(0.6),
      );

  // Link có thể nhấn
  static TextStyle link(bool isDarkMode) => TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: isDarkMode ? Colors.lightBlue[200] : Colors.blue,
        decoration: TextDecoration.underline,
      );

  // Thông báo lỗi
  static TextStyle error(bool isDarkMode) => const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.red,
      );

  // Placeholder cho input
  static TextStyle placeholder(bool isDarkMode) => TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.normal,
        color: isDarkMode ? AppColors.darkTextThird : AppColors.textThird,
      );

  // Text người dùng nhập
  static TextStyle inputText(bool isDarkMode) => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
      );
}

class AppBackgroundStyles {
  static Color mainBackground(bool isDarkMode) =>
      isDarkMode ? AppColors.darkBackground : AppColors.background;

  static Color secondaryBackground(bool isDarkMode) =>
      isDarkMode ? AppColors.darkBackgroundSecond : AppColors.backgroundSecond;

  static Color footerBackground(bool isDarkMode) =>
      isDarkMode ? AppColors.background : AppColors.darkBackground;
}

class AppIconStyles {
  static Color footbarIcon(bool isDarkMode) =>
      isDarkMode ? AppColors.darkBackground : AppColors.background;

  static Color iconPrimary(bool isDarkMode) =>
      isDarkMode ? AppColors.white : AppColors.black;

  static Color iconSecondary(bool isDarkMode) =>
      isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary;
}
