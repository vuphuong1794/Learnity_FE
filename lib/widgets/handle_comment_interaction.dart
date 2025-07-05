import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:learnity/models/bottom_sheet_option.dart';
import 'package:learnity/widgets/common/confirm_modal.dart';
import 'package:learnity/widgets/common/custom_bottom_sheet.dart';
import 'package:learnity/widgets/common/text_field_modal.dart';
import 'package:get/get.dart';

Future<void> handleCommentInteraction({
  required BuildContext context,
  required bool isDarkMode,
  required String commentId,
  required String postId,
  required String content,
  required String userId,
  required bool isSharedPost,
  String? groupId,
  required Function(String newContent) onEditSuccess,
  required VoidCallback onDeleteSuccess,
}) async {
  final currentUser = FirebaseAuth.instance.currentUser;
  final isOwnComment = currentUser?.uid == userId;

  final List<BottomSheetOption> options = [];

  if (isOwnComment) {
    options.addAll([
      BottomSheetOption(
        icon: Icons.edit,
        text: 'Sửa bình luận',
        onTap: () async {
          Navigator.pop(context);
          await showTextFieldModal(
            context: context,
            isDarkMode: isDarkMode,
            title: 'Chỉnh sửa bình luận',
            hintText: 'Nhập nội dung mới',
            confirmText: 'Cập nhật',
            initialText: content,
            onConfirm: (newContent) async {
              final path =
                  (groupId == null)
                      ? 'shared_post_comments/$postId/comments/$commentId'
                      : 'communityGroups/$groupId/posts/$postId/comments/$commentId';

              try {
                await FirebaseFirestore.instance.doc(path).update({
                  'content': newContent,
                  'editedAt': FieldValue.serverTimestamp(),
                });
                onEditSuccess(newContent);
              } catch (e) {
                Get.snackbar(
                  "Lỗi",
                  "Không thể cập nhật bình luận",
                  backgroundColor: Colors.red.withOpacity(0.9),
                  colorText: Colors.white,
                );
                rethrow;
              }
            },
          );
        },
      ),
      BottomSheetOption(
        icon: Icons.delete,
        text: 'Xóa bình luận',
        onTap: () async {
          Navigator.pop(context);
          final confirm = await showConfirmModal(
            title: 'Xác nhận xoá',
            content: 'Bạn có chắc muốn xoá bình luận này?',
            cancelText: 'Hủy',
            confirmText: 'Xoá',
            context: context,
            isDarkMode: isDarkMode,
          );

          if (confirm == true) {
            final path =
                (groupId == null)
                    ? 'shared_post_comments/$postId/comments/$commentId'
                    : 'communityGroups/$groupId/posts/$postId/comments/$commentId';

            try {
              await FirebaseFirestore.instance.doc(path).delete();
              onDeleteSuccess();
            } catch (e) {
              Get.snackbar(
                "Lỗi",
                "Không thể xóa bình luận",
                backgroundColor: Colors.red.withOpacity(0.9),
                colorText: Colors.white,
              );
              rethrow;
            }
          }
        },
      ),
    ]);
  }

  options.add(
    BottomSheetOption(
      icon: Icons.copy,
      text: 'Sao chép nội dung',
      onTap: () {
        Navigator.pop(context);
        Clipboard.setData(ClipboardData(text: content));
        Get.snackbar(
          "Thành công",
          "Đã sao chép bình luận",
          backgroundColor: Colors.green.withOpacity(0.9),
          colorText: Colors.white,
        );
      },
    ),
  );

  showCustomBottomSheet(
    context: context,
    isDarkMode: isDarkMode,
    options: options,
  );
}
