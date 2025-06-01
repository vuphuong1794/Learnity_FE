import 'package:flutter/material.dart';

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

  Widget _buildActivityItem({
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
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.grey.shade600, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              if (subtitle != null && subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hoạt động trong nhóm',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          _buildActivityItem(
            icon: Icons.article_outlined,
            text: '$postsTodayCount bài viết mới hôm nay',
          ),
          const SizedBox(height: 12),
          _buildActivityItem(icon: Icons.people_outline, text: membersInfo),
          const SizedBox(height: 12),
          _buildActivityItem(icon: Icons.groups_outlined, text: creationInfo),
        ],
      ),
    );
  }
}
