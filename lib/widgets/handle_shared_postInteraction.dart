import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

Future<void> handleSharedPostInteraction({
  required BuildContext context,
  required String sharedPostId,
  required String sharerUserId,
  required VoidCallback onDeleteSuccess,
}) async {
  final currentUser = FirebaseAuth.instance.currentUser;
  final isOwnSharedPost = currentUser?.uid == sharerUserId;

  if (!isOwnSharedPost) return;

  showModalBottomSheet(
    context: context,
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.delete),
          title: const Text("Xoá bài chia sẻ"),
          onTap: () async {
            Navigator.pop(context);
            try {
              // Xoá bài chia sẻ khỏi Firestore
              await FirebaseFirestore.instance
                  .collection('shared_posts')
                  .doc(sharedPostId)
                  .delete();

              // Xoá luôn stats nếu muốn reset hoàn toàn shareCount
              await FirebaseFirestore.instance
                  .collection('shared_post_stats')
                  .doc(sharedPostId)
                  .delete(); //.set({'shareCount': 0});

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
    ),
  );
}

