import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:learnity/viewmodels/post_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:learnity/theme/theme_provider.dart';
import 'package:learnity/theme/theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:learnity/models/post_model.dart';
import 'package:learnity/screen/homePage/social_feed_page.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../api/user_apis.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;
  List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  String? _fetchedUserAvatarUrl;
  bool _isLoadingAvatar = true;
  String _usernameDisplay = "";
  final APIs _userApi = APIs();

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserAvatar();
  }

  static const int maxImages = 10;

  Future<void> _pickImages() async {
    try {
      if (_selectedImages.length >= maxImages) {
        Get.snackbar(
          "Thông báo",
          "Bạn chỉ có thể chọn tối đa $maxImages ảnh",
          backgroundColor: Colors.orange.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        return;
      }

      final remainingSlots = maxImages - _selectedImages.length;

      final pickedFiles = await _picker.pickMultiImage(
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFiles.isNotEmpty && mounted) {
        List<File> newImages = [];
        final imagesToAdd = pickedFiles.take(remainingSlots).toList();

        for (var pickedFile in imagesToAdd) {
          newImages.add(File(pickedFile.path));
        }

        setState(() {
          _selectedImages.addAll(newImages);
        });
        if (pickedFiles.length > remainingSlots) {
          Get.snackbar(
            "Thông báo",
            "Chỉ có thể thêm $remainingSlots ảnh nữa. Đã thêm ${imagesToAdd.length} ảnh.",
            backgroundColor: Colors.orange.withOpacity(0.9),
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
        }
      }
    } catch (e) {
      log('Error picking images: $e');
      if (mounted) {
        Get.snackbar(
          "Lỗi",
          "Không thể chọn ảnh: $e",
          backgroundColor: Colors.red.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }
    }
  }

  Future<void> _captureImage() async {
    try {
      if (_selectedImages.length >= maxImages) {
        Get.snackbar(
          "Thông báo",
          "Bạn chỉ có thể chọn tối đa $maxImages ảnh",
          backgroundColor: Colors.orange.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        return;
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        setState(() {
          _selectedImages.add(File(image.path));
        });
      }
    } catch (e) {
      log('Error capturing image: $e');
      if (mounted) {
        Get.snackbar(
          "Lỗi",
          "Không thể chụp ảnh: $e",
          backgroundColor: Colors.red.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _fetchCurrentUserAvatar() async {
    setState(() => _isLoadingAvatar = true);
    final avatarUrl = await _userApi.getCurrentUserAvatarUrl();
    final username = await _userApi.getCurrentUsername();
    if (mounted) {
      setState(() {
        _fetchedUserAvatarUrl = avatarUrl;
        _usernameDisplay = username ?? "User";
        _isLoadingAvatar = false;
      });
    }
  }

  Widget _buildImageGrid() {
    if (_selectedImages.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          if (_selectedImages.length == 1)
            _buildSingleImage(_selectedImages[0], 0),
          if (_selectedImages.length >= 2)
            _buildMultipleImagesGrid(),
        ],
      ),
    );
  }

  Widget _buildSingleImage(File image, int index) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            image,
            fit: BoxFit.cover,
            width: double.infinity,
            height: 200,
          ),
        ),
        IconButton(
          icon: const CircleAvatar(
            backgroundColor: Colors.black54,
            child: Icon(
              Icons.close,
              color: Colors.white,
              size: 18,
            ),
          ),
          onPressed: () => _removeImage(index),
        ),
      ],
    );
  }

  Widget _buildMultipleImagesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _selectedImages.length == 2 ? 2 : 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: _selectedImages.length > 4 ? 4 : _selectedImages.length,
      itemBuilder: (context, index) {
        if (index == 3 && _selectedImages.length > 4) {
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  _selectedImages[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.black54,
                ),
                child: Center(
                  child: Text(
                    '+${_selectedImages.length - 4}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => _removeImage(index),
                  child: const CircleAvatar(
                    backgroundColor: Colors.black54,
                    radius: 12,
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                _selectedImages[index],
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _removeImage(index),
                child: const CircleAvatar(
                  backgroundColor: Colors.black54,
                  radius: 12,
                  child: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final mq = MediaQuery.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppBackgroundStyles.mainBackground(isDarkMode),
        foregroundColor: AppTextStyles.normalTextColor(isDarkMode),
        elevation: 0,
      ),
      backgroundColor: AppBackgroundStyles.mainBackground(isDarkMode),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: mq.size.height - mq.padding.top - mq.padding.bottom,
            ),
              child: Column(
                children: [
                  // Logo
                  Column(
                    children: [
                      Text(
                        'Bài đăng mới',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: AppTextStyles.normalTextColor(isDarkMode),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Divider(
                    thickness: 1,
                    color: AppTextStyles.normalTextColor(
                      isDarkMode,
                    ).withOpacity(0.2),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundImage:
                                        (_fetchedUserAvatarUrl != null &&
                                                _fetchedUserAvatarUrl!
                                                    .isNotEmpty)
                                            ? NetworkImage(
                                              _fetchedUserAvatarUrl!,
                                            )
                                            : null,
                                    child:
                                        (_fetchedUserAvatarUrl == null ||
                                                _fetchedUserAvatarUrl!.isEmpty)
                                            ? Icon(
                                              Icons.person,
                                              size: 20,
                                              color: Colors.grey.shade700,
                                            )
                                            : null,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    _usernameDisplay,
                                    style: TextStyle(
                                      color: AppTextStyles.normalTextColor(
                                        isDarkMode,
                                      ),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _titleController,
                                decoration: InputDecoration(
                                  hintText: 'Thêm chủ đề',
                                  hintStyle: TextStyle(
                                    color: AppTextStyles.normalTextColor(
                                      isDarkMode,
                                    ),
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                style: TextStyle(
                                  fontSize: 15,
                                  color: AppTextStyles.normalTextColor(
                                    isDarkMode,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _contentController,
                                decoration: InputDecoration(
                                  hintText: 'Hãy đăng một gì đó?',
                                  hintStyle: TextStyle(
                                    color: AppTextStyles.normalTextColor(
                                      isDarkMode,
                                    ),
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                style: TextStyle(
                                  fontSize: 15,
                                  color: AppTextStyles.normalTextColor(
                                    isDarkMode,
                                  ),
                                ),
                                minLines: 1,
                                maxLines: 3,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Hiển thị grid ảnh đã chọn
                  _buildImageGrid(),

                  // Hiển thị số lượng ảnh đã chọn
                  if (_selectedImages.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Text(
                            '${_selectedImages.length}/$maxImages ảnh',
                            style: TextStyle(
                              color: AppTextStyles.normalTextColor(isDarkMode)
                                  .withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          if (_selectedImages.length < maxImages)
                            TextButton(
                              onPressed: _pickImages,
                              child: Text(
                                'Thêm ảnh',
                                style: TextStyle(
                                  color: AppTextStyles.buttonTextColor(isDarkMode),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.image_outlined,
                            size: 28,
                            color: _selectedImages.length < maxImages
                                ? AppTextStyles.buttonTextColor(isDarkMode)
                                : AppTextStyles.buttonTextColor(isDarkMode)
                                .withOpacity(0.5),
                          ),
                          onPressed: _selectedImages.length < maxImages
                              ? _pickImages
                              : null,
                        ),
                        const SizedBox(width: 18),
                        IconButton(
                          icon: Icon(
                            Icons.camera_alt_outlined,
                            size: 28,
                            color: _selectedImages.length < maxImages
                                ? AppTextStyles.buttonTextColor(isDarkMode)
                                : AppTextStyles.buttonTextColor(isDarkMode)
                                .withOpacity(0.5),
                          ),
                          onPressed: _selectedImages.length < maxImages
                              ? _captureImage
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () async {
                      await PostViewmodel().submitPost(
                        context,
                        _selectedImages,
                        _titleController.text.trim(),
                        _contentController.text.trim(),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppBackgroundStyles.buttonBackground(
                        isDarkMode,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      'Đăng',
                      style: TextStyle(
                        color: AppTextStyles.buttonTextColor(isDarkMode),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    );
  }
}