import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:learnity/theme/theme_provider.dart';
import 'package:learnity/theme/theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:learnity/models/group_post_model.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;

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
  final User? currentUser = FirebaseAuth.instance.currentUser;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isPosting = false;
  String? _fetchedUserAvatarUrl;
  bool _isLoadingAvatar = true;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserAvatar();
  }
  Future<void> _fetchCurrentUserAvatar() async {
    if (!mounted) return;
    setState(() {
      _isLoadingAvatar = true;
    });

    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        final userDoc =
        await _firestore.collection('users').doc(currentUser.uid).get();
        if (userDoc.exists && userDoc.data() != null && mounted) {
          setState(() {
            _fetchedUserAvatarUrl = userDoc.data()!['avatarUrl'] as String?;
            if (_fetchedUserAvatarUrl == null ||
                _fetchedUserAvatarUrl!.isEmpty) {
              _fetchedUserAvatarUrl = currentUser.photoURL;
            }
          });
        } else if (mounted) {
          setState(() {
            _fetchedUserAvatarUrl = currentUser.photoURL;
          });
        }
      } catch (e) {
        print("Lỗi khi lấy avatar người dùng cho CreatePostBar: $e");
        if (mounted) {
          setState(() {
            _fetchedUserAvatarUrl = currentUser.photoURL;
          });
        }
      }
    }
    if (mounted) {
      setState(() {
        _isLoadingAvatar = false;
      });
    }
  }
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

  Future<String?> _uploadImage(File imageFile, String postId) async {
    if (currentUser == null) return null;
    try {
      String fileName =
          'group_post_${widget.groupId}_${postId}_${DateTime.now().millisecondsSinceEpoch}${p.extension(imageFile.path)}';
      Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('group_posts_images')
          .child(widget.groupId)
          .child(fileName);

      UploadTask uploadTask = storageRef.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Lỗi tải ảnh lên: $e");
      Get.snackbar("Lỗi ảnh", "Không thể tải ảnh lên: ${e.toString()}");
      return null;
    }
  }

  void _submitPost() async {
    if (currentUser == null) {
      Get.snackbar("Lỗi", "Bạn cần đăng nhập để đăng bài.");
      return;
    }
    if (_titleController.text.trim().isEmpty &&
        _contentController.text.trim().isEmpty &&
        _selectedImage == null) {
      Get.snackbar("Lỗi", "Bài đăng cần có tiêu đề, nội dung hoặc hình ảnh.");
      return;
    }

    setState(() => _isPosting = true);

    String? imageUrl;
    final String postId =
        FirebaseFirestore.instance
            .collection('communityGroups')
            .doc(widget.groupId)
            .collection('posts')
            .doc()
            .id;

    if (_selectedImage != null) {
      imageUrl = await _uploadImage(_selectedImage!, postId);
      if (imageUrl == null && _selectedImage != null) {
        setState(() => _isPosting = false);
        return;
      }
    }

    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .get();
    String? authorUsername = currentUser!.displayName;
    String? authorAvatarUrl = currentUser!.photoURL;
    if (userDoc.exists) {
      final userData = userDoc.data() as Map<String, dynamic>;
      authorUsername =
          userData['displayName'] as String? ??
          userData['username'] as String? ??
          authorUsername;
      authorAvatarUrl = userData['avatarUrl'] as String? ?? authorAvatarUrl;
    }

    final post = GroupPostModel(
      postId: postId,
      groupId: widget.groupId,
      authorUid: currentUser!.uid,
      authorUsername: authorUsername,
      authorAvatarUrl: authorAvatarUrl,
      title:
          _titleController.text.trim().isNotEmpty
              ? _titleController.text.trim()
              : null,
      text:
          _contentController.text.trim().isNotEmpty
              ? _contentController.text.trim()
              : null,
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
    );

    try {
      await FirebaseFirestore.instance
          .collection('communityGroups')
          .doc(widget.groupId)
          .collection('posts')
          .doc(postId)
          .set(post.toMap());

      Get.back(result: true);
      Get.snackbar("Thành công", "Bài viết đã được đăng vào nhóm!");
    } catch (e) {
      print("Lỗi khi đăng bài vào nhóm: $e");
      Get.snackbar("Lỗi", "Không thể đăng bài: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final usernameDisplay =
        currentUser?.displayName ??
        currentUser?.email?.split('@').first ??
        'User';
    final avatarUrlDisplay = currentUser?.photoURL ?? '';

    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final mq = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: AppBackgroundStyles.mainBackground(isDarkMode),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
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
                        Image.asset('assets/learnity.png', height: 60),
                        const SizedBox(height: 5),
                        Text(
                          'Bài viết mới cho nhóm',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.groupName,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade700,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(thickness: 1),
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
                                  usernameDisplay,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // TextField cho chủ đề
                                TextField(
                                  controller: _titleController,
                                  decoration: const InputDecoration(
                                    hintText: 'Thêm chủ đề',
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textCapitalization:
                                      TextCapitalization.sentences,
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
                    if (_selectedImage != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Stack(
                          alignment: Alignment.topRight,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                _selectedImage!,
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
                                  () => setState(() => _selectedImage = null),
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
                            icon: const Icon(
                              Icons.image_outlined,
                              size: 28,
                              color: Colors.black54,
                            ),
                            onPressed: _isPosting ? null : _pickImage,
                          ),
                          const SizedBox(width: 18),
                          IconButton(
                            icon: const Icon(
                              Icons.camera_alt_outlined,
                              size: 28,
                              color: Colors.black54,
                            ),
                            onPressed: _isPosting ? null : _captureImage,
                          ),
                          const SizedBox(width: 18),
                          IconButton(
                            icon: const Icon(
                              Icons.mic_outlined,
                              size: 28,
                              color: Colors.black54,
                            ),
                            onPressed:
                                _isPosting
                                    ? null
                                    : () {
                                      Get.snackbar(
                                        'Thông báo',
                                        'Chức năng ghi âm sắp ra mắt!',
                                      );
                                    },
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
                        onPressed: _isPosting ? null : _submitPost,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          'Đăng',
                          style: TextStyle(color: Colors.white),
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
