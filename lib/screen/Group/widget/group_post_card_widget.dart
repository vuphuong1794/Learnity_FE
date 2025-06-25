import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:provider/provider.dart';
import 'package:learnity/theme/theme.dart';
import 'package:learnity/theme/theme_provider.dart';

class GroupPostCardWidget extends StatelessWidget {
  final String userName;
  final String userAvatarUrl;
  final String? postTitle;
  final String postText;
  final String? postImageUrl;
  final String timestamp;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final bool isLikedByCurrentUser;
  final VoidCallback onLikePressed;
  final VoidCallback onCommentPressed;
  final VoidCallback onSharePressed;
  final String postAuthorUid;
  final VoidCallback onDeletePost;

  const GroupPostCardWidget({
    super.key,
    required this.userName,
    required this.userAvatarUrl,
    this.postTitle,
    required this.postText,
    this.postImageUrl,
    required this.timestamp,
    required this.likesCount,
    required this.commentsCount,
    required this.sharesCount,
    required this.isLikedByCurrentUser,
    required this.onLikePressed,
    required this.onCommentPressed,
    required this.onSharePressed,
    required this.postAuthorUid,
    required this.onDeletePost,
  });

  void _showPostOptionsMenuAtTap(BuildContext context, Offset tapPosition) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwner = currentUser != null && currentUser.uid == postAuthorUid;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        tapPosition.dx,
        tapPosition.dy,
        tapPosition.dx,
        0,
      ),
      items: [
        if (isOwner)
          const PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline, color: Colors.red),
                SizedBox(width: 10),
                Text('Xóa bài viết', style: TextStyle(color: Colors.red)),
              ],
            ),
          )
        else
          const PopupMenuItem<String>(
            value: 'report',
            child: Row(
              children: [
                Icon(Icons.report_gmailerrorred_outlined, color: Colors.orange),
                SizedBox(width: 10),
                Text(
                  'Báo cáo bài viết',
                  style: TextStyle(color: Colors.orange),
                ),
              ],
            ),
          ),
      ],
    ).then((value) {
      if (value == 'delete') {
        _confirmDelete(context);
      } else if (value == 'report') {
        _showReportDialog(context);
      }
    });
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Xác nhận xóa'),
            content: const Text(
              'Bạn có chắc chắn muốn xóa bài viết này không?',
            ),
            actions: [
              TextButton(
                child: const Text('Hủy'),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: const Text('Xóa', style: TextStyle(color: Colors.red)),
                onPressed: () {
                  Navigator.pop(context);
                  onDeletePost();
                },
              ),
            ],
          ),
    );
  }

  void _showReportDialog(BuildContext context) {
    String reportReason = '';

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Báo cáo bài viết'),
            content: TextField(
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Nhập lý do báo cáo',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => reportReason = value,
            ),
            actions: [
              TextButton(
                child: const Text('Hủy'),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: const Text('Báo cáo'),
                onPressed: () async {
                  if (reportReason.isNotEmpty) {
                    await reportPost(context, reportReason);
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Vui lòng nhập lý do báo cáo'),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
    );
  }

  Future<void> reportPost(BuildContext context, String reason) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    await FirebaseFirestore.instance.collection('post_reports').add({
      'postId': postAuthorUid,
      'reason': reason,
      'userId': currentUser.uid,
      'reportedAt': Timestamp.now(),
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Bài viết đã được báo cáo')));
  }

  Widget _buildPostAction(
    bool isDarkMode,
    BuildContext context,
    IconData icon,
    String count,
    Color color,
    VoidCallback onPressed, {
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 4),
            Text(
              count,
              style: TextStyle(
                color: AppTextStyles.subTextColor(isDarkMode),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Card(
      elevation: 1.0,
      margin: const EdgeInsets.symmetric(vertical: 3.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      color: AppBackgroundStyles.boxBackground(isDarkMode),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(userAvatarUrl),
                  radius: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: TextStyle(
                          color: AppTextStyles.normalTextColor(isDarkMode),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        timestamp,
                        style: TextStyle(
                          color: AppTextStyles.subTextColor(isDarkMode),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTapDown:
                      (details) => _showPostOptionsMenuAtTap(
                        context,
                        details.globalPosition,
                      ),
                  child: Icon(Icons.more_vert, color: AppIconStyles.iconPrimary(isDarkMode),),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (postTitle != null && postTitle!.isNotEmpty) ...[
              Text(
                postTitle!,
                style: TextStyle(
                  color: AppTextStyles.normalTextColor(isDarkMode),
                  fontSize: 15.5,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 6),
            ],
            if (postText.isNotEmpty)
              Text(
                postText,
                style: TextStyle(color: AppTextStyles.normalTextColor(isDarkMode), fontSize: 14.5, height: 1.4),
              ),
            if (postImageUrl != null && postImageUrl!.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  postImageUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) => Container(
                        height: 150,
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(Icons.broken_image_outlined),
                        ),
                      ),
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      height: 150,
                      color: Colors.grey.shade200,
                      child: Center(
                        child: CircularProgressIndicator(
                          value:
                              progress.expectedTotalBytes != null
                                  ? progress.cumulativeBytesLoaded /
                                      progress.expectedTotalBytes!
                                  : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPostAction(
                  isDarkMode,
                  context,
                  isLikedByCurrentUser ? Icons.favorite : Icons.favorite_border,
                  likesCount.toString(),
                  isLikedByCurrentUser ? Colors.red : AppTextStyles.subTextColor(isDarkMode),
                  onLikePressed,
                  isActive: isLikedByCurrentUser,
                ),
                _buildPostAction(
                  isDarkMode,
                  context,
                  Icons.chat_bubble_outline,
                  commentsCount.toString(),
                  AppTextStyles.subTextColor(isDarkMode),
                  onCommentPressed,
                ),
                _buildPostAction(
                  isDarkMode,
                  context,
                  Icons.share_outlined,
                  sharesCount.toString(),
                  AppTextStyles.subTextColor(isDarkMode),
                  onSharePressed,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
