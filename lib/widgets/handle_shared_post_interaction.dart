import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:learnity/models/bottom_sheet_option.dart';
import 'package:learnity/widgets/common/custom_bottom_sheet.dart';

Future<void> handleSharedPostInteraction({
  required BuildContext context,
  required String sharedPostId,
  required String sharerUserId,
  required VoidCallback onDeleteSuccess,
  required bool isDarkMode,
}) async {
  final currentUser = FirebaseAuth.instance.currentUser;
  final isOwnSharedPost = currentUser?.uid == sharerUserId;

  if (!isOwnSharedPost) return;

  await showCustomBottomSheet(
    context: context,
    isDarkMode: isDarkMode,
    options: [
      BottomSheetOption(
        icon: Icons.delete,
        text: "Xoá bài chia sẻ",
        onTap: () async {
          Navigator.pop(context); // đóng bottom sheet trước
          try {
            // Xoá bài chia sẻ khỏi Firestore
            await FirebaseFirestore.instance
                .collection('shared_posts')
                .doc(sharedPostId)
                .delete();

            // Xoá luôn stats nếu có
            await FirebaseFirestore.instance
                .collection('shared_post_stats')
                .doc(sharedPostId)
                .delete();

            onDeleteSuccess();

            Get.snackbar(
              "Thành công",
              "Đã xoá bài chia sẻ thành công!",
              backgroundColor: Colors.blue.withOpacity(0.9),
              colorText: Colors.white,
              duration: const Duration(seconds: 4),
            );
          } catch (e) {
            debugPrint("Lỗi khi xoá bài chia sẻ: $e");
            Get.snackbar(
              "Lỗi",
              "Không thể xoá bài chia sẻ.",
              backgroundColor: Colors.red.withOpacity(0.9),
              colorText: Colors.white,
              duration: const Duration(seconds: 4),
            );
          }
        },
      ),
    ],
  );
}
