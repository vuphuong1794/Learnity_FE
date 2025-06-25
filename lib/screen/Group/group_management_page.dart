import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../api/group_api.dart';

import 'package:provider/provider.dart';
import 'package:learnity/theme/theme.dart';
import 'package:learnity/theme/theme_provider.dart';

class GroupManagementPage extends StatefulWidget {
  final String groupId;

  const GroupManagementPage({super.key, required this.groupId});

  @override
  State<GroupManagementPage> createState() => _GroupManagementPageState();
}

class _GroupManagementPageState extends State<GroupManagementPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;
  final ImagePicker _picker = ImagePicker();
  late TextEditingController _groupNameController;

  String _groupPrivacy = 'Công khai';
  File? _avatarImageFile;
  String _currentAvatarUrl = '';
  final GroupApi _groupApi = GroupApi();

  @override
  void initState() {
    super.initState();
    _groupNameController = TextEditingController();
    _fetchGroupDetails();
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  Future<void> _fetchGroupDetails() async {
    setState(() => _isLoading = true);

    final detailsMap = await _groupApi.getGroupInfo(widget.groupId);

    if (mounted) {
      if (detailsMap != null) {
        setState(() {
          _groupNameController.text = detailsMap['name'] ?? '';
          _groupPrivacy = detailsMap['privacy'] ?? 'Công khai';
          _currentAvatarUrl = detailsMap['avatarUrl'] ?? '';
        });
      } else {
        Get.snackbar(
          'Lỗi',
          'Không thể tải chi tiết nhóm hoặc nhóm không tồn tại.',
        );
      }

      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final success = await _groupApi.uploadAvtGroup(
      groupId: widget.groupId,
      name: _groupNameController.text,
      privacy: _groupPrivacy,
      newAvatarFile: _avatarImageFile,
    );

    if (mounted) {
      if (success) {
        Get.snackbar('Thành công', 'Đã cập nhật thông tin nhóm.');
        Navigator.of(context).pop(true);
      } else {
        Get.snackbar('Lỗi', 'Không thể lưu thay đổi. Vui lòng thử lại.');
      }
      setState(() => _isSaving = false);
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
          _avatarImageFile = File(pickedFile.path);
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: AppBackgroundStyles.mainBackground(isDarkMode),
      appBar: AppBar(
        backgroundColor: AppBackgroundStyles.secondaryBackground(isDarkMode),
        foregroundColor: AppTextStyles.normalTextColor(isDarkMode),
        title: const Text(
          'Chỉnh sửa nhóm',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          if (!_isLoading)
            _isSaving
                ? const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                : TextButton(
                  onPressed: _saveChanges,
                  child: IconButton(
                    icon: Icon(Icons.save, color: AppIconStyles.iconPrimary(isDarkMode), size: 24,),
                    onPressed: _saveChanges,
                  ),
                ),
        ],
      ),
      body: Container(
        // color: AppColors.background,
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle(isDarkMode, 'Ảnh đại diện nhóm'),
                        const SizedBox(height: 16),
                        _buildAvatarSection(isDarkMode),
                        const SizedBox(height: 32),
                        _buildSectionTitle(isDarkMode, 'Thông tin cơ bản'),
                        const SizedBox(height: 16),
                        _buildTextField(
                          isDarkMode,
                          controller: _groupNameController,
                          label: 'Tên nhóm',
                          validator:
                              (value) =>
                                  (value == null || value.trim().isEmpty)
                                      ? 'Tên nhóm không được để trống'
                                      : null,
                        ),

                        const SizedBox(height: 32),
                        _buildSectionTitle(isDarkMode, 'Quyền riêng tư'),
                        _buildPrivacySettings(isDarkMode),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }

  Widget _buildAvatarSection(bool isDarkMode) {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey.shade300,
            backgroundImage:
                _avatarImageFile != null
                    ? FileImage(_avatarImageFile!) // Now displays the new image
                    : (_currentAvatarUrl.isNotEmpty
                            ? NetworkImage(_currentAvatarUrl)
                            : null)
                        as ImageProvider?,
            child:
                _avatarImageFile == null && _currentAvatarUrl.isEmpty
                    ? Icon(
                      Icons.group_work,
                      size: 50,
                      color: Colors.grey.shade600,
                    )
                    : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              // FIX: Correctly call the _pickImage method on tap.
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 20,
                backgroundColor: AppBackgroundStyles.buttonBackground(isDarkMode),
                child: Icon(
                  Icons.camera_alt,
                  color: AppIconStyles.iconPrimary(isDarkMode),
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(bool isDarkMode, String title) {
    return Text(
      title,
      style: TextStyle(
        color: AppTextStyles.normalTextColor(isDarkMode),
        fontWeight: FontWeight.bold,
        letterSpacing: 0.8,
        fontSize: 18,
      ),
    );
  }

  Widget _buildTextField(
    bool isDarkMode, {
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      style: TextStyle(
        color: AppTextStyles.normalTextColor(isDarkMode),
      ),
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: AppBackgroundStyles.buttonBackgroundSecondary(isDarkMode),
      ),
      validator: validator,
    );
  }

  Widget _buildPrivacySettings(bool isDarkMode) {
    return Column(
      children: [
        RadioListTile<String>(
          title: Text('Công khai', style: TextStyle(color: AppTextStyles.normalTextColor(isDarkMode))),
          subtitle: Text('Bất kỳ ai cũng có thể tìm và xem nhóm.', style: TextStyle(color: AppTextStyles.normalTextColor(isDarkMode))),
          value: 'Công khai',
          groupValue: _groupPrivacy,
          activeColor: AppIconStyles.iconPrimary(isDarkMode),
          onChanged: (value) => setState(() => _groupPrivacy = value!),
        ),
        RadioListTile<String>(
          title: Text('Riêng tư', style: TextStyle(color: AppTextStyles.normalTextColor(isDarkMode))),
          subtitle: Text('Chỉ thành viên mới có thể xem nội dung.', style: TextStyle(color: AppTextStyles.normalTextColor(isDarkMode))),
          value: 'Riêng tư',
          groupValue: _groupPrivacy,
          activeColor: AppIconStyles.iconPrimary(isDarkMode),
          onChanged: (value) => setState(() => _groupPrivacy = value!),
        ),
      ],
    );
  }
}
