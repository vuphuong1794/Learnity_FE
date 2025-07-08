import 'dart:developer';
import 'package:cloudinary_sdk/cloudinary_sdk.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:learnity/viewmodels/community_group_viewmodel.dart';
import 'package:learnity/viewmodels/post_viewmodel.dart';
import 'package:learnity/widgets/common/check_bad_words.dart';
import 'package:provider/provider.dart';
import 'package:learnity/theme/theme_provider.dart';
import 'package:learnity/theme/theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:learnity/models/group_post_model.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:get/get.dart';

import '../../api/group_api.dart';
import '../../api/user_apis.dart';

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
  final TextEditingController _titleController = TextEditingController();
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

  Widget _buildImageGrid() {
    if (_selectedImages.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          if (_selectedImages.length == 1)
            _buildSingleImage(_selectedImages[0], 0),
          if (_selectedImages.length >= 2) _buildMultipleImagesGrid(),
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
            child: Icon(Icons.close, color: Colors.white, size: 18),
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
                    child: Icon(Icons.close, color: Colors.white, size: 14),
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
                  child: Icon(Icons.close, color: Colors.white, size: 14),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // void _submitPost() async {
  //   if (_titleController.text.trim().isEmpty &&
  //       _contentController.text.trim().isEmpty &&
  //       _selectedImages.isEmpty) {
  //     Get.snackbar(
  //       "Lỗi",
  //       "Vui lòng nhập ít nhất một nội dung để đăng bài viết.",
  //       backgroundColor: Colors.blue.withOpacity(0.9),
  //       colorText: Colors.white,
  //       duration: const Duration(seconds: 2),
  //     );
  //     return;
  //   }

  //   // Kiểm tra từ bậy trong title và content
  //   if (CheckBadWords.containsBadWords(_titleController.text) ||
  //       CheckBadWords.containsBadWords(_contentController.text)) {
  //     Get.snackbar(
  //       "Không thể đăng bài",
  //       "Nội dung bài viết chứa từ ngữ không phù hợp.",
  //       backgroundColor: Colors.red.withOpacity(0.9),
  //       colorText: Colors.white,
  //       duration: const Duration(seconds: 2),
  //     );
  //     return;
  //   }

  //   if (!mounted) return;
  //   setState(() => _isPosting = true);

  //   final String? result = await _groupApi.createPostInGroup(
  //     groupId: widget.groupId,
  //     title: _titleController.text.trim(),
  //     text: _contentController.text.trim(),
  //     imageFiles: _selectedImages.isNotEmpty ? _selectedImages : null,
  //   );

  //   if (mounted) {
  //     if (result != null) {
  //       Get.back(result: true);

  //       if (result == 'approved') {
  //         Get.snackbar(
  //           "Thành công",
  //           "Đã đăng bài viết trong nhóm ${widget.groupName}!",
  //           backgroundColor: Colors.green.withOpacity(0.9),
  //           colorText: Colors.white,
  //           duration: const Duration(seconds: 2),
  //         );
  //       } else if (result == 'pending') {
  //         Get.snackbar(
  //           "Đã gửi thành công",
  //           "Bài viết của bạn đang chờ quản trị viên duyệt.",
  //           backgroundColor: Colors.blue.withOpacity(0.9),
  //           colorText: Colors.white,
  //           duration: const Duration(seconds: 2),
  //         );
  //       }
  //     } else {
  //       Get.snackbar(
  //         "Lỗi",
  //         "Không thể đăng bài viết. Vui lòng thử lại sau.",
  //         backgroundColor: Colors.blue.withOpacity(0.9),
  //         colorText: Colors.white,
  //         duration: const Duration(seconds: 2),
  //       );
  //     }

  //     setState(() => _isPosting = false);
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final mq = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: AppBackgroundStyles.mainBackground(isDarkMode),
      // appBar: AppBar(
      //   backgroundColor: AppBackgroundStyles.secondaryBackground(isDarkMode),
      //   iconTheme: IconThemeData(
      //     color: AppIconStyles.iconPrimary(isDarkMode), // Đổi màu mũi tên tại đây
      //   ),
      //   elevation: 0,
      // ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: mq.size.height - mq.padding.top - mq.padding.bottom,
            ),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Column(
                  children: [
                    // Image.asset('assets/learnity.png', height: 60),
                    // const SizedBox(height: 5),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          size: 28,
                          color: AppTextStyles.buttonTextColor(isDarkMode),
                        ),
                        onPressed: () {
                          Navigator.pop(context, true);
                        },
                      ),
                    ),
                    Text(
                      'Bài viết mới cho nhóm',
                      style: TextStyle(
                        color: AppTextStyles.normalTextColor(isDarkMode),
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.groupName,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTextStyles.subTextColor(isDarkMode),
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
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
                      CircleAvatar(
                        radius: 22,
                        backgroundImage:
                            (_fetchedUserAvatarUrl != null &&
                                    _fetchedUserAvatarUrl!.isNotEmpty)
                                ? NetworkImage(_fetchedUserAvatarUrl!)
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                            const SizedBox(height: 12),
                            // TextField cho chủ đề
                            TextField(
                              controller: _titleController,
                              decoration: InputDecoration(
                                hintText: 'Thêm chủ đề',
                                hintStyle: TextStyle(
                                  color: AppTextStyles.normalTextColor(
                                    isDarkMode,
                                  ).withOpacity(0.5),
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: TextStyle(
                                color: AppTextStyles.normalTextColor(
                                  isDarkMode,
                                ),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                              textCapitalization: TextCapitalization.sentences,
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _contentController,
                              decoration: InputDecoration(
                                hintText: 'Hãy đăng một gì đó?',
                                hintStyle: TextStyle(
                                  color: AppTextStyles.normalTextColor(
                                    isDarkMode,
                                  ).withOpacity(0.5),
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: TextStyle(
                                color: AppTextStyles.normalTextColor(
                                  isDarkMode,
                                ),
                                fontSize: 15,
                              ),
                              minLines: 3,
                              maxLines: 10,
                              keyboardType: TextInputType.multiline,
                              textCapitalization: TextCapitalization.sentences,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                _buildImageGrid(),
                // Hiển thị ảnh đã chọn (nếu có)
                if (_selectedImages.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Text(
                          '${_selectedImages.length}/$maxImages ảnh',
                          style: TextStyle(
                            color: AppTextStyles.normalTextColor(
                              isDarkMode,
                            ).withOpacity(0.7),
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
                                color: AppTextStyles.buttonTextColor(
                                  isDarkMode,
                                ),
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
                          color:
                              _selectedImages.length < maxImages
                                  ? AppTextStyles.buttonTextColor(isDarkMode)
                                  : AppTextStyles.buttonTextColor(
                                    isDarkMode,
                                  ).withOpacity(0.5),
                        ),
                        onPressed:
                            _selectedImages.length < maxImages
                                ? _pickImages
                                : null,
                      ),
                      const SizedBox(width: 18),
                      IconButton(
                        icon: Icon(
                          Icons.camera_alt_outlined,
                          size: 28,
                          color:
                              _selectedImages.length < maxImages
                                  ? AppTextStyles.buttonTextColor(isDarkMode)
                                  : AppTextStyles.buttonTextColor(
                                    isDarkMode,
                                  ).withOpacity(0.5),
                        ),
                        onPressed:
                            _selectedImages.length < maxImages
                                ? _captureImage
                                : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: ElevatedButton(
                    onPressed: () async {
                      await PostViewmodel().submitGroupPost(
                        context,
                        _selectedImages,
                        _titleController.text.trim(),
                        _contentController.text.trim(),
                        widget.groupId,
                        widget.groupName,
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
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
