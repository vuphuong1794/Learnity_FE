import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_sdk/cloudinary_sdk.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:learnity/config.dart';
import 'package:learnity/viewmodels/community_group_viewmodel.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

import 'package:provider/provider.dart';
import 'package:learnity/theme/theme.dart';
import 'package:learnity/theme/theme_provider.dart';

// .env
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CreateGroup extends StatefulWidget {
  const CreateGroup({super.key});

  @override
  State<CreateGroup> createState() => _CreateGroupState();
}

class _CreateGroupState extends State<CreateGroup> {
  File? _avatarImage;
  String _currentAvatarUrl = "";
  String _selectedPrivacy = 'Công khai';
  bool isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _groupNameController = TextEditingController();

  Future<void> _pickImage() async {
    try {
      PermissionStatus storageStatus = PermissionStatus.denied;
      PermissionStatus photosStatus = PermissionStatus.denied;

      if (Platform.isAndroid) {
        storageStatus = await Permission.storage.request();
      }

      photosStatus = await Permission.photos.request();

      if (storageStatus.isGranted || photosStatus.isGranted) {
        final picker = ImagePicker();
        final pickedFile = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 85,
        );

        if (pickedFile != null && mounted) {
          setState(() {
            _avatarImage = File(pickedFile.path);
          });
        }
      } else {
        if (mounted) {
          Get.snackbar(
            "Lỗi",
            "Vui lòng cấp quyền truy cập vào bộ nhớ hoặc ảnh để chọn ảnh đại diện.",
            backgroundColor: Colors.red.withOpacity(0.9),
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
        }
        if (storageStatus.isPermanentlyDenied ||
            photosStatus.isPermanentlyDenied) {
          await openAppSettings();
        }
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          "Lỗi",
          "Không thể chọn ảnh đại diện. Vui lòng thử lại sau.",
          backgroundColor: Colors.red.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }
    }
  }

  Future<void> _createGroup() async {
    if (_groupNameController.text.trim().isEmpty) {
      Get.snackbar(
        "Lỗi",
        "Vui lòng nhập tên nhóm.",
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      // Tạo groupId
      String groupId = const Uuid().v1();

      // Upload ảnh đại diện nếu có
      String? avatarUrl;
      if (_avatarImage != null) {
        final communityGroup = CommunityGroup();
        avatarUrl = await communityGroup.uploadToCloudinary(_avatarImage!);
      }

      // Lấy thông tin người dùng hiện tại
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      // Tạo danh sách thành viên (chỉ có người tạo)
      List<Map<String, dynamic>> membersList = [
        {
          "username": userData['username'],
          "email": userData['email'],
          "uid": userData['uid'],
          "avatarUrl": userData['avatarUrl'],
          "isAdmin": true,
        },
      ];

      // Thêm nhóm vào collection 'communityGroups'
      await _firestore.collection('communityGroups').doc(groupId).set({
        "name": _groupNameController.text.trim(),
        "id": groupId,
        "avatarUrl": avatarUrl ?? "",
        "privacy": _selectedPrivacy,
        "createdBy": currentUser.uid,
        "createdAt": FieldValue.serverTimestamp(),
        "membersCount": 1, // Số lượng thành viên ban đầu
        "membersList": membersList,
        "status": "active",
      });

      if (mounted) {
        Get.snackbar(
          "Thành công",
          "Tạo nhóm thành công!",
          backgroundColor: Colors.blue.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        // Điều hướng về trang trước hoặc trang danh sách nhóm
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('Error creating group: $e');
      if (mounted) {
        Get.snackbar(
          "Lỗi",
          "Không thể tạo nhóm. Vui lòng thử lại sau.",
          backgroundColor: Colors.blue.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: AppBackgroundStyles.mainBackground(isDarkMode),
      appBar: AppBar(
        backgroundColor: AppBackgroundStyles.secondaryBackground(isDarkMode),
        foregroundColor: AppTextStyles.normalTextColor(isDarkMode),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          'Tạo nhóm',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.black, height: 1.0),
        ),
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus(); // Dismiss keyboard on tap
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chọn ảnh đại diện',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTextStyles.normalTextColor(isDarkMode),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                height: 100,
                decoration: BoxDecoration(
                  color: AppBackgroundStyles.buttonBackgroundSecondary(
                    isDarkMode,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Center(
                  child:
                      _avatarImage == null
                          ? IconButton(
                            icon: Icon(
                              Icons.add_a_photo,
                              size: 30,
                              color: AppIconStyles.iconPrimary(isDarkMode),
                            ),
                            onPressed: _pickImage,
                          )
                          : GestureDetector(
                            onTap: _pickImage,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _avatarImage!,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Tên nhóm',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTextStyles.normalTextColor(isDarkMode),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                style: TextStyle(
                  color: AppTextStyles.normalTextColor(isDarkMode),
                ),
                controller: _groupNameController,
                decoration: InputDecoration(
                  hintText: 'Đặt tên nhóm',
                  hintStyle: TextStyle(
                    color: AppTextStyles.normalTextColor(
                      isDarkMode,
                    ).withOpacity(0.5),
                  ),

                  filled: true,
                  fillColor: AppBackgroundStyles.buttonBackgroundSecondary(
                    isDarkMode,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Quyền riêng tư',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTextStyles.normalTextColor(isDarkMode),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                style: TextStyle(
                  color: AppTextStyles.normalTextColor(isDarkMode),
                ),
                dropdownColor: AppBackgroundStyles.modalBackground(isDarkMode),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppBackgroundStyles.buttonBackgroundSecondary(
                    isDarkMode,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                value: _selectedPrivacy,
                items: const [
                  DropdownMenuItem(
                    value: 'Công khai',
                    child: Text('Công khai'),
                  ),
                  DropdownMenuItem(value: 'Riêng tư', child: Text('Riêng tư')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedPrivacy = value ?? 'Công khai';
                  });
                  if (kDebugMode) {
                    print('Selected privacy: $value');
                  }
                },
              ),
              const SizedBox(height: 32),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppBackgroundStyles.buttonBackground(
                      isDarkMode,
                    ),
                    foregroundColor: AppTextStyles.buttonTextColor(isDarkMode),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  onPressed: isLoading ? null : _createGroup,
                  child:
                      isLoading
                          ? const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.black,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text('Đang tạo...'),
                            ],
                          )
                          : const Text('Tạo nhóm'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
