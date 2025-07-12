import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:learnity/api/post_tag_api.dart';
import 'package:learnity/viewmodels/post_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:learnity/theme/theme_provider.dart';
import 'package:learnity/theme/theme.dart';
import 'package:image_picker/image_picker.dart';
import '../../api/user_apis.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController _contentController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;
  List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  String? _fetchedUserAvatarUrl;
  bool _isLoadingAvatar = true;
  String _usernameDisplay = "";
  final APIs _userApi = APIs();

  List<String> _availableTags = [];
  List<String> _selectedTags = [];
  final ValueNotifier<List<String>> _selectedTagsNotifier = ValueNotifier([]);

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserAvatar();
    loadTags();
    _selectedTagsNotifier.value = _selectedTags;
  }

  Future<void> loadTags() async {
    final tags = await PostTagApi.fetchAvailableTags();
    setState(() {
      _availableTags = tags;
    });
  }

  void _showTagSelectionModal(bool isDarkMode, BuildContext context) {
    final TextEditingController _customTagController = TextEditingController();
    List<String> _tempSelectedTags = List.from(_selectedTagsNotifier.value);

    showModalBottomSheet(
      backgroundColor: AppBackgroundStyles.modalBackground(isDarkMode),
      context: context,
      isScrollControlled: true,
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
                    
                    // Ô nhập tag tùy chọn
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
                    
                    // Hiển thị các tag đã chọn trong modal
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
                    
                    // Danh sách tag có sẵn
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
                              : AppTextStyles.normalTextColor(isDarkMode) ,
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
                            _selectedTagsNotifier.value = List.from(_tempSelectedTags);
                            _selectedTags = List.from(_tempSelectedTags);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppBackgroundStyles.buttonBackground(isDarkMode), // Đổi màu nền tại đây
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
        title: Text(
          'Bài đăng mới',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10.0), // Giảm khoảng cách với mép phải
            child: TextButton(
              onPressed: () async {
                await PostViewmodel().submitPost(
                  context,
                  _selectedImages,
                  _contentController.text.trim(),
                  _selectedTags,
                );
              },
              style: TextButton.styleFrom(
                backgroundColor: AppBackgroundStyles.buttonBackground(isDarkMode),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
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
                  // Phần thông tin người dùng
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
                            // Nút thêm chủ đề
                            InkWell(
                              onTap: () => _showTagSelectionModal(isDarkMode, context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Thêm chủ đề',
                                      style: TextStyle(
                                        color: AppTextStyles.normalTextColor(isDarkMode),
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.add,
                                      size: 16,
                                      color: AppTextStyles.normalTextColor(isDarkMode),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  // Hiển thị các tag đã chọn
                  ValueListenableBuilder<List<String>>(
                    valueListenable: _selectedTagsNotifier,
                    builder: (context, tags, _) {
                      return tags.isNotEmpty
                          ? Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: tags.map((tag) {
                                  return Chip(
                                    label: Text(tag, style: TextStyle(color: AppTextStyles.normalTextColor(isDarkMode))),
                                    onDeleted: () {
                                      _selectedTagsNotifier.value = 
                                        List.from(tags)..remove(tag);
                                      _selectedTags = 
                                        List.from(tags)..remove(tag);
                                    },
                                    deleteIcon: Icon(Icons.close, size: 16, color: AppIconStyles.iconPrimary(isDarkMode),),
                                    backgroundColor: AppBackgroundStyles.buttonBackgroundSecondary(isDarkMode),
                                  );
                                }).toList(),
                              ),
                            )
                          : const SizedBox.shrink();
                    },
                  ),
                  
                  // Ô nhập nội dung
                  const SizedBox(height: 16),
                  TextField(
                    controller: _contentController,
                    decoration: InputDecoration(
                      hintText: 'Bạn đang nghĩ gì?',
                      hintStyle: TextStyle(
                        color: AppTextStyles.normalTextColor(isDarkMode)
                          .withOpacity(0.6),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTextStyles.normalTextColor(isDarkMode),
                    ),
                    minLines: 1,
                    maxLines: 10,
                    keyboardType: TextInputType.multiline,
                  ),
                  
                  // Hiển thị ảnh đã chọn
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
          
          // Thanh công cụ dưới cùng
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
                  onPressed: _selectedImages.length < maxImages ? _pickImages : null,
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
                  onPressed: _selectedImages.length < maxImages ? _captureImage : null,
                ),
                const Spacer(),
                if (_selectedTagsNotifier.value.length < 3)
                  TextButton(
                    onPressed: () => _showTagSelectionModal(isDarkMode, context),
                    style: TextButton.styleFrom(
                      backgroundColor: AppBackgroundStyles.buttonBackground(isDarkMode),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Thêm chủ đề',
                          style: TextStyle(
                            color: AppTextStyles.buttonTextColor(isDarkMode),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}