import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> handleSharedPostInteraction({
  required BuildContext context,
  required String sharedPostId,
  required String sharerUserId,
  required VoidCallback onDeleteSuccess,
}) async {
  final currentUser = FirebaseAuth.instance.currentUser;
  final isOwnSharedPost = currentUser?.uid == sharerUserId;

  if (!isOwnSharedPost) return; // Nếu không phải chủ bài chia sẻ thì không làm gì

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
              await FirebaseFirestore.instance
                  .collection('shared_posts')
                  .doc(sharedPostId)
                  .delete();
              onDeleteSuccess();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Đã xoá bài chia sẻ")),
              );
            } catch (e) {
              debugPrint("Lỗi khi xoá bài chia sẻ: $e");
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Lỗi khi xoá bài chia sẻ")),
              );
            }
          },
        ),
      ],
    ),
  );
}
