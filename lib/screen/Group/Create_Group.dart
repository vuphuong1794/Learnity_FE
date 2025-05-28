import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_sdk/cloudinary_sdk.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:learnity/theme/theme.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vui lòng cấp quyền truy cập để chọn ảnh'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        if (storageStatus.isPermanentlyDenied ||
            photosStatus.isPermanentlyDenied) {
          await openAppSettings();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi chọn ảnh: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Cloudinary configuration
  final Cloudinary cloudinary = Cloudinary.full(
    apiKey: "186443578522722",
    apiSecret: "vuxXrro8h5VwdYCPFppAZUkB4oI",
    cloudName: "drbfk0it9",
  );

  Future<String?> _uploadToCloudinary(File imageFile) async {
    try {
      final response = await cloudinary.uploadFile(
        filePath: imageFile.path,
        resourceType: CloudinaryResourceType.image,
        folder:
            'Learnity/CommunityGroups/${FirebaseAuth.instance.currentUser?.uid}', // thư mục lưu trữ trên Cloudinary
        fileName:
            'avatar_${FirebaseAuth.instance.currentUser?.uid}', // tên file
        progressCallback: (count, total) {
          debugPrint('Uploading image: $count/$total');
        },
      );

      if (response.isSuccessful && response.secureUrl != null) {
        return response.secureUrl;
      } else {
        throw Exception('Upload failed: ${response.error}');
      }
    } catch (e) {
      debugPrint('Error uploading to Cloudinary: $e');
      rethrow;
    }
  }

  Future<void> _createGroup() async {
    if (_groupNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập tên nhóm'),
          duration: Duration(seconds: 2),
        ),
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
        avatarUrl = await _uploadToCloudinary(_avatarImage!);
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
          "isAdmin": true,
        },
      ];

      // Tạo nhóm trong collection 'groups'
      await _firestore.collection('groups').doc(groupId).set({
        "name": _groupNameController.text.trim(),
        "id": groupId,
        "members": membersList,
        "privacy": _selectedPrivacy,
        "avatarUrl": avatarUrl ?? "",
        "createdBy": currentUser.uid,
        "createdAt": FieldValue.serverTimestamp(),
      });

      // Thêm nhóm vào collection 'groups' của user
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('groups')
          .doc(groupId)
          .set({
            "name": _groupNameController.text.trim(),
            "id": groupId,
            "avatarUrl": avatarUrl ?? "",
            "privacy": _selectedPrivacy,
          });

      // Thêm tin nhắn thông báo tạo nhóm
      await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('chats')
          .add({
            "message":
                "${currentUser.displayName ?? userData['username']} đã tạo nhóm",
            "type": "notify",
            "time": FieldValue.serverTimestamp(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tạo nhóm thành công!'),
            duration: Duration(seconds: 2),
          ),
        );

        // Điều hướng về trang trước hoặc trang danh sách nhóm
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('Error creating group: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tạo nhóm: $e'),
            duration: const Duration(seconds: 3),
          ),
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Tạo nhóm',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 25,
          ),
        ),
        backgroundColor: AppColors.background,
        foregroundColor: Colors.black,
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
              const Text(
                'Chọn ảnh đại diện',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Center(
                  child:
                      _avatarImage == null
                          ? IconButton(
                            icon: const Icon(
                              Icons.add_a_photo,
                              size: 30,
                              color: Colors.grey,
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
              const Text(
                'Tên nhóm',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _groupNameController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  hintText: 'Đặt tên nhóm',
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Quyền riêng tư',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
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
                    backgroundColor: const Color(0xFF9EB9A8),
                    foregroundColor: Colors.black,
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
