import 'dart:developer';
import 'package:cloudinary_sdk/cloudinary_sdk.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  File? _imageToUpload;
  final ImagePicker _picker = ImagePicker();
  bool _isPosting = false;
  String? _fetchedUserAvatarUrl;
  bool _isLoadingAvatar = true;
  String _usernameDisplay = "User";

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

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null && mounted) {
        setState(() {
          _imageToUpload = File(pickedFile.path);
        });
      }
    } catch (e) {
      log('Error picking image: $e');
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
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (image != null && mounted) {
        setState(() {
          _imageToUpload = File(image.path);
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

  // Danh sách các từ cấm (tùy bạn mở rộng)
  final List<String> _badWords = [
    'chửi',
    'đm',
    'vkl',
    'vl',
    'cc',
    'shit',
    'fuck',
    'bitch',
    'ngu',
    'đần',
    'dốt',
    'địt',
    'lồn',
    'cặc',
    'đụ',
    'đéo',
    'má',
    'mẹ',
    'cút',
    'clm',
  ];

  // Hàm kiểm tra có chứa từ cấm hay không
  bool _containsBadWords(String text) {
    final lowerText = text.toLowerCase();
    return _badWords.any((word) => lowerText.contains(word));
  }

  void _submitPost() async {
    if (_titleController.text.trim().isEmpty &&
        _contentController.text.trim().isEmpty &&
        _imageToUpload == null) {
      Get.snackbar(
        "Lỗi",
        "Vui lòng nhập ít nhất một nội dung để đăng bài viết.",
        backgroundColor: Colors.blue.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    // Kiểm tra từ bậy trong title và content
    if (_containsBadWords(_titleController.text) ||
        _containsBadWords(_contentController.text)) {
      Get.snackbar(
        "Không thể đăng bài",
        "Nội dung bài viết chứa từ ngữ không phù hợp.",
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isPosting = true);

    final String? result = await _groupApi.createPostInGroup(
      groupId: widget.groupId,
      title: _titleController.text.trim(),
      text: _contentController.text.trim(),
      imageFile: _imageToUpload,
    );

    if (mounted) {
      if (result != null) {
        Get.back(result: true);

        if (result == 'approved') {
          Get.snackbar(
            "Thành công",
            "Đã đăng bài viết trong nhóm ${widget.groupName}!",
            backgroundColor: Colors.green.withOpacity(0.9),
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
        } else if (result == 'pending') {
          Get.snackbar(
            "Đã gửi thành công",
            "Bài viết của bạn đang chờ quản trị viên duyệt.",
            backgroundColor: Colors.blue.withOpacity(0.9),
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
        }
      } else {
        Get.snackbar(
          "Lỗi",
          "Không thể đăng bài viết. Vui lòng thử lại sau.",
          backgroundColor: Colors.blue.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }

      setState(() => _isPosting = false);
    }
  }

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
            child: IntrinsicHeight(
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
                                textCapitalization:
                                    TextCapitalization.sentences,
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
                                textCapitalization:
                                    TextCapitalization.sentences,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Hiển thị ảnh đã chọn (nếu có)
                  if (_imageToUpload != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Stack(
                        alignment: Alignment.topRight,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _imageToUpload!,
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
                            onPressed:
                                () => setState(() => _imageToUpload = null),
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
                            color: AppIconStyles.iconPrimary(isDarkMode),
                          ),
                          onPressed: _pickImage,
                        ),
                        const SizedBox(width: 18),
                        IconButton(
                          icon: Icon(
                            Icons.camera_alt_outlined,
                            size: 28,
                            color: AppIconStyles.iconPrimary(isDarkMode),
                          ),
                          onPressed: _isPosting ? null : _captureImage,
                        ),
                        // const SizedBox(width: 18),
                        // IconButton(
                        //   icon: Icon(
                        //     Icons.mic_outlined,
                        //     size: 28,
                        //     color: AppIconStyles.iconPrimary(isDarkMode),
                        //   ),
                        //   onPressed:
                        //       _isPosting
                        //           ? null
                        //           : () {
                        //             Get.snackbar(
                        //               'Thông báo',
                        //               'Chức năng ghi âm sắp ra mắt!',
                        //             );
                        //           },
                        // ),
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
                      onPressed: _isPosting ? null : _submitPost,
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
      ),
    );
  }
}
