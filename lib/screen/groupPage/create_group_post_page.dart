import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:learnity/viewmodels/post_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:learnity/theme/theme_provider.dart';
import 'package:learnity/theme/theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart';

import '../../api/user_apis.dart';
import '../../api/group_api.dart';

class CreateGroupPostPage extends StatefulWidget {
  final String groupId;
  final String groupName;

  const CreateGroupPostPage({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<CreateGroupPostPage> createState() => _CreateGroupPostPageState();
}

class _CreateGroupPostPageState extends State<CreateGroupPostPage> {
  final TextEditingController _contentController = TextEditingController();
  final GroupApi _groupApi = GroupApi();
  final APIs _userApi = APIs();
  List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isPosting = false;
  String? _fetchedUserAvatarUrl;
  bool _isLoadingAvatar = true;
  String _usernameDisplay = "User";
  static const int maxImages = 10;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserAvatar();
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final mq = MediaQuery.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppBackgroundStyles.mainBackground(isDarkMode),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppTextStyles.normalTextColor(isDarkMode),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tạo bài viết mới',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTextStyles.normalTextColor(isDarkMode),
              ),
            ),
            Text(
              widget.groupName,
              style: TextStyle(
                fontSize: 14,
                color: AppTextStyles.subTextColor(isDarkMode),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton(
              onPressed: _isPosting
                  ? null
                  : () async {
                      setState(() => _isPosting = true);
                      await PostViewmodel().submitGroupPost(
                        context,
                        _selectedImages,
                        "", // title if needed
                        _contentController.text.trim(),
                        widget.groupId,
                        widget.groupName,
                      );
                      setState(() => _isPosting = false);
                    },
              style: TextButton.styleFrom(
                backgroundColor: _isPosting
                    ? Colors.grey
                    : AppBackgroundStyles.buttonBackground(isDarkMode),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: _isPosting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Đăng',
                      style: TextStyle(
                        color: AppTextStyles.buttonTextColor(isDarkMode),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
      backgroundColor: AppBackgroundStyles.mainBackground(isDarkMode),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // User info and post content
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundImage: (_fetchedUserAvatarUrl != null &&
                                _fetchedUserAvatarUrl!.isNotEmpty)
                            ? NetworkImage(_fetchedUserAvatarUrl!)
                            : null,
                        child: (_fetchedUserAvatarUrl == null ||
                                _fetchedUserAvatarUrl!.isEmpty)
                            ? Icon(
                                Icons.person,
                                size: 20,
                                color: Colors.grey.shade700,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _usernameDisplay,
                              style: TextStyle(
                                color: AppTextStyles.normalTextColor(isDarkMode),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _contentController,
                              decoration: InputDecoration(
                                hintText: 'Bạn đang nghĩ gì?',
                                hintStyle: TextStyle(
                                  color: AppTextStyles.normalTextColor(isDarkMode)
                                      .withOpacity(0.5),
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              style: TextStyle(
                                fontSize: 16,
                                color: AppTextStyles.normalTextColor(isDarkMode),
                              ),
                              minLines: 1,
                              maxLines: 10,
                              keyboardType: TextInputType.multiline,
                              textCapitalization: TextCapitalization.sentences,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  // Selected images grid
                  if (_selectedImages.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildImageGrid(),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          Text(
                            '${_selectedImages.length}/$maxImages ảnh',
                            style: TextStyle(
                              color: AppTextStyles.subTextColor(isDarkMode),
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
                  ],
                ],
              ),
            ),
          ),
          
          // Bottom action bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: AppTextStyles.normalTextColor(isDarkMode).withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.image_outlined,
                    size: 28,
                    color: _selectedImages.length < maxImages
                        ? AppTextStyles.buttonTextColor(isDarkMode)
                        : AppTextStyles.buttonTextColor(isDarkMode).withOpacity(0.5),
                  ),
                  onPressed: _selectedImages.length < maxImages
                      ? _pickImages
                      : null,
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    Icons.camera_alt_outlined,
                    size: 28,
                    color: _selectedImages.length < maxImages
                        ? AppTextStyles.buttonTextColor(isDarkMode)
                        : AppTextStyles.buttonTextColor(isDarkMode).withOpacity(0.5),
                  ),
                  onPressed: _selectedImages.length < maxImages
                      ? _captureImage
                      : null,
                ),
                const Spacer(),
                // Add other action buttons here if needed
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid() {
    if (_selectedImages.isEmpty) return const SizedBox.shrink();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _selectedImages.length == 1 ? 1 : 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: _selectedImages.length > 4 ? 4 : _selectedImages.length,
      itemBuilder: (context, index) {
        if (index == 3 && _selectedImages.length > 4) {
          return Stack(
            children: [
              _buildImageItem(_selectedImages[index]),
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
            ],
          );
        }
        return _buildImageItem(_selectedImages[index]);
      },
    );
  }

  Widget _buildImageItem(File image) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            image,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeImage(_selectedImages.indexOf(image)),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black54,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}