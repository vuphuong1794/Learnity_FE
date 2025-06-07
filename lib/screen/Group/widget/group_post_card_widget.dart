import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:learnity/theme/theme.dart';

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

  Widget _buildPostAction(
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
                color:
                    isActive
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPostOptionsMenuAtTap(
      BuildContext context,
      Offset tapPosition,
      String postAuthorUid,
      VoidCallback onDeletePost,
      ) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null && currentUser.uid == postAuthorUid) {
      final left = tapPosition.dx;
      final top = tapPosition.dy;

      showMenu<String>(
        context: context,
        position: RelativeRect.fromLTRB(left, top, 0, 0),
        items: [
          const PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline, color: Colors.red),
                SizedBox(width: 10),
                Text('Xóa bài viết', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
      ).then((value) {
        if (value == 'delete') {
          onDeletePost();
        }
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.0,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      color: AppColors.background,
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
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        timestamp,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTapDown: (TapDownDetails details) {
                    _showPostOptionsMenuAtTap(
                      context,
                      details.globalPosition,
                      postAuthorUid,
                      onDeletePost,
                    );
                  },
                  child: Icon(Icons.more_vert),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (postTitle != null && postTitle!.isNotEmpty) ...[
              Text(
                postTitle!,
                style: const TextStyle(
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
                style: const TextStyle(fontSize: 14.5, height: 1.4),
              ),
            if (postImageUrl != null && postImageUrl!.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  postImageUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 150,
                      color: Colors.grey.shade200,
                      child: Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: Colors.grey.shade400,
                          size: 40,
                        ),
                      ),
                    );
                  },
                  loadingBuilder: (
                    BuildContext context,
                    Widget child,
                    ImageChunkEvent? loadingProgress,
                  ) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 150,
                      color: Colors.grey.shade200,
                      child: Center(
                        child: CircularProgressIndicator(
                          value:
                              loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 12),
            Divider(color: Colors.grey.shade300),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPostAction(
                  context,
                  isLikedByCurrentUser ? Icons.favorite : Icons.favorite_border,
                  likesCount.toString(),
                  isLikedByCurrentUser ? Colors.red : Colors.grey,
                  onLikePressed,
                  isActive: isLikedByCurrentUser,
                ),
                _buildPostAction(
                  context,
                  Icons.chat_bubble_outline,
                  commentsCount.toString(),
                  Colors.grey.shade700,
                  onCommentPressed,
                ),
                _buildPostAction(
                  context,
                  Icons.share_outlined,
                  sharesCount.toString(),
                  Colors.grey.shade700,
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
