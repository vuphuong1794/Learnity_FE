import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../theme/theme.dart';
import '../../../../theme/theme_provider.dart';

class AppDeleteHelpScreen extends StatelessWidget {
  const AppDeleteHelpScreen({super.key});

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
          'Xóa ứng dụng',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
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
                'Nếu bạn muốn xóa ứng dụng khỏi thiết bị của mình, vui lòng làm theo các bước dưới đây:',
                style: TextStyle(fontSize: 16, color: textColor),
              ),
              const SizedBox(height: 24),
              _buildStep(
                isDark,
                icon: Icons.home_outlined,
                title: '1. Quay về màn hình chính',
                description: 'Thoát khỏi ứng dụng và trở về màn hình chính của thiết bị.',
              ),
              _buildStep(
                isDark,
                icon: Icons.touch_app_outlined,
                title: '2. Nhấn giữ biểu tượng ứng dụng',
                description: 'Tìm biểu tượng ứng dụng trên màn hình và nhấn giữ.',
              ),
              _buildStep(
                isDark,
                icon: Icons.delete_outline,
                title: '3. Chọn "Gỡ cài đặt" hoặc "Xóa"',
                description: 'Chọn tùy chọn xoá/gỡ ứng dụng trong menu hiện ra.',
              ),
              _buildStep(
                isDark,
                icon: Icons.check_circle_outline,
                title: '4. Xác nhận xoá',
                description: 'Xác nhận khi thiết bị hỏi bạn có muốn xóa ứng dụng không.',
              ),
              const SizedBox(height: 30),
              Divider(color: Colors.grey.shade400),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.info_outline, color: AppIconStyles.iconPrimary(isDark)),
                  const SizedBox(width: 8),
                  Text(
                    'Lưu ý trước khi xóa',
                    style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '• Dữ liệu của bạn có thể bị mất nếu không sao lưu trước.\n'
                    '• Một số thông tin vẫn được lưu nếu bạn đăng nhập bằng tài khoản.\n'
                    '• Bạn có thể cài lại ứng dụng bất kỳ lúc nào từ CH Play hoặc App Store.',
                style: TextStyle(color: textColor),
              ),
              const SizedBox(height: 30),
              Divider(color: Colors.grey.shade400),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.help_outline, color: AppIconStyles.iconPrimary(isDark)),
                  const SizedBox(width: 8),
                  Text(
                    'Cần hỗ trợ thêm?',
                    style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () {
                  // mở hộp thư hỗ trợ
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
            backgroundColor: isDark ? Colors.red.shade900 : Colors.red.shade100,
            child: Icon(icon, color: isDark ? Colors.white : Colors.red),
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
