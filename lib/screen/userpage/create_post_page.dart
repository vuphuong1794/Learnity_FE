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

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }
  Future<void> _captureImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
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
                      const Text('Bài đăng mới', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(thickness: 1),
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
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _titleController,
                                decoration: const InputDecoration(
                                  hintText: 'Thêm chủ đề',
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                style: const TextStyle(fontSize: 15),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _contentController,
                                decoration: const InputDecoration(
                                  hintText: 'Hãy đăng một gì đó?',
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                style: const TextStyle(fontSize: 15),
                                minLines: 1,
                                maxLines: 3,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                              icon: const Icon(Icons.image_outlined, size: 28, color: Colors.black54),
                              onPressed: _pickImage,
                            ),
                        const SizedBox(width: 18),
                        
                        IconButton(
                              icon: const Icon(Icons.camera_alt_outlined, size: 28, color: Colors.black54),
                              onPressed: _captureImage,
                            ),                        
                        const SizedBox(width: 18),
                        
                        Icon(Icons.mic_outlined, size: 28, color: Colors.black54),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _submitPost,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    child: const Text('Đăng', style: TextStyle(color: Colors.white)),
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = FirebaseFirestore.instance.collection('posts').doc();
    final postId = docRef.id;

    final post = PostModel(
      postId: postId,
      username: user.displayName ?? user.email?.split('@').first ?? 'User',
      avatarUrl: user.photoURL ?? '',
      isVerified: false,
      postDescription: _titleController.text,
      content: _contentController.text,
      imageUrl: '', // Có thể cập nhật nếu chọn ảnh
      likes: 0,
      comments: 0,
      shares: 0,
      uid: user.uid,
      createdAt: DateTime.now(),
    );

    await docRef.set(post.toMap());
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SocialFeedPage()),
    );
  }
}