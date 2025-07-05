import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_sdk/cloudinary_sdk.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:learnity/config.dart';
import 'package:learnity/models/user_info_model.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:provider/provider.dart';
import 'package:learnity/theme/theme.dart';
import 'package:learnity/theme/theme_provider.dart';

// .env
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EditProfilePage extends StatefulWidget {
  final UserInfoModel? currentUser;

  const EditProfilePage({super.key, this.currentUser});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  File? _avatarImage;
  String _currentAvatarUrl = "";
  bool _isLoading = false;
  bool _isEmailUser = true;
  bool _obscurePassword = true;

  // Cloudinary configuration
  final Cloudinary cloudinary = Cloudinary.full(
    // apiKey: dotenv.env['CLOUDINARY_API_KEY1']!,
    // apiSecret: dotenv.env['CLOUDINARY_API_SECRET1']!,
    // cloudName: dotenv.env['CLOUDINARY_CLOUD_NAME1']!,
    apiKey: Config.cloudinaryApiKey1,
    apiSecret: Config.cloudinaryApiSecret1,
    cloudName: Config.cloudinaryCloudName1,
  );

  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // FocusNodes for smooth keyboard navigation
  final FocusNode _displayNameFocus = FocusNode();
  final FocusNode _bioFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _checkAuthProvider();
    _loadUserData();

    if (widget.currentUser != null) {
      _displayNameController.text = widget.currentUser!.displayName ?? '';
      _bioController.text = widget.currentUser!.bio ?? '';
      _currentAvatarUrl = widget.currentUser!.avatarUrl ?? '';
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    _passwordController.dispose();

    _displayNameFocus.dispose();
    _bioFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _checkAuthProvider() {
    final user = FirebaseAuth.instance.currentUser;
    final providers = user?.providerData.map((e) => e.providerId).toList();
    _isEmailUser = providers != null && providers.contains('password');
  }

  Future<void> _pickImage() async {
    try {
      PermissionStatus storageStatus = PermissionStatus.denied;
      PermissionStatus photosStatus = PermissionStatus.denied;

      if (Platform.isAndroid) {
        storageStatus = await Permission.storage.request();
      }

      photosStatus = await Permission.photos.request();

      if (storageStatus.isGranted || photosStatus.isGranted) {
        final picker = ImagePicker();
        final pickedFile = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 85,
        );

        if (pickedFile != null && mounted) {
          setState(() {
            _avatarImage = File(pickedFile.path);
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vui lòng cấp quyền truy cập để chọn ảnh'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        if (storageStatus.isPermanentlyDenied ||
            photosStatus.isPermanentlyDenied) {
          await openAppSettings();
        }
      }
    } catch (e) {
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

  Future<String?> _uploadToCloudinary(File imageFile) async {
    try {
      final response = await cloudinary.uploadFile(
        filePath: imageFile.path,
        resourceType: CloudinaryResourceType.image,
        folder:
            'Learnity/Users/${FirebaseAuth.instance.currentUser?.uid}', // thư mục lưu trữ trên Cloudinary
        fileName:
            'avatar_${FirebaseAuth.instance.currentUser?.uid}', // tên file
        progressCallback: (count, total) {
          debugPrint('Uploading image: $count/$total');
        },
      );

      if (response.isSuccessful && response.secureUrl != null) {
        return response.secureUrl;
      } else {
        throw Exception('Upload failed: ${response.error}');
      }
    } catch (e) {
      debugPrint('Error uploading to Cloudinary: $e');
      rethrow;
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      String avatarUrl = _currentAvatarUrl;

      if (_avatarImage != null) {
        final uploadedUrl = await _uploadToCloudinary(_avatarImage!);
        if (uploadedUrl != null) {
          avatarUrl = uploadedUrl;
        }
      }

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'displayName': _displayNameController.text.trim(),
        'bio': _bioController.text.trim(),
        'avatarUrl': avatarUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (_passwordController.text.isNotEmpty) {
        final user = FirebaseAuth.instance.currentUser;
        final providers = user?.providerData.map((e) => e.providerId).toList();

        if (providers != null && providers.contains('password')) {
          await user?.updatePassword(_passwordController.text.trim());
        } else {
          showSnackBar(
            'Tài khoản Google không thể đổi mật khẩu tại đây.',
            Colors.orange,
          );
        }
      }

      Get.snackbar(
        "Thành công",
        "Cập nhật trang cá nhân thành công!",
        backgroundColor: Colors.blue.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      showSnackBar('Lỗi: $e', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          setState(() {
            _displayNameController.text = data['displayName'] ?? '';
            _bioController.text = data['bio'] ?? '';
            _currentAvatarUrl = data['avatarUrl'] ?? '';
          });
        }
      }
    } catch (e) {
      showSnackBar('Lỗi tải dữ liệu: $e', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  ImageProvider _getAvatarImage() {
    if (_avatarImage != null) {
      return FileImage(_avatarImage!);
    } else if (_currentAvatarUrl.isNotEmpty) {
      return NetworkImage(_currentAvatarUrl);
    } else {
      return const AssetImage("assets/avatar.png");
    }
  }

  Widget _buildLabeledField(
    bool isDarkMode,
    String label,
    Color labelColor,
    TextEditingController controller, {
    FocusNode? focusNode,
    TextInputAction? inputAction,
    Function(String)? onFieldSubmitted,
    bool obscureText = false,
    bool enabled = true,
    Widget? suffixIcon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          focusNode: focusNode,
          textInputAction: inputAction,
          onSubmitted: onFieldSubmitted,
          obscureText: obscureText,
          enabled: enabled,
          maxLines: maxLines,
          style: TextStyle(
            color:
                enabled
                    ? AppTextStyles.buttonTextColor(isDarkMode)
                    : Colors.grey[600],
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor:
                enabled
                    ? AppBackgroundStyles.buttonBackgroundSecondary(isDarkMode)
                    : Colors.grey[300],
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: enabled ? Colors.grey.shade400 : Colors.grey,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: labelColor, width: 2),
            ),
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    final backgroundColor = AppBackgroundStyles.mainBackground(isDarkMode);
    final textColor = AppTextStyles.normalTextColor(isDarkMode);
    final buttonColor = AppBackgroundStyles.buttonBackground(isDarkMode);
    final buttonTextColor = AppTextStyles.buttonTextColor(isDarkMode);

    return GestureDetector(
      onTap: () {
        // Ẩn bàn phím khi chạm ngoài
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: backgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            "Chỉnh sửa trang cá nhân",
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Divider(
              height: 1,
              thickness: 1,
              color: Colors.grey.shade400,
            ),
          ),
        ),
        resizeToAvoidBottomInset: true,
        body:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 52,
                                backgroundImage: _getAvatarImage(),
                                backgroundColor: Colors.grey[200],
                              ),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppBackgroundStyles.buttonBackground(
                                    isDarkMode,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 4,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.camera_alt,
                                  color: AppTextStyles.buttonTextColor(
                                    isDarkMode,
                                  ),
                                  size: 22,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        _buildLabeledField(
                          isDarkMode,
                          "Tên người dùng",
                          textColor,
                          _displayNameController,
                          focusNode: _displayNameFocus,
                          inputAction: TextInputAction.next,
                          onFieldSubmitted: (_) {
                            _bioFocus.requestFocus();
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildLabeledField(
                          isDarkMode,
                          "Tiểu sử",
                          textColor,
                          _bioController,
                          focusNode: _bioFocus,
                          inputAction: TextInputAction.next,
                          maxLines: 3,
                          onFieldSubmitted: (_) {
                            if (_isEmailUser) {
                              _passwordFocus.requestFocus();
                            } else {
                              FocusScope.of(context).unfocus();
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildLabeledField(
                          isDarkMode,
                          "Mật khẩu",
                          textColor,
                          _passwordController,
                          focusNode: _passwordFocus,
                          obscureText: _obscurePassword,
                          enabled: _isEmailUser,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: AppTextStyles.buttonTextColor(isDarkMode),
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          inputAction: TextInputAction.done,
                          onFieldSubmitted: (_) {
                            FocusScope.of(context).unfocus();
                          },
                        ),
                        if (!_isEmailUser)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              "Tài khoản Google không thể đổi mật khẩu tại đây.",
                              style: TextStyle(color: Colors.orange[700]),
                            ),
                          ),
                        const SizedBox(height: 36),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: buttonColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              minimumSize: const Size.fromHeight(48),
                              elevation: 3,
                            ),
                            onPressed: _isLoading ? null : _saveProfile,
                            child: Text(
                              _isLoading ? 'Đang lưu...' : 'Lưu thay đổi',
                              style: TextStyle(
                                fontSize: 16,
                                color: buttonTextColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }
}
