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

  if (!isOwnSharedPost)
    return; // Nếu không phải chủ bài chia sẻ thì không làm gì

  showModalBottomSheet(
    context: context,
    builder:
        (context) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text("Xoá bài chia sẻ"),
              onTap: () async {
                Navigator.pop(context);
                try {
                  await FirebaseFirestore.instance
                      .collection('shared_posts')
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
                    backgroundColor: Colors.blue.withOpacity(0.9),
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
