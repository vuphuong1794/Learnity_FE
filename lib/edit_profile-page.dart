import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/theme.dart';
import 'theme/theme_provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';


class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  File? _avatarImage;

  Future<void> _pickImage() async {
    // Dành cho Android 13 trở lên
    PermissionStatus status = await Permission.photos.request();

    if (status.isGranted) {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          _avatarImage = File(pickedFile.path);
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng cấp quyền để chọn ảnh')),
      );
      if (status.isPermanentlyDenied) {
        openAppSettings(); // mở cài đặt để cấp quyền thủ công
      }
    }
  }
  // File ? _selectedImage;
  // Future _pickImageFromGallery() async {
  //   final returnedImage = await ImagePicker().pickImage(source: ImageSource.gallery)
  // }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final backgroundColor = isDark ? AppColors.darkBackground : AppColors.background;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final buttonColor = isDark ? Colors.white : Colors.black;
    final buttonTextColor = isDark ? Colors.black : Colors.white;

    return Scaffold(
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
          style: TextStyle(color: textColor),
        ),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Colors.black),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _avatarImage != null
                    ? FileImage(_avatarImage!)
                    : AssetImage("assets/avatar.png") as ImageProvider,
              ),
            ),
            const SizedBox(height: 24),
            _buildLabeledField("Tên người dùng", textColor),
            const SizedBox(height: 16),
            _buildLabeledField("Họ và Tên", textColor),
            const SizedBox(height: 16),
            _buildLabeledField("Email", textColor),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              onPressed: () {
                // Save logic
              },
              child: Text("Lưu", style: TextStyle(color: buttonTextColor)),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Chế độ Darkmode", style: TextStyle(fontSize: 16, color: textColor)),
                const SizedBox(width: 12),
                IconButton(
                  icon: Icon(Icons.light_mode, color: isDark ? AppColors.background : AppColors.darkBackground),
                  onPressed: () {
                    themeProvider.setLightMode();
                  },
                ),
                IconButton(
                  icon: Icon(Icons.dark_mode, color: isDark ? AppColors.background : AppColors.darkBackground),
                  onPressed: () {
                    themeProvider.setDarkMode(true);
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLabeledField(String label, Color labelColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: labelColor, fontSize: 14)),
        const SizedBox(height: 6),
        TextField(
          style: const TextStyle(color: Colors.black),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.white),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: labelColor),
            ),
          ),
        ),
      ],
    );
  }

}
