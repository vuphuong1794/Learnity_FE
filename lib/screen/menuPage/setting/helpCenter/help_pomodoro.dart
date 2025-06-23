import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../theme/theme.dart';
import '../../../../theme/theme_provider.dart';

class PomodoroHelpScreen extends StatelessWidget {
  const PomodoroHelpScreen({super.key});

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
          'Pomodoro hoạt động như thế nào?',
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
                'Kỹ thuật Pomodoro giúp bạn tập trung tốt hơn bằng cách chia thời gian học/làm việc thành các chu kỳ có kiểm soát.',
                style: TextStyle(fontSize: 16, color: textColor),
              ),
              const SizedBox(height: 24),
              _buildStep(
                isDark,
                icon: Icons.timer_outlined,
                title: '1. Đặt thời gian Pomodoro (25 phút)',
                description: 'Chọn công việc và bắt đầu đếm ngược trong 25 phút. Không bị gián đoạn.',
              ),
              _buildStep(
                isDark,
                icon: Icons.check_circle_outline,
                title: '2. Làm việc tập trung',
                description: 'Chỉ làm đúng 1 việc trong suốt thời gian đó. Tạm dừng thông báo nếu cần.',
              ),
              _buildStep(
                isDark,
                icon: Icons.coffee_outlined,
                title: '3. Nghỉ ngắn (5 phút)',
                description: 'Sau mỗi phiên, bạn được nghỉ ngắn. Thư giãn, đi lại hoặc uống nước.',
              ),
              _buildStep(
                isDark,
                icon: Icons.access_time,
                title: '4. Lặp lại 4 lần rồi nghỉ dài',
                description: 'Sau 4 phiên Pomodoro, hãy nghỉ dài hơn (15-30 phút).',
              ),
              const SizedBox(height: 20),
              Divider(color: Colors.grey.shade400),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: AppIconStyles.iconPrimary(isDark)),
                  const SizedBox(width: 8),
                  Text(
                    'Mẹo tối ưu Pomodoro',
                    style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '• Sử dụng tai nghe chống ồn\n'
                    '• Ghi chú lại mỗi phiên đã hoàn thành\n'
                    '• Đừng bỏ qua nghỉ giữa giờ',
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
                    'Cần thêm trợ giúp?',
                    style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () {
                  // điều hướng đến trang hỗ trợ
                },
                icon: const Icon(Icons.support_agent_outlined),
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
            backgroundColor: isDark ? Colors.teal.shade700 : Colors.teal.shade100,
            child: Icon(icon, color: isDark ? Colors.white : Colors.teal),
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
