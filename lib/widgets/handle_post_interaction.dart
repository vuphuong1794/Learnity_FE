import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:learnity/models/bottom_sheet_option.dart';
import 'package:learnity/widgets/common/confirm_modal.dart';
import 'package:learnity/widgets/common/custom_bottom_sheet.dart';
import 'package:learnity/widgets/common/text_field_modal.dart';

import '../screen/homePage/edit_post_page.dart';
import '../theme/theme.dart';

class ReusablePostActionButton extends StatelessWidget {
  final bool isDarkMode;
  final String? postId;
  final String? currentUserId;
  final dynamic post;
  final VoidCallback? onPostUpdated;
  final Future<void> Function(
    BuildContext context,
    String postId,
    String reason,
  )?
  reportPost;

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
        _showPostOptions(context);
      },
    );
  }

  void _showPostOptions(BuildContext context) {
    final bool isOwnPost = post.uid == currentUserId;
    String reportReason = '';

    final List<BottomSheetOption> options = [];

    if (isOwnPost) {
      options.addAll([
        BottomSheetOption(
          icon: Icons.edit,
          text: 'Chỉnh sửa bài viết',
          onTap: () {
            Navigator.pop(context); // Close bottom sheet
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) =>
                        EditPostPage(post: post, onPostUpdated: onPostUpdated),
              ),
            );
          },
        ),
        BottomSheetOption(
          icon: Icons.delete,
          text: 'Xóa bài viết',
          onTap: () async {
            Navigator.pop(context);
            final confirm = await showConfirmModal(
              title: 'Xác nhận xoá',
              content: 'Bạn có chắc muốn xoá bài viết này?',
              cancelText: 'Hủy',
              confirmText: 'Xoá',
              context: context,
              isDarkMode: isDarkMode,
            );
            if (confirm == true) {
              await FirebaseFirestore.instance
                  .collection('posts')
                  .doc(post.postId)
                  .delete();
              onPostUpdated?.call();
            }
          },
        ),
      ]);
    }

    if (!isOwnPost) {
      options.add(
        BottomSheetOption(
          icon: Icons.flag,
          text: 'Báo cáo bài viết',
          onTap: () {
            Navigator.pop(context);
            showTextFieldModal(
              context: context,
              isDarkMode: isDarkMode,
              title: 'Báo cáo bài viết',
              hintText: 'Nhập lý do báo cáo',
              confirmText: 'Báo cáo',
              onConfirm: (reason) async {
                if (reportPost != null && postId != null) {
                  await reportPost!(context, postId!, reason);
                }
              },
            );
          },
        ),
      );
    }

    showCustomBottomSheet(
      context: context,
      isDarkMode: isDarkMode,
      options: options,
    );
  }
}
