import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../api/comment_thread_api.dart';
import '../../widgets/time_utils.dart';
import '../../models/post_model.dart';
import '../homePage/post_detail_page.dart';

class UserCommentList extends StatelessWidget {
  final String userId;
  const UserCommentList({super.key, required this.userId});

  void _navigateToPostDetail(BuildContext context, Map<String, dynamic> originData) {
    final postMap = originData['post'] as Map<String, dynamic>?;
    if (postMap == null) {
      debugPrint("Không có dữ liệu bài viết trong comment.");
      return;
    }

    try {
      final post = PostModel.fromMap(postMap);
      final sharedPostId = originData['sharedPostId'];
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PostDetailPage(
            post: post,
            isDarkMode: Theme.of(context).brightness == Brightness.dark,
            sharedPostId: sharedPostId,
          ),
        ),
      );
    } catch (e) {
      debugPrint("Lỗi chuyển trang PostDetailPage: $e");
    }
  }

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
            final postAuthorAvatar = firstComment['postAuthorAvatar'];
            final postContent = firstComment['postContent'] ?? '[Không có nội dung]';
            final postTime = (firstComment['postCreateAt'] as Timestamp?)?.toDate();

            final allEntries = [
              {
                'avatar': postAuthorAvatar,
                'name': postAuthorName,
                'content': postContent,
                'time': postTime,
                'origin': {
                  'post': firstComment['post'], // cần đảm bảo chứa post
                  'sharedPostId': firstComment['sharedPostId'],
                }
              },
              ...comments.map((c) => {
                'avatar': c['userAvatar'],
                'name': c['username'] ?? 'Ẩn danh',
                'content': (c['content'] ?? '').toString().trim().isEmpty
                    ? '[Không có nội dung]'
                    : c['content'],
                'time': (c['createdAt'] as Timestamp?)?.toDate(),
                'origin': {
                  'post': c['post'],
                  'sharedPostId': c['sharedPostId'],
                }
              }),
            ];

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...List.generate(allEntries.length, (i) {
                    final item = allEntries[i];
                    final isLast = i == allEntries.length - 1;
                    final avatarUrl = item['avatar'];
                    final showNetworkAvatar = avatarUrl != null && avatarUrl.toString().startsWith('http');

                    return GestureDetector(
                      onTap: () => _navigateToPostDetail(context, item['origin']),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Avatar + line
                          Column(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundImage: showNetworkAvatar ? NetworkImage(avatarUrl) : null,
                                backgroundColor: Colors.grey.shade400,
                                child: !showNetworkAvatar
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
                          // Nội dung
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
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Text(
                                        item['time'] != null ? formatTime(item['time']) : '',
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                      ),
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
