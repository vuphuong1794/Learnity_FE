import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:learnity/theme/theme.dart';
import 'post_privacy_enum.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Lựa chọn riêng tư hiện tại, mặc định là everyone
  PostPrivacy _selectedPrivacy =
      PostPrivacy.everyone;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentPrivacySetting();
  }

  // Hàm tải cài đặt riêng tư hiện tại của người dùng từ DB
  Future<void> _loadCurrentPrivacySetting() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        final docSnapshot =
            await _firestore.collection('users').doc(currentUser.uid).get();
        if (docSnapshot.exists && docSnapshot.data() != null) {
          final data = docSnapshot.data()!;
          final String? currentSetting = data['view_permission'] as String?;
          _selectedPrivacy = PostPrivacyExtension.fromFirestoreValue(
            currentSetting,
          );
        } else {
          _selectedPrivacy = PostPrivacy.everyone;
        }
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          "Lỗi",
          "Không thể tải cài đặt hiện tại: ${e.toString()}",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
      _selectedPrivacy = PostPrivacy.everyone;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  // Hàm lưu cài đặt riêng tư mới của người dùng vào db
  Future<void> _savePrivacySetting() async {
    setState(() {
      _isSaving = true;
    });
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _firestore.collection('users').doc(currentUser.uid).set(
          {'view_permission': _selectedPrivacy.firestoreValue},
          SetOptions(merge: true),
        );

        if (mounted) {
          Get.snackbar(
            "Thành công",
            "Đã lưu cài đặt quyền riêng tư.",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
          Navigator.of(context).pop();
        }
      } else {
        throw Exception("Người dùng chưa đăng nhập.");
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          "Lỗi",
          "Không thể lưu cài đặt: ${e.toString()}",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
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
