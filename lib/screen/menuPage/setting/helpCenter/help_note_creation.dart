import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../theme/theme.dart';
import '../../../../theme/theme_provider.dart';

class NoteCreationHelpScreen extends StatelessWidget {
  const NoteCreationHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final textColor = AppTextStyles.normalTextColor(isDark);
    final bgColor = AppBackgroundStyles.mainBackground(isDark);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: AppBackgroundStyles.secondaryBackground(isDark),
        elevation: 0,
        leading: BackButton(color: AppIconStyles.iconPrimary(isDark)),
        title: Text(
          'Tạo ghi chú mới',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: ListView(
            children: [
              Text(
                'Làm theo các bước bên dưới để tạo một ghi chú mới trong ứng dụng của bạn.',
                style: TextStyle(fontSize: 16, color: textColor),
              ),
              const SizedBox(height: 24),
              _buildStep(
                isDark,
                icon: Icons.note_add_outlined,
                title: '1. Nhấn nút + hoặc biểu tượng ghi chú',
                description: 'Tại màn hình chính, tìm nút "+" hoặc biểu tượng "Ghi chú mới" để bắt đầu.',
              ),
              _buildStep(
                isDark,
                icon: Icons.edit_note_outlined,
                title: '2. Nhập nội dung ghi chú',
                description: 'Viết tiêu đề và nội dung cho ghi chú. Bạn có thể thêm danh sách, ảnh hoặc đính kèm nếu cần.',
              ),
              _buildStep(
                isDark,
                icon: Icons.save_alt_outlined,
                title: '3. Lưu ghi chú',
                description: 'Nhấn nút "Lưu" hoặc biểu tượng dấu check để hoàn tất việc tạo ghi chú.',
              ),
              const SizedBox(height: 30),
              Divider(color: Colors.grey.shade400),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.help_outline, color: AppIconStyles.iconPrimary(isDark)),
                  const SizedBox(width: 8),
                  Text(
                    'Gặp khó khăn?',
                    style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () {
                  // điều hướng đến hỗ trợ
                },
                icon: const Icon(Icons.mail_outline),
                label: const Text("Liên hệ bộ phận hỗ trợ"),
                style: TextButton.styleFrom(
                  foregroundColor: AppTextStyles.buttonTextColor(isDark),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(bool isDark, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: isDark ? Colors.blueGrey : Colors.blue.shade100,
            child: Icon(icon, color: isDark ? Colors.white : Colors.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTextStyles.normalTextColor(isDark)),
                ),
                const SizedBox(height: 4),
                Text(description, style: TextStyle(color: AppTextStyles.normalTextColor(isDark))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
