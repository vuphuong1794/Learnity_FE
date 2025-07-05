import 'dart:convert';
import 'dart:io';

import 'package:cloudinary_sdk/cloudinary_sdk.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../api/user_apis.dart';
import '../../models/post_model.dart';

class EditPostPage extends StatefulWidget {
  final PostModel post;
  final VoidCallback? onPostUpdated;

  const EditPostPage({
    super.key,
    required this.post,
    this.onPostUpdated,
  });

  @override
  State<EditPostPage> createState() => _EditPostPageState();
}

class _EditPostPageState extends State<EditPostPage> {
  late TextEditingController _descController;
  late TextEditingController _contentController;

  List<String> oldImageUrls = [];
  List<File> newImages = [];
  final picker = ImagePicker();

  bool _isSaving = false;

  static const cloudName = 'drbfk0it9';
  static const uploadPreset = 'Learnity';

  @override
  void initState() {
    super.initState();
    _descController = TextEditingController(text: widget.post.postDescription);
    _contentController = TextEditingController(text: widget.post.content);
    oldImageUrls = List<String>.from(widget.post.imageUrls ?? []);
  }

  Future<void> _pickImages() async {
    final picked = await picker.pickMultiImage();
    if (picked != null && picked.isNotEmpty) {
      setState(() {
        newImages.addAll(picked.map((e) => File(e.path)));
      });
    }
  }

  void _removeOldImage(int index) {
    setState(() => oldImageUrls.removeAt(index));
  }

  void _removeNewImage(int index) {
    setState(() => newImages.removeAt(index));
  }

  Future<String?> uploadImageToCloudinary(File imageFile) async {
    try {
      final postId = widget.post.postId ?? 'unknown_post';
      final response = await APIs.cloudinary.uploadFile(
        filePath: imageFile.path,
        resourceType: CloudinaryResourceType.image,
        folder: 'Learnity/HomePosts/$postId',
        fileName: '${DateTime.now().millisecondsSinceEpoch}',
        progressCallback: (count, total) {
          debugPrint('Đang upload: $count/$total');
        },
      );

      if (response.isSuccessful && response.secureUrl != null) {
        return response.secureUrl;
      } else {
        debugPrint('❌ Upload thất bại: ${response.error}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Lỗi khi upload: $e');
      return null;
    }
  }


  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);

    List<String> uploadedImageUrls = [];

    try {
      for (File imageFile in newImages) {
        final url = await uploadImageToCloudinary(imageFile);
        if (url != null) {
          uploadedImageUrls.add(url);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Không thể upload ảnh: ${imageFile.path}')),
          );
        }
      }

      final updatedImageUrls = [...oldImageUrls, ...uploadedImageUrls];

      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.post.postId)
          .update({
        'postDescription': _descController.text.trim(),
        'content': _contentController.text.trim(),
        'imageUrls': updatedImageUrls,
      });

      widget.onPostUpdated?.call();
      Navigator.pop(context);
    } catch (e) {
      print('❌ Lỗi khi cập nhật bài viết: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xảy ra lỗi khi cập nhật bài viết')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chỉnh sửa bài viết')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Mô tả'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(labelText: 'Nội dung'),
              maxLines: null,
            ),
            const SizedBox(height: 16),
            const Text('Ảnh hiện tại:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(oldImageUrls.length, (index) {
                return Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Image.network(
                      oldImageUrls[index],
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red, size: 20),
                      onPressed: () => _removeOldImage(index),
                    ),
                  ],
                );
              }),
            ),
            const SizedBox(height: 16),
            const Text('Ảnh mới thêm:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(newImages.length, (index) {
                return Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Image.file(
                      newImages[index],
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red, size: 20),
                      onPressed: () => _removeNewImage(index),
                    ),
                  ],
                );
              }),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Thêm ảnh'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.upload),
                label: Text(_isSaving ? "Đang cập nhật..." : "Cập nhật bài viết"),
                onPressed: _isSaving ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
