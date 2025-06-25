import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../theme/theme.dart';
import '../../../../theme/theme_provider.dart';

class PasswordHelpScreen extends StatelessWidget {
  const PasswordHelpScreen({super.key});

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
          'Hướng dẫn đổi mật khẩu',
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
                'Bạn có thể dễ dàng thay đổi mật khẩu của mình bằng cách làm theo các bước dưới đây.',
                style: TextStyle(fontSize: 16, color: textColor),
              ),
              const SizedBox(height: 24),
              _buildStep(
                context,
                isDark,
                step: 1,
                title: 'Đi tới Trang Cá Nhân',
                description: 'Nhấn vào ảnh đại diện ở góc phải và chọn "Trang cá nhân".',
                icon: Icons.person_outline,
              ),
              _buildStep(
                context,
                isDark,
                step: 2,
                title: 'Chọn "Đổi mật khẩu"',
                description: 'Trong phần cài đặt, chọn mục "Đổi mật khẩu".',
                icon: Icons.lock_outline,
              ),
              _buildStep(
                context,
                isDark,
                step: 3,
                title: 'Nhập mật khẩu mới',
                description: 'Nhập mật khẩu hiện tại, mật khẩu mới và xác nhận lại.',
                icon: Icons.vpn_key_outlined,
              ),
              _buildStep(
                context,
                isDark,
                step: 4,
                title: 'Lưu thay đổi',
                description: 'Nhấn "Lưu" để hoàn tất việc đổi mật khẩu.',
                icon: Icons.check_circle_outline,
              ),
              const SizedBox(height: 30),
              Divider(color: Colors.grey.shade400),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.help_outline, color: AppIconStyles.iconPrimary(isDark)),
                  const SizedBox(width: 8),
                  Text(
                    'Bạn cần thêm trợ giúp?',
                    style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () {
                  // Điều hướng đến form hỗ trợ
                },
                icon: const Icon(Icons.mail_outline),
                label: const Text("Liên hệ với bộ phận hỗ trợ"),
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

  Widget _buildStep(BuildContext context, bool isDark, {
    required int step,
    required String title,
    required String description,
    required IconData icon,
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
                  '$step. $title',
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
