import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:learnity/theme/theme.dart';
import 'package:learnity/theme/theme_provider.dart';

class GroupActivitySectionWidget extends StatelessWidget {
  final int postsTodayCount;
  final String membersInfo;
  final String creationInfo;

  const GroupActivitySectionWidget({
    super.key,
    required this.postsTodayCount,
    required this.membersInfo,
    required this.creationInfo,
  });

  Widget _buildActivityItem(
    bool isDarkMode, {
    required IconData icon,
    required String text,
    String? subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppBackgroundStyles.secondaryBackground(isDarkMode),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppIconStyles.iconPrimary(isDarkMode), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTextStyles.normalTextColor(isDarkMode),
                ),
              ),
              if (subtitle != null && subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: AppTextStyles.subTextColor(isDarkMode)),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Container(
      color: AppBackgroundStyles.mainBackground(isDarkMode),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hoạt động trong nhóm',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTextStyles.normalTextColor(isDarkMode),
            ),
          ),
          const SizedBox(height: 16),
          _buildActivityItem(
            isDarkMode,
            icon: Icons.article_outlined,
            text: '$postsTodayCount bài viết mới hôm nay',
          ),
          const SizedBox(height: 12),
          _buildActivityItem(isDarkMode, icon: Icons.people_outline, text: membersInfo),
          const SizedBox(height: 12),
          _buildActivityItem(isDarkMode, icon: Icons.groups_outlined, text: creationInfo),
        ],
      ),
    );
  }
}
