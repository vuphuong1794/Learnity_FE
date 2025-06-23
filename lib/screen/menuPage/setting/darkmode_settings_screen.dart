import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../../api/user_apis.dart';
import 'enum/post_privacy_enum.dart';
import 'package:provider/provider.dart';
import 'package:learnity/theme/theme.dart';
import 'package:learnity/theme/theme_provider.dart';

class DarkmodeSettingsScreen extends StatefulWidget {
  const DarkmodeSettingsScreen({super.key});

  @override
  State<DarkmodeSettingsScreen> createState() => _DarkmodeSettingsScreenState();
}

class _DarkmodeSettingsScreenState extends State<DarkmodeSettingsScreen> {
  // Lựa chọn riêng tư hiện tại, mặc định là everyone
  PostPrivacy _selectedPrivacy =
      PostPrivacy.everyone;
  bool _isSaving = false;
  final APIs _userApi = APIs();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: AppBackgroundStyles.mainBackground(isDarkMode),
      appBar: AppBar(
        backgroundColor: AppBackgroundStyles.secondaryBackground(isDarkMode),
        iconTheme: IconThemeData(
          color: AppIconStyles.iconPrimary(isDarkMode), // Đổi màu mũi tên tại đây
        ),
        title: Text(
          'Cài đặt chế độ tối',
          // style: TextStyle(color:  AppColors.black),
          style: AppTextStyles.headbarTitle(isDarkMode),
        ),
        centerTitle: true,
        elevation: 1,
        bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Container(
                    height: 1,
                    color: AppTextStyles.normalTextColor(isDarkMode).withOpacity(0.2), // bạn có thể chỉnh màu ở đây
                  ),
                ),
      ),
      body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    title: Text(
                      "Chế độ tối",
                      style: AppTextStyles.body(isDarkMode),
                      ),
                    value: isDarkMode,
                    onChanged: (value) {
                      themeProvider.setDarkMode(value);
                    },
                    secondary: Icon(
                      Icons.dark_mode,
                      color: AppIconStyles.iconPrimary(isDarkMode),
                      ),
                    activeColor: AppColors.darkBackground,           // Màu nút khi bật
                    activeTrackColor: AppColors.darkButtonBackgroundSecondary, // Màu nền khi bật
                    inactiveThumbColor: AppColors.background,      // Màu nút khi tắt
                    inactiveTrackColor: AppColors.darkTextThird, // Màu nền khi tắt
                  ),
                ],
              ),
            ),
    );
  }
}
