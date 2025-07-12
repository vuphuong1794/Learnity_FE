import 'dart:convert';
import 'dart:io';

import 'package:cloudinary_sdk/cloudinary_sdk.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:learnity/api/post_tag_api.dart';

import '../../api/user_apis.dart';
import '../../models/post_model.dart';

import 'package:provider/provider.dart';
import 'package:learnity/theme/theme.dart';
import 'package:learnity/theme/theme_provider.dart';

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
  List<String> _selectedTags = [];

  List<String> _availableTags = [];

  bool _isSaving = false;

  static const cloudName = 'drbfk0it9';
  static const uploadPreset = 'Learnity';

  @override
  void initState() {
    super.initState();
    _descController = TextEditingController(text: widget.post.postDescription);
    _contentController = TextEditingController(text: widget.post.content);
    oldImageUrls = List<String>.from(widget.post.imageUrls ?? []);
    loadTags();
    _selectedTags = List<String>.from(widget.post.tagList ?? []);
  }

  Future<void> loadTags() async {
    final tags = await PostTagApi.fetchAvailableTags();
    setState(() {
      _availableTags = tags;
    });
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

  void _removeTag(String tag) {
    setState(() {
      _selectedTags.remove(tag);
    });
  }

  Future<void> _showTagSelectionModal() async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;

    final TextEditingController _customTagController = TextEditingController();
    List<String> _tempSelectedTags = List.from(_selectedTags);

    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppBackgroundStyles.modalBackground(isDarkMode),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void updateTags(List<String> newTags) {
              _tempSelectedTags = newTags;
              setModalState(() {});
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Chọn chủ đề',
                          style: TextStyle(
                            color: AppTextStyles.normalTextColor(isDarkMode),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, 
                            color: AppTextStyles.normalTextColor(isDarkMode)),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Custom tag input
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _customTagController,
                            style: TextStyle(
                              color: AppTextStyles.normalTextColor(isDarkMode)),
                            decoration: InputDecoration(
                              hintText: 'Thêm tag tùy chọn',
                              hintStyle: TextStyle(
                                color: AppTextStyles.normalTextColor(isDarkMode)
                                  .withOpacity(0.5),
                              ),
                              filled: true,
                              fillColor: AppBackgroundStyles
                                .buttonBackgroundSecondary(isDarkMode),
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              counter: Builder(
                                builder: (context) {
                                  final currentLength = 
                                    _customTagController.text.length;
                                  return Text(
                                    '$currentLength/20',
                                    style: TextStyle(
                                      color: AppTextStyles.subTextColor(isDarkMode),
                                      fontSize: 12,
                                    ),
                                  );
                                },
                              ),
                            ),
                            maxLength: 20,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            Icons.add, 
                            color: AppIconStyles.iconPrimary(isDarkMode)),
                          onPressed: () {
                            if (_customTagController.text.trim().isNotEmpty) {
                              if (_tempSelectedTags.length >= 3) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Bạn chỉ có thể chọn tối đa 3 tag'),
                                  ),
                                );
                                return;
                              }
                              
                              if (!_tempSelectedTags.contains(
                                _customTagController.text.trim())) {
                                updateTags([
                                  ..._tempSelectedTags,
                                  _customTagController.text.trim()
                                ]);
                                _customTagController.clear();
                              }
                            }
                          },
                        ),
                      ],
                    ),
                    
                    // Selected tags in modal
                    if (_tempSelectedTags.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _tempSelectedTags.map((tag) {
                          return Chip(
                            label: Text(tag, style: TextStyle(color: AppTextStyles.normalTextColor(isDarkMode))),
                            onDeleted: () {
                              updateTags(
                                _tempSelectedTags.where((t) => t != tag).toList());
                            },
                            deleteIcon: Icon(Icons.close, size: 16, color: AppIconStyles.iconPrimary(isDarkMode),),
                            backgroundColor: AppBackgroundStyles.buttonBackgroundSecondary(isDarkMode),
                          );
                        }).toList(),
                      ),
                    ],
                    
                    // Available tags
                    const SizedBox(height: 16),
                    Text(
                      'Chọn từ danh sách:', 
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppTextStyles.normalTextColor(isDarkMode),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableTags.map((tag) {
                        final isSelected = _tempSelectedTags.contains(tag);
                        return FilterChip(
                          label: Text(tag),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected && _tempSelectedTags.length >= 3) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Bạn chỉ có thể chọn tối đa 3 tag'),
                                ),
                              );
                              return;
                            }
                            
                            if (selected) {
                              updateTags([..._tempSelectedTags, tag]);
                            } else {
                              updateTags(
                                _tempSelectedTags.where((t) => t != tag).toList());
                            }
                          },
                          selectedColor: AppBackgroundStyles.buttonBackgroundSecondary(isDarkMode),
                          backgroundColor: AppBackgroundStyles.buttonBackground(isDarkMode),
                          checkmarkColor: AppTextStyles.normalTextColor(isDarkMode),
                          labelStyle: TextStyle(
                            color: isSelected ? AppTextStyles.normalTextColor(isDarkMode) 
                              : AppTextStyles.normalTextColor(isDarkMode),
                          ),
                        );
                      }).toList(),
                    ),
                    
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Đã chọn ${_tempSelectedTags.length}/3',
                          style: TextStyle(
                            color: AppTextStyles.subTextColor(isDarkMode)),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context, _tempSelectedTags);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppBackgroundStyles.buttonBackground(isDarkMode),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text('Xác nhận', style: TextStyle(color: AppTextStyles.normalTextColor(isDarkMode))),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        _selectedTags = result;
      });
    }
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
        debugPrint(' Upload thất bại: ${response.error}');
        return null;
      }
    } catch (e) {
      debugPrint(' Lỗi khi upload: $e');
      return null;
    }
  }


  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);

    if (_selectedTags.isEmpty) {
      Get.snackbar(
        "Lỗi",
        "Vui lòng chọn ít nhất một chủ đề để đăng bài viết.",
        backgroundColor: Colors.blue.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      _isSaving = false;
      return;
    }

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

      
      if (_contentController.text.trim().isEmpty && updatedImageUrls.isEmpty) {
        Get.snackbar(
          "Lỗi",
          "Vui lòng nhập ít nhất một nội dung để đăng bài viết.",
          backgroundColor: Colors.blue.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        _isSaving = false;
        return;
      }

      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.post.postId)
          .update({
        'tagList': _selectedTags,
        'content': _contentController.text.trim(),
        'imageUrls': updatedImageUrls,
      });

      widget.onPostUpdated?.call();
      Navigator.pop(context);
    } catch (e) {
      print(' Lỗi khi cập nhật bài viết: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xảy ra lỗi khi cập nhật bài viết')),
      );
    } finally {
      // setState(() => _isSaving = false);
    }
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
        title: Text('Chỉnh sửa bài viết', style: TextStyle(color: AppTextStyles.normalTextColor(isDarkMode)))
        ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tags section
            Row(
              children: [
                Text(
                  'Chủ đề',
                  style: TextStyle(
                    color: AppTextStyles.normalTextColor(isDarkMode),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _showTagSelectionModal,
                  child: Text(
                    'Thay đổi chủ đề',
                    style: TextStyle(
                      color: AppTextStyles.buttonTextColor(isDarkMode),
                    ),
                  ),
                ),
              ],
            ),
            
            // Selected tags
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedTags.map((tag) {
                return Chip(
                  label: Text(tag, style: TextStyle(color: AppTextStyles.normalTextColor(isDarkMode)),),
                  onDeleted: () => _removeTag(tag),
                  deleteIcon: Icon(Icons.close, size: 16, color: AppIconStyles.iconPrimary(isDarkMode),),
                  backgroundColor: AppBackgroundStyles.buttonBackgroundSecondary(isDarkMode),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 16),

            // Nội dung
            Text(
              'Nội dung',
              style: TextStyle(
                color: AppTextStyles.normalTextColor(isDarkMode),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextField(
              controller: _contentController,
              style: TextStyle(color: AppTextStyles.normalTextColor(isDarkMode)),
              decoration: InputDecoration(
                hintText: 'Nhập nội dung',
                hintStyle: TextStyle(
                  color: AppTextStyles.normalTextColor(isDarkMode).withOpacity(0.5),
                ),
              ),
              maxLines: null,
            ),
            const SizedBox(height: 16),

            // Ảnh hiện tại
            Text(
              'Ảnh',
              style: TextStyle(
                color: AppTextStyles.normalTextColor(isDarkMode),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Gom ảnh cũ và mới
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(oldImageUrls.length + newImages.length, (index) {
                final isOldImage = index < oldImageUrls.length;

                return Stack(
                  alignment: Alignment.topRight,
                  children: [
                    isOldImage
                        ? Image.network(
                            oldImageUrls[index],
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          )
                        : Image.file(
                            newImages[index - oldImageUrls.length],
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red, size: 20),
                      onPressed: () {
                        if (isOldImage) {
                          _removeOldImage(index);
                        } else {
                          _removeNewImage(index - oldImageUrls.length);
                        }
                      },
                    ),
                  ],
                );
              }),
            ),

            const SizedBox(height: 12),

            // Nút thêm ảnh
            TextButton.icon(
              onPressed: _pickImages,
              icon: Icon(Icons.add_photo_alternate, color: AppIconStyles.iconPrimary(isDarkMode)),
              label: Text('Thêm ảnh', style: TextStyle(color: AppTextStyles.normalTextColor(isDarkMode))),
            ),
            const SizedBox(height: 24),

            // Nút cập nhật
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.upload),
                label: Text(_isSaving ? "Đang cập nhật..." : "Cập nhật bài viết", style: TextStyle(color: AppTextStyles.buttonTextColor(isDarkMode)),),
                onPressed: _isSaving ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: AppBackgroundStyles.buttonBackground(isDarkMode),
                  foregroundColor: AppTextStyles.buttonTextColor(isDarkMode),
                  elevation: 4,
                  shadowColor: Colors.black.withOpacity(0.4),
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
