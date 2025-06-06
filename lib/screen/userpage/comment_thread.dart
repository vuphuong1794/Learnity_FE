import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/post_model.dart';
import '../../models/user_info_model.dart';
import '../../widgets/time_utils.dart';

class CommentThread extends StatefulWidget {
  final PostModel post;
  final String? sharedPostId;

  const CommentThread({
    super.key,
    required this.post,
    this.sharedPostId,
  });

  @override
  State<CommentThread> createState() => _CommentThreadState();
}

class _CommentThreadState extends State<CommentThread> {
  List<Map<String, dynamic>> comments = [];

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    final targetPostId = widget.sharedPostId ?? widget.post.postId;

    final snapshot = await FirebaseFirestore.instance
        .collection('shared_post_comments')
        .doc(targetPostId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .get();

    List<Map<String, dynamic>> loadedComments = [];

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final userId = data['userId'];
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      final userData = userDoc.exists ? userDoc.data() : null;

      loadedComments.add({
        'userId': userId,
        'username': userData?['displayName'] ?? 'Ẩn danh',
        'avatarUrl': userData?['avatarUrl'],
        'content': data['content'],
        'createdAt': (data['createdAt'] as Timestamp).toDate(),
      });
    }

    setState(() {
      comments = loadedComments;
    });
  }

  @override
  Widget build(BuildContext context) {
    final parentUser = UserInfoModel(
      displayName: widget.post.username,
      avatarUrl: widget.post.avatarUrl,
    );

    final parentPost = PostModel(
      content: widget.post.content,
      createdAt: widget.post.createdAt,
    );

    return Stack(
      children: [
        if (comments.isNotEmpty)
          Positioned(
            left: 35,
            top: 60,
            bottom: 85,
            child: Container(width: 2, color: Colors.black),
          ),
        Column(
          children: [
            _buildCommentBlock(user: parentUser, post: parentPost),
            const SizedBox(height: 8),
            ...comments.map((c) => _buildCommentBlock(
              user: UserInfoModel(
                displayName: c['username'],
                avatarUrl: c['avatarUrl'],
              ),
              post: PostModel(
                content: c['content'],
                createdAt: c['createdAt'],
              ),
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildCommentBlock({
    required UserInfoModel user,
    required PostModel post,
  }) {
    ImageProvider avatar;
    if (user.avatarUrl != null && user.avatarUrl!.startsWith('http')) {
      avatar = NetworkImage(user.avatarUrl!);
    } else if (user.avatarUrl != null && user.avatarUrl!.isNotEmpty) {
      avatar = AssetImage(user.avatarUrl!);
    } else {
      avatar = const AssetImage('assets/avatar.png');
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundImage: avatar,
            radius: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      user.displayName ?? "Không có tên",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      formatTime(post.createdAt),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(post.content ?? "không có nội dung"),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.favorite_border, size: 22),
                    const SizedBox(width: 4),
                    const Text("123"),
                    const SizedBox(width: 22),
                    Image.asset('assets/chat_bubble.png', width: 22),
                    const SizedBox(width: 4),
                    const Text("123"),
                    const SizedBox(width: 22),
                    Image.asset('assets/Share.png', width: 22),
                    const SizedBox(width: 4),
                    const Text("123"),
                    const SizedBox(width: 25),
                    Image.asset('assets/dots.png', width: 22),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
