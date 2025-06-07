import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:learnity/theme/theme.dart';
import '../../api/user_apis.dart';
import 'post_privacy_enum.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  // Lựa chọn riêng tư hiện tại, mặc định là everyone
  PostPrivacy _selectedPrivacy =
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
    if (mounted) {
      setState(() {
        _selectedPrivacy = currentSetting;
        _isLoading = false;
      });
    }
  }
  // Hàm lưu cài đặt riêng tư mới của người dùng vào db
  Future<void> _savePrivacySetting() async {
    setState(() => _isSaving = true);
    final success = await _userApi.savePostPrivacySetting(_selectedPrivacy);
    if (mounted) {
      if (success) {
        Get.snackbar(
          "Thành công",
          "Đã lưu cài đặt quyền riêng tư.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        Navigator.of(context).pop();
      } else {
        Get.snackbar(
          "Lỗi",
          "Không thể lưu cài đặt. Vui lòng thử lại.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Cài đặt quyền riêng tư bài viết',
          style: TextStyle(color:  AppColors.black),
        ),
        centerTitle: true,
        backgroundColor:  AppColors.background,
        elevation: 1,
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
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color:  AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cài đặt này sẽ áp dụng cho tất cả các bài viết mà bạn đã đăng',
                      style: TextStyle(
                        fontSize: 14,
                        color:  AppColors.black.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 20),
                    RadioListTile<PostPrivacy>(
                      title: Text(
                        PostPrivacy.everyone.displayName,
                        style: TextStyle(color: AppColors.black),
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
                      activeColor:
                          Theme.of(
                            context,
                          ).primaryColor,
                    ),
                    RadioListTile<PostPrivacy>(
                      title: Text(
                        PostPrivacy.myself.displayName,
                        style: TextStyle(color:AppColors.black),
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
                      activeColor:
                          Theme.of(
                            context,
                          ).primaryColor,
                    ),
                    const SizedBox(height: 8),
                    RadioListTile<PostPrivacy>(
                      title: Text(
                        PostPrivacy.followers.displayName,
                        style: TextStyle(color:AppColors.black),
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
                      activeColor:
                      Theme.of(
                        context,
                      ).primaryColor,
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
                          backgroundColor: AppColors.buttonBg,
                          foregroundColor: AppColors.buttonText
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
