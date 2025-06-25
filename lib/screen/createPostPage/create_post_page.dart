import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  File? _imageToUpload;

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi chọn ảnh: $e'),
            duration: const Duration(seconds: 3),
          ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error capturing image: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    final username = user?.displayName ?? user?.email?.split('@').first ?? 'User';
    final avatarUrl = user?.photoURL ?? '';
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final mq = MediaQuery.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppBackgroundStyles.mainBackground(isDarkMode),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppIconStyles.iconPrimary(isDarkMode)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: AppBackgroundStyles.mainBackground(isDarkMode),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: mq.size.height - mq.padding.top - mq.padding.bottom),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  // Logo
                  Column(
                    children: [
                      Image.asset('assets/learnity.png', height: 60),
                      const SizedBox(height: 5),
                      Text('Bài đăng mới', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTextStyles.normalTextColor(isDarkMode))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Divider(thickness: 1, color: AppTextStyles.normalTextColor(isDarkMode),),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                                    backgroundColor: Colors.grey,
                                    backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                                    child: avatarUrl.isEmpty ? Icon(Icons.person, color: Colors.white) : null,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    username,
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTextStyles.normalTextColor(isDarkMode)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _titleController,
                                decoration: InputDecoration(
                                  hintText: 'Thêm chủ đề',
                                  hintStyle: TextStyle(
                                    color: AppTextStyles.normalTextColor(isDarkMode),         // 🎯 đổi màu hint text
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                style: TextStyle(fontSize: 15, color: AppTextStyles.normalTextColor(isDarkMode)),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _contentController,
                                decoration: InputDecoration(
                                  hintText: 'Hãy đăng một gì đó?',
                                  hintStyle: TextStyle(
                                    color: AppTextStyles.normalTextColor(isDarkMode),         // 🎯 đổi màu hint text
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                style: TextStyle(fontSize: 15, color: AppTextStyles.normalTextColor(isDarkMode)),
                                minLines: 1,
                                maxLines: 3,
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                              icon: Icon(Icons.image_outlined, size: 28, color: AppTextStyles.buttonTextColor(isDarkMode)),
                              onPressed: _pickImage,
                            ),
                        const SizedBox(width: 18),
                        
                        IconButton(
                              icon: Icon(Icons.camera_alt_outlined, size: 28, color: AppTextStyles.buttonTextColor(isDarkMode)),
                              onPressed: _captureImage,
                            ),                        
                        const SizedBox(width: 18),
                        
                        Icon(Icons.mic_outlined, size: 28, color: AppTextStyles.buttonTextColor(isDarkMode)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _submitPost,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppBackgroundStyles.buttonBackground(isDarkMode),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    child: Text('Đăng', style: TextStyle(color: AppTextStyles.buttonTextColor(isDarkMode))),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submitPost() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final APIs _userApi = APIs();
    final success = await _userApi.createPostOnHomePage(
      title: title,
      text: content,
      imageFile: _imageToUpload,
    );

    if (success != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng bài thành công!')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SocialFeedPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng bài thất bại. Vui lòng thử lại.')),
      );
    }
  }
}