import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../../api/user_apis.dart';
import 'enum/post_privacy_enum.dart';
import 'package:provider/provider.dart';
import 'package:learnity/theme/theme.dart';
import 'package:learnity/theme/theme_provider.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  // Lựa chọn riêng tư hiện tại, mặc định là everyone
  PostPrivacy _selectedPrivacy =
      PostPrivacy.everyone;
  PostPrivacy _selectedSharedPostPrivacy =
      PostPrivacy.everyone;
  bool _isLoading = true;
  bool _isSaving = false;
  final APIs _userApi = APIs();

  @override
  void initState() {
    super.initState();
    _loadCurrentPrivacySetting();
  }

  // Hàm tải cài đặt riêng tư hiện tại của người dùng từ DB
  Future<void> _loadCurrentPrivacySetting() async {
    setState(() => _isLoading = true);
    final currentSetting = await _userApi.loadPostPrivacySetting();
    final currentSharedPostSetting = await _userApi.loadSharedPostPrivacySetting();
    if (mounted) {
      setState(() {
        _selectedPrivacy = currentSetting;
        _selectedSharedPostPrivacy = currentSharedPostSetting;
        _isLoading = false;
      });
    }
  }
  // Hàm lưu cài đặt riêng tư mới của người dùng vào db
  Future<void> _savePrivacySetting() async {
    setState(() => _isSaving = true);
    final success = await _userApi.savePostPrivacySetting(_selectedPrivacy);
    final sharedPostSuccess = await _userApi.saveSharedPostPrivacySetting(_selectedSharedPostPrivacy);
    if (mounted) {
      if (success && sharedPostSuccess) {
        Get.snackbar(
          "Thành công",
          "Đã lưu cài đặt quyền riêng tư.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        Navigator.of(context).pop();
      } else {
        if (!success) {
          Get.snackbar(
            "Lỗi",
            "Không thể lưu cài đặt bài viết. Vui lòng thử lại.",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        } else {
          Get.snackbar(
            "Lỗi",
            "Không thể lưu cài đặt bài chia sẻ. Vui lòng thử lại.",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      }
      setState(() => _isSaving = false);
    }
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
          color: AppIconStyles.iconPrimary(isDarkMode),
        ),
        title: Text(
          'Cài đặt quyền riêng tư bài viết',
          style: AppTextStyles.headbarTitle(isDarkMode),
        ),
        centerTitle: true,
        elevation: 1,
        bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Container(
                    height: 1,
                    color: AppIconStyles.iconPrimary(isDarkMode).withOpacity(0.2),
                  ),
                ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ai có thể xem được bài viết của bạn?',
                      style: AppTextStyles.bodyTitle(isDarkMode)
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cài đặt này sẽ áp dụng cho tất cả các bài viết mà bạn đã đăng',
                      style: AppTextStyles.bodySecondary(isDarkMode)
                    ),
                    const SizedBox(height: 20),
                    RadioListTile<PostPrivacy>(
                      title: Text(
                        PostPrivacy.everyone.displayName,
                        style: AppTextStyles.body(isDarkMode)
                      ),
                      value: PostPrivacy.everyone,
                      // Lựa chọn hiện tại đang được chọn
                      groupValue: _selectedPrivacy,
                      onChanged: (PostPrivacy? value) {
                        if (value != null) {
                          setState(() {
                            _selectedPrivacy = value;
                          });
                        }
                      },
                      activeColor: AppIconStyles.iconPrimary(isDarkMode),
                    ),
                    RadioListTile<PostPrivacy>(
                      title: Text(
                        PostPrivacy.myself.displayName,
                        style: AppTextStyles.body(isDarkMode)
                      ),
                      value: PostPrivacy.myself,
                      groupValue: _selectedPrivacy,
                      onChanged: (PostPrivacy? value) {
                        if (value != null) {
                          setState(() {
                            _selectedPrivacy = value;
                          });
                        }
                      },
                      activeColor: AppIconStyles.iconPrimary(isDarkMode),
                    ),
                    const SizedBox(height: 8),
                    RadioListTile<PostPrivacy>(
                      title: Text(
                        PostPrivacy.followers.displayName,
                        style: AppTextStyles.body(isDarkMode)
                      ),
                      value: PostPrivacy.followers,
                      groupValue: _selectedPrivacy,
                      onChanged: (PostPrivacy? value) {
                        if (value != null) {
                          setState(() {
                            _selectedPrivacy = value;
                          });
                        }
                      },
                      activeColor: AppIconStyles.iconPrimary(isDarkMode),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      'Ai có thể xem được bài chia sẻ của bạn?',
                      style: AppTextStyles.bodyTitle(isDarkMode)
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cài đặt này sẽ áp dụng cho tất cả các bài chia sẻ mà bạn đã chia sẻ',
                      style: AppTextStyles.bodySecondary(isDarkMode)
                    ),
                    const SizedBox(height: 20),
                    RadioListTile<PostPrivacy>(
                      title: Text(
                        PostPrivacy.everyone.displayName,
                        style: AppTextStyles.body(isDarkMode)
                      ),
                      value: PostPrivacy.everyone,
                      // Lựa chọn hiện tại đang được chọn
                      groupValue: _selectedSharedPostPrivacy,
                      onChanged: (PostPrivacy? value) {
                        if (value != null) {
                          setState(() {
                            _selectedSharedPostPrivacy = value;
                          });
                        }
                      },
                      activeColor: AppIconStyles.iconPrimary(isDarkMode),
                    ),
                    RadioListTile<PostPrivacy>(
                      title: Text(
                        PostPrivacy.myself.displayName,
                        style: AppTextStyles.body(isDarkMode)
                      ),
                      value: PostPrivacy.myself,
                      groupValue: _selectedSharedPostPrivacy,
                      onChanged: (PostPrivacy? value) {
                        if (value != null) {
                          setState(() {
                            _selectedSharedPostPrivacy = value;
                          });
                        }
                      },
                      activeColor: AppIconStyles.iconPrimary(isDarkMode),
                    ),
                    const SizedBox(height: 8),
                    RadioListTile<PostPrivacy>(
                      title: Text(
                        PostPrivacy.followers.displayName,
                        style: AppTextStyles.body(isDarkMode)
                      ),
                      value: PostPrivacy.followers,
                      groupValue: _selectedSharedPostPrivacy,
                      onChanged: (PostPrivacy? value) {
                        if (value != null) {
                          setState(() {
                            _selectedSharedPostPrivacy = value;
                          });
                        }
                      },
                      activeColor: AppIconStyles.iconPrimary(isDarkMode),
                    ),
                    const SizedBox(height: 30),
                    Center(
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _savePrivacySetting,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 15
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          backgroundColor: AppBackgroundStyles.buttonBackground(isDarkMode),
                          foregroundColor: AppTextStyles.buttonTextColor(isDarkMode)
                        ),
                        child:
                            _isSaving
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.buttonBg,
                                  ),
                                )
                                : const Text('Lưu thay đổi'),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
