import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:provider/provider.dart';
import 'package:learnity/theme/theme.dart';
import 'package:learnity/theme/theme_provider.dart';

import '../../../models/user_info_model.dart';
import '../../../viewmodels/navigate_user_profile_viewmodel.dart';

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

  void _showPostOptionsMenuAtTap(
    bool isDarkMode,
    BuildContext context,
    Offset tapPosition,
  ) {
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
        // _confirmDelete(isDarkMode, context);
        onDeletePost();
      } else if (value == 'report') {
        _showReportDialog(isDarkMode, context);
      }
    });
  }

  void _confirmDelete(bool isDarkMode, BuildContext context) {
    // showDialog(
    //   context: context,
    //   builder:
    //       (_) => AlertDialog(
    //         backgroundColor: AppBackgroundStyles.modalBackground(isDarkMode),
    //         title: Text('Xác nhận xóa', style: TextStyle(color: AppTextStyles.normalTextColor(isDarkMode))),
    //         content: Text(
    //           'Bạn có chắc chắn muốn xóa bài viết này không?',
    //           style: TextStyle(color: AppTextStyles.normalTextColor(isDarkMode))
    //         ),
    //         actions: [
    //           TextButton(
    //             child: Text('Hủy', style: TextStyle(color: AppTextStyles.subTextColor(isDarkMode))),
    //             onPressed: () => Navigator.pop(context),
    //           ),
    //           ElevatedButton(
    //                 onPressed: () { 
    //                   Navigator.pop(context);
    //                   onDeletePost();
    //                 },
    //                 child: const Text('Xóa'),
    //                 style: ElevatedButton.styleFrom(
    //                   backgroundColor: AppBackgroundStyles.buttonBackground(isDarkMode),
    //                   foregroundColor: AppTextStyles.normalTextColor(isDarkMode),
    //                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    //                 ),
    //               ),
    //         ],
    //       ),
    // );
    onDeletePost();
  }

  void showPostActionBottomSheet({
    required BuildContext context,
    required bool isDarkMode,
    required bool isOwner,
    required VoidCallback onDelete,
    required Future<void> Function(String reason) onReport,
  }) {
    String reportReason = '';

    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isOwner)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Xóa bài viết', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  onDelete();
                },
              ),
            if (!isOwner)
              ListTile(
                leading: const Icon(Icons.report_gmailerrorred_outlined, color: Colors.orange),
                title: const Text('Báo cáo bài viết', style: TextStyle(color: Colors.orange)),
                onTap: () {
                  Navigator.pop(context); // Đóng bottom sheet
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: AppBackgroundStyles.modalBackground(isDarkMode),
                      title: Text(
                        'Báo cáo bài viết',
                        style: TextStyle(color: AppTextStyles.normalTextColor(isDarkMode)),
                      ),
                      content: TextField(
                        style: TextStyle(color: AppTextStyles.normalTextColor(isDarkMode)),
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Nhập lý do báo cáo',
                          hintStyle: TextStyle(
                            color: AppTextStyles.normalTextColor(isDarkMode).withOpacity(0.5),
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (value) => reportReason = value,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Hủy', style: TextStyle(color: AppTextStyles.subTextColor(isDarkMode))),
                        ),
                        TextButton(
                          onPressed: () async {
                            if (reportReason.isNotEmpty) {
                              await onReport(reportReason);
                              Navigator.pop(context);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Vui lòng nhập lý do báo cáo')),
                              );
                            }
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: AppBackgroundStyles.buttonBackground(isDarkMode),
                            foregroundColor: AppTextStyles.buttonTextColor(isDarkMode),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          child: const Text('Báo cáo'),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  void _showReportDialog(bool isDarkMode, BuildContext context) {
    String reportReason = '';

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: AppBackgroundStyles.modalBackground(isDarkMode),
            title: Text(
              'Báo cáo bài viết',
              style: TextStyle(
                color: AppTextStyles.normalTextColor(isDarkMode),
              ),
            ),
            content: TextField(
              style: TextStyle(
                color: AppTextStyles.normalTextColor(isDarkMode),
              ),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Nhập lý do báo cáo',
                hintStyle: TextStyle(
                  color: AppTextStyles.normalTextColor(
                    isDarkMode,
                  ).withOpacity(0.5),
                ),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => reportReason = value,
            ),
            actions: [
              TextButton(
                child: Text(
                  'Hủy',
                  style: TextStyle(
                    color: AppTextStyles.subTextColor(isDarkMode),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
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
                style: TextButton.styleFrom(
                  backgroundColor: AppBackgroundStyles.buttonBackground(
                    isDarkMode,
                  ),
                  foregroundColor: AppTextStyles.buttonTextColor(isDarkMode),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                child: Text('Báo cáo'),
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

    Get.snackbar(
      "Thành công",
      "Đã gửi báo cáo thành công!",
      backgroundColor: Colors.blue.withOpacity(0.9),
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
    );
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
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(postAuthorUid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(); // Loading UI
                }

                final userData = snapshot.data?.data() as Map<String, dynamic>?;

                if (userData == null) {
                  return Row(
                    children: const [
                      CircleAvatar(radius: 20, child: Icon(Icons.person)),
                      SizedBox(width: 10),
                      Text('Người dùng không tồn tại'),
                    ],
                  );
                }

                final userModel = UserInfoModel.fromMap(userData, snapshot.data!.id);
                final avatarUrl = userModel.avatarUrl ?? '';
                final displayName = userModel.username ?? 'Không tên';

                return Row(
                  children: [
                    GestureDetector(
                      onTap: () => navigateToUserProfile(context, userModel),
                      child: CircleAvatar(
                        backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                        radius: 20,
                        backgroundColor: Colors.grey[300],
                        child: avatarUrl.isEmpty
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => navigateToUserProfile(context, userModel),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
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
                    ),
                    GestureDetector(
                      onTap: () {
                        final currentUser = FirebaseAuth.instance.currentUser;
                        final isOwner = currentUser != null && currentUser.uid == postAuthorUid;

                        showPostActionBottomSheet(
                          context: context,
                          isDarkMode: isDarkMode,
                          isOwner: isOwner,
                          onDelete: onDeletePost,
                          onReport: (reason) => reportPost(context, reason),
                        );
                      },
                      child: Icon(
                        Icons.more_vert,
                        color: AppIconStyles.iconPrimary(isDarkMode),
                      ),
                    ),
                  ],
                );
              },
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
                style: TextStyle(
                  color: AppTextStyles.normalTextColor(isDarkMode),
                  fontSize: 14.5,
                  height: 1.4,
                ),
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
                  isLikedByCurrentUser
                      ? Colors.red
                      : AppTextStyles.subTextColor(isDarkMode),
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
