
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme.dart';
import '../theme/theme_provider.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
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
          icon: const Icon(Icons.arrow_back, color: Colors.black),
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
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.black,
              child: Icon(Icons.camera_alt, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 24),
            _buildTextField("Tên người dùng", Colors.black),
            const SizedBox(height: 16),
            _buildTextField("Họ và Tên", Colors.black),
            const SizedBox(height: 16),
            _buildTextField("Email", Colors.black),
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

  Widget _buildTextField(String hint, Color textColor) {
    return TextField(
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: textColor),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: textColor),
        ),
      ),
    );
  }
}
