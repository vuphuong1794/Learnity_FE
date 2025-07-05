import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import '../screen/homePage/edit_post_page.dart';
import '../theme/theme.dart';

class ReusablePostActionButton extends StatelessWidget {
  final bool isDarkMode;
  final String? postId;
  final String? currentUserId;
  final dynamic post;
  final VoidCallback? onPostUpdated;
  final Future<void> Function(BuildContext context, String postId, String reason)? reportPost;

  const ReusablePostActionButton({
    super.key,
    required this.isDarkMode,
    required this.postId,
    required this.currentUserId,
    required this.post,
    this.onPostUpdated,
    this.reportPost,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.more_vert, color: AppIconStyles.iconPrimary(isDarkMode)),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: isDarkMode ? Colors.black : Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (context) {
            return _buildBottomSheetOptions(context);
          },
        );
      },
    );
  }

  Widget _buildBottomSheetOptions(BuildContext context) {
    final bool isOwnPost = post.uid == currentUserId;
    String reportReason = '';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isOwnPost)
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Chỉnh sửa bài viết'),
            onTap: () {
              Navigator.pop(context); // Đóng BottomSheet
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditPostPage(
                    post: post,
                    onPostUpdated: onPostUpdated,
                  ),
                ),
              );
            },
          ),

        if (isOwnPost)
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Xóa bài viết'),
            onTap: () async {
              Navigator.pop(context);
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Xác nhận xoá"),
                  content: const Text("Bạn có chắc muốn xoá bài viết này?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Hủy"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Xoá"),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await FirebaseFirestore.instance.collection('posts').doc(post.postId).delete();
                onPostUpdated?.call();
              }
            },
          ),
        ListTile(
          leading: const Icon(Icons.flag),
          title: const Text('Báo cáo bài viết'),
          onTap: () {
            Navigator.pop(context);
            showDialog(
              context: context,
              builder: (context) => StatefulBuilder(
                builder: (context, setState) => AlertDialog(
                  backgroundColor: AppBackgroundStyles.modalBackground(isDarkMode),
                  title: Text(
                    'Báo cáo bài viết',
                    style: TextStyle(color: AppTextStyles.normalTextColor(isDarkMode)),
                  ),
                  content: TextField(
                    style: TextStyle(color: AppTextStyles.normalTextColor(isDarkMode)),
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
                      style: TextButton.styleFrom(
                        backgroundColor: AppBackgroundStyles.buttonBackground(isDarkMode),
                        foregroundColor: AppTextStyles.buttonTextColor(isDarkMode),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onPressed: () async {
                        if (reportReason.isNotEmpty) {
                          if (reportPost != null) {
                            await reportPost!(context, postId!, reportReason);
                          }
                          Navigator.pop(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Vui lòng nhập lý do báo cáo')),
                          );
                        }
                      },
                      child: const Text('Báo cáo'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
