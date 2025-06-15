import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../api/comment_thread_api.dart';
import '../../widgets/time_utils.dart';

class UserCommentList extends StatelessWidget {
  final String userId;
  const UserCommentList({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final commentService = CommentService();

    return FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
      future: commentService.fetchCommentsGroupedByPost(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Người này chưa có bình luận nào.'));
        }

        final groupedComments = snapshot.data!;

        return ListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: groupedComments.entries.map((entry) {
            final comments = entry.value;
            final firstComment = comments.first;

            final postAuthorName = firstComment['postAuthorName'] ?? 'Ẩn danh';
            final postAuthorAvatar = (firstComment['postAuthorAvatar'] != null &&
                firstComment['postAuthorAvatar'].toString().startsWith('http'))
                ? firstComment['postAuthorAvatar']
                : null;
            final postContent = firstComment['postContent'] ?? '[Không có nội dung]';
            final postTime = (firstComment['postCreateAt'] as Timestamp?)?.toDate();

            // Gộp bài viết + các comment vào cùng danh sách để vẽ đều
            final allEntries = [
              {
                'avatar': postAuthorAvatar,
                'name': postAuthorName,
                'content': postContent,
                'time': postTime,
                'isPost': true,
              },
              ...comments.map((c) => {
                'avatar': (c['userAvatar'] != null && c['userAvatar'].toString().startsWith('http'))
                    ? c['userAvatar']
                    : null,
                'name': c['username'] ?? 'Ẩn danh',
                'content': (c['content'] ?? '').toString().trim().isEmpty
                    ? '[Không có nội dung]'
                    : c['content'],
                'time': (c['createdAt'] as Timestamp?)?.toDate(),
                'isPost': false,
              })
            ];

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...List.generate(allEntries.length, (i) {
                    final item = allEntries[i];
                    final isLast = i == allEntries.length - 1;

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundImage: item['avatar'] != null &&
                                  item['avatar'].toString().startsWith('http')
                                  ? NetworkImage(item['avatar'])
                                  : null,
                              backgroundColor: Colors.grey.shade400,
                              child: (item['avatar'] == null || !item['avatar'].toString().startsWith('http'))
                                  ? const Icon(Icons.person, color: Colors.white)
                                  : null,
                            ),
                            if (!isLast)
                              Container(
                                width: 2,
                                height: 32,
                                color: Colors.grey.shade400,
                              ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item['name'],
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Text(
                                      item['time'] != null
                                          ? formatTime(item['time'])
                                          : '',
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(item['content']),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }),

                  const Divider(height: 32),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
