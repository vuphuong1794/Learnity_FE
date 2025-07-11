import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../models/group_post_model.dart';
import '../../theme/theme.dart';
import '../../widgets/menuPage/groupPage/group_activity_section_widget.dart';
import 'view_group_members_screen.dart';

class GroupInfoScreen extends StatelessWidget {
  final String groupId;
  final String groupName;
  final String groupDescription;
  final Timestamp? createdAt;
  final bool isDarkMode;

  final List<GroupPostModel> recentPosts;
  final List<Map<String, dynamic>> groupMembers;
  final Map<String, dynamic>? groupData;

  const GroupInfoScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.groupDescription,
    required this.createdAt,
    required this.isDarkMode,
    required this.recentPosts,
    required this.groupMembers,
    required this.groupData,
  });

  @override
  Widget build(BuildContext context) {
    final createdDate = createdAt?.toDate();
    final formattedDate = createdDate != null
        ? '${createdDate.day}/${createdDate.month}/${createdDate.year}'
        : 'Không xác định';

    final admins = groupMembers.where((m) => m['isAdmin'] == true).toList();
    final normalMembers = groupMembers.where((m) => m['isAdmin'] != true).toList();

    // Tính số bài viết hôm nay
    final today = DateTime.now();
    final postsTodayCount = recentPosts.where((post) {
      final postDate = post.createdAt;
      return postDate.year == today.year &&
          postDate.month == today.month &&
          postDate.day == today.day;
    }).length;

    Widget buildAvatarRow(List members) {
      final displayCount = members.length > 2 ? 2 : members.length;
      final extraCount = members.length - displayCount;

      List<Widget> avatars = List.generate(displayCount, (index) {
        final member = members[index];
        final avatarUrl = (member['avatarUrl'] ?? '').toString();
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: Colors.teal,
            backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
            child: avatarUrl.isEmpty
                ? const Icon(Icons.person, color: Colors.white, size: 16)
                : null,
          ),
        );
      });

      if (extraCount > 0) {
        avatars.add(
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade500,
              child: Text(
                '+$extraCount',
                style: const TextStyle(fontSize: 12, color: Colors.white),
              ),
            ),
          ),
        );
      }

      return Row(children: avatars);
    }

    String buildDisplayNames(List members) {
      final names = members.map((m) => m['username'] ?? 'Ẩn danh').toList();
      if (names.isEmpty) return '';
      if (names.length == 1) return names[0];
      if (names.length == 2) return '${names[0]} và ${names[1]}';
      return '${names[0]}, ${names[1]} và ${members.length - 2} người khác';
    }

    return Scaffold(
      backgroundColor: AppBackgroundStyles.mainBackground(isDarkMode),
      appBar: AppBar(
        backgroundColor: AppBackgroundStyles.secondaryBackground(isDarkMode),
        foregroundColor: AppTextStyles.normalTextColor(isDarkMode),
        title: Text(groupName),
        leading: const BackButton(),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              'Giới thiệu nhóm',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTextStyles.normalTextColor(isDarkMode),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              groupDescription.isNotEmpty
                  ? groupDescription
                  : 'Chưa có giới thiệu nhóm.',
              style: TextStyle(
                fontSize: 16,
                color: AppTextStyles.normalTextColor(isDarkMode),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Thành viên",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTextStyles.normalTextColor(isDarkMode),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ViewGroupMembersScreen(
                          groupId: groupId,
                          groupName: groupName,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    "Xem tất cả",
                    style: TextStyle(
                      color: AppTextStyles.buttonTextColor(isDarkMode),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (normalMembers.isNotEmpty) ...[
              buildAvatarRow(normalMembers),
              const SizedBox(height: 8),
              Text(
                '${buildDisplayNames(normalMembers)} đã tham gia',
                style: TextStyle(
                  fontSize: 15,
                  color: AppTextStyles.normalTextColor(isDarkMode),
                ),
              ),
              const SizedBox(height: 20),
            ],
            if (admins.isNotEmpty) ...[
              buildAvatarRow(admins),
              const SizedBox(height: 8),
              Text(
                '${buildDisplayNames(admins)} là quản trị viên.',
                style: TextStyle(
                  fontSize: 15,
                  color: AppTextStyles.normalTextColor(isDarkMode),
                ),
              ),
            ],
            const SizedBox(height: 32),
            GroupActivitySectionWidget(
              postsTodayCount: postsTodayCount,
              membersInfo: '${groupMembers.length} thành viên',
              creationInfo: 'Nhóm được tạo vào ngày $formattedDate',
            ),
          ],
        ),
      ),
    );
  }
}
