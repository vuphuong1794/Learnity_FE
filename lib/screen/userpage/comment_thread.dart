import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../api/comment_thread_api.dart';
import '../../widgets/time_utils.dart';
import '../../models/post_model.dart';
import '../homePage/post_detail_page.dart';

class UserCommentList extends StatefulWidget {
  final String userId;
  const UserCommentList({super.key, required this.userId});

  @override
  State<UserCommentList> createState() => _UserCommentListState();
}

class _UserCommentListState extends State<UserCommentList> {
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

  Future<Map<String, dynamic>?> _getUserData(String? uid) async {
    if (uid == null) return null;
    final snapshot = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return snapshot.data();
  }

  @override
  Widget build(BuildContext context) {
    final commentService = CommentService();

    return FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
      future: commentService.fetchCommentsGroupedByPost(widget.userId),
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
            final comments = entry.value.where((comment) {
              final postMap = comment['post'] as Map<String, dynamic>?;
              if (postMap == null) return false;
              return postMap['isHidden'] != true;
            }).toList();

            if (comments.isEmpty) return const SizedBox.shrink();

            final firstComment = comments.first;
            final postAuthorId = firstComment['postAuthorId'];

            return FutureBuilder<Map<String, dynamic>?>(
              future: _getUserData(postAuthorId),
              builder: (context, authorSnapshot) {
                final postAuthorData = authorSnapshot.data;
                final postAuthorName = postAuthorData?['username'] ?? 'Ẩn danh';
                final postAuthorAvatar = postAuthorData?['avatarUrl'];
                final postContent = firstComment['postContent'] ?? '[Không có nội dung]';
                final postTime = (firstComment['postCreateAt'] as Timestamp?)?.toDate();

                final postEntry = {
                  'userId': postAuthorId,
                  'content': postContent,
                  'time': postTime,
                  'origin': {
                    'post': firstComment['post'],
                    'sharedPostId': firstComment['sharedPostId'],
                  }
                };

                final allEntries = [postEntry, ...comments];

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: allEntries.map((item) {
                      final userId = item['userId'];
                      final content = item['content'];
                      final time = item['time'] ?? (item['createdAt'] as Timestamp?)?.toDate();
                      final origin = item['origin'] ?? {
                        'post': item['post'],
                        'sharedPostId': item['sharedPostId']
                      };

                      return FutureBuilder<Map<String, dynamic>?>(
                        future: _getUserData(userId),
                        builder: (context, userSnapshot) {
                          final userData = userSnapshot.data;
                          final name = userData?['username'] ?? 'Ẩn danh';
                          final avatar = userData?['avatarUrl'];
                          final showAvatar = avatar != null && avatar.toString().startsWith('http');
                          final isLast = item == allEntries.last;

                          return GestureDetector(
                            onTap: () => _navigateToPostDetail(context, origin),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundImage: showAvatar ? NetworkImage(avatar) : null,
                                      backgroundColor: Colors.grey.shade400,
                                      child: !showAvatar
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
                                                name,
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                            Text(
                                              time != null ? formatTime(time) : '',
                                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(content == null || content.toString().trim().isEmpty
                                            ? '[Không có nội dung]'
                                            : content),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }
}


