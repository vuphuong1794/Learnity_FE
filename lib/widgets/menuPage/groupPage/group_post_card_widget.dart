import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:provider/provider.dart';
import 'package:learnity/theme/theme.dart';
import 'package:learnity/theme/theme_provider.dart';

import '../../../models/group_post_model.dart';
import '../../../models/user_info_model.dart';
import '../../../screen/homePage/ImageViewerPage.dart';
import '../../../viewmodels/navigate_user_profile_viewmodel.dart';

class GroupPostCardWidget extends StatelessWidget {
  final String userName;
  final String userAvatarUrl;
  final String? postTitle;
  final String postText;
  final List<String>? postImageUrls;
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
    this.postImageUrls,
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

  Widget _buildImageDisplay(BuildContext context,List<String>? imageUrls, bool isDarkMode) {
    if (imageUrls == null || imageUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: _buildImageGrid(context,imageUrls, isDarkMode),
    );
  }

  Widget _buildImageGrid(BuildContext context ,List<String> imageUrls, bool isDarkMode) {
    if (imageUrls.length == 1) {
      return _buildSingleImage(context,imageUrls[0], isDarkMode);
    } else if (imageUrls.length == 2) {
      return _buildTwoImages(context,imageUrls, isDarkMode);
    } else if (imageUrls.length == 3) {
      return _buildThreeImages(context,imageUrls, isDarkMode);
    } else {
      return _buildFourPlusImages(context, imageUrls, isDarkMode);
    }
  }

  Widget _buildSingleImage(BuildContext context,String imageUrl, bool isDarkMode) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: GestureDetector(
        onTap: () => _showImageViewer(context,[imageUrl], 0),
        child: _buildImageWidget(imageUrl, isDarkMode,
          width: double.infinity,
          height: 250,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildTwoImages(BuildContext context,List<String> imageUrls, bool isDarkMode) {
    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8.0),
                bottomLeft: Radius.circular(8.0),
              ),
              child: GestureDetector(
                onTap: () => _showImageViewer(context,imageUrls, 0),
                child: _buildImageWidget(imageUrls[0], isDarkMode,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(8.0),
                bottomRight: Radius.circular(8.0),
              ),
              child: GestureDetector(
                onTap: () => _showImageViewer(context,imageUrls, 1),
                child: _buildImageWidget(imageUrls[1], isDarkMode,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThreeImages(BuildContext context,List<String> imageUrls, bool isDarkMode) {
    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8.0),
                bottomLeft: Radius.circular(8.0),
              ),
              child: GestureDetector(
                onTap: () => _showImageViewer(context,imageUrls, 0),
                child: _buildImageWidget(imageUrls[0], isDarkMode,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(8.0),
                    ),
                    child: GestureDetector(
                      onTap: () => _showImageViewer(context,imageUrls, 1),
                      child: _buildImageWidget(imageUrls[1], isDarkMode,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(8.0),
                    ),
                    child: GestureDetector(
                      onTap: () => _showImageViewer(context,imageUrls, 2),
                      child: _buildImageWidget(imageUrls[2], isDarkMode,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFourPlusImages(BuildContext context,List<String> imageUrls, bool isDarkMode) {
    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8.0),
                bottomLeft: Radius.circular(8.0),
              ),
              child: GestureDetector(
                onTap: () => _showImageViewer(context,imageUrls, 0),
                child: _buildImageWidget(imageUrls[0], isDarkMode,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(8.0),
                    ),
                    child: GestureDetector(
                      onTap: () => _showImageViewer(context,imageUrls, 1),
                      child: _buildImageWidget(imageUrls[1], isDarkMode,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(8.0),
                    ),
                    child: GestureDetector(
                      onTap: () => _showImageViewer(context,imageUrls, 2),
                      child: Stack(
                        children: [
                          _buildImageWidget(imageUrls[2], isDarkMode,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                          if (imageUrls.length > 3)
                            Container(
                              width: double.infinity,
                              height: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.only(
                                  bottomRight: Radius.circular(8.0),
                                ),
                                color: Colors.black54,
                              ),
                              child: Center(
                                child: Text(
                                  '+${imageUrls.length - 3}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageWidget(String imageUrl, bool isDarkMode, {
    required double width,
    required double height,
    required BoxFit fit,
  }) {
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorImage(isDarkMode);
        },
      );
    } else {
      return Image.network(
        imageUrl,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorImage(isDarkMode);
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width,
            height: height,
            color: isDarkMode
                ? AppColors.darkTextThird.withOpacity(0.1)
                : AppColors.textThird.withOpacity(0.1),
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
      );
    }
  }

  Widget _buildErrorImage(bool isDarkMode) {
    return Container(
      color: isDarkMode
          ? AppColors.darkTextThird.withOpacity(0.2)
          : AppColors.textThird.withOpacity(0.2),
      child: Center(
        child: Icon(
          Icons.image_not_supported,
          color: AppTextStyles.subTextColor(isDarkMode),
        ),
      ),
    );
  }

  void _showImageViewer(BuildContext context,List<String> imageUrls, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ImageViewerPage(
          imageUrls: imageUrls,
          initialIndex: initialIndex,
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
            _buildImageDisplay(context, postImageUrls, isDarkMode),
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
