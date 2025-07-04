import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> handleCommentInteraction({
  required BuildContext context,
  required String commentId,
  required String postId,
  required String content,
  required String userId,
  required bool isSharedPost,
  required Function(String newContent) onEditSuccess,
  required VoidCallback onDeleteSuccess,
}) async {
  final currentUser = FirebaseAuth.instance.currentUser;
  final isOwnComment = currentUser?.uid == userId;

  List<Widget> actions = [];

  if (isOwnComment) {
    actions = [
      ListTile(
        leading: const Icon(Icons.edit),
        title: const Text("Sửa"),
        onTap: () async {
          Navigator.pop(context); // Đóng BottomSheet
          final controller = TextEditingController(text: content);
          final result = await showDialog<String>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Chỉnh sửa bình luận"),
              content: TextField(
                controller: controller,
                maxLines: null,
                decoration: const InputDecoration(hintText: "Nhập nội dung mới"),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Huỷ"),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, controller.text),
                  child: const Text("Cập nhật"),
                ),
              ],
            ),
          );
          if (result != null && result.trim().isNotEmpty) {
            final path = 'shared_post_comments';
            final commentRef = FirebaseFirestore.instance
                .collection(path)
                .doc(postId)
                .collection('comments')
                .doc(commentId);

            print("Path cập nhật: $path/$postId/comments/$commentId");

            try {
              await commentRef.update({'content': result.trim()});
              onEditSuccess(result.trim());
              print("Sửa thành công");
            } catch (e) {
              print("Lỗi khi sửa: $e");
            }
          }

        },
      ),
      ListTile(
        leading: const Icon(Icons.delete),
        title: const Text("Xoá"),
        onTap: () async {
          Navigator.pop(context);
          final path = 'shared_post_comments';
          final commentRef = FirebaseFirestore.instance
              .collection(path)
              .doc(postId)
              .collection('comments')
              .doc(commentId);

          print("Path xoá: $path/$postId/comments/$commentId");

          try {
            await commentRef.delete();
            onDeleteSuccess();
            print("Xoá thành công");
          } catch (e) {
            print("Lỗi khi xoá: $e");
          }

        },
      ),
    ];
  }

  actions.add(
    ListTile(
      leading: const Icon(Icons.copy),
      title: const Text("Sao chép nội dung"),
      onTap: () {
        Clipboard.setData(ClipboardData(text: content));
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đã sao chép bình luận")),
        );
      },
    ),
  );

  showModalBottomSheet(
    context: context,
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      children: actions,
    ),
  );
}
Future<void> handleCommentInteractionGroup({
  required BuildContext context,
  required String commentId,
  required String postId,
  required String content,
  required String userId,
  required bool isSharedPost,
  String? groupId, // Thêm groupId để dùng khi không phải shared post
  required Function(String newContent) onEditSuccess,
  required VoidCallback onDeleteSuccess,
}) async {
  final currentUser = FirebaseAuth.instance.currentUser;
  final isOwnComment = currentUser?.uid == userId;

  List<Widget> actions = [];

  if (isOwnComment) {
    actions = [
      ListTile(
        leading: const Icon(Icons.edit),
        title: const Text("Sửa"),
        onTap: () async {
          Navigator.pop(context); // Đóng BottomSheet
          final controller = TextEditingController(text: content);
          final result = await showDialog<String>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Chỉnh sửa bình luận"),
              content: TextField(
                controller: controller,
                maxLines: null,
                decoration: const InputDecoration(hintText: "Nhập nội dung mới"),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Huỷ"),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, controller.text),
                  child: const Text("Cập nhật"),
                ),
              ],
            ),
          );
          if (result != null && result.trim().isNotEmpty) {
            final path = isSharedPost
                ? 'shared_post_comments/$postId/comments/$commentId'
                : 'communityGroups/$groupId/posts/$postId/comments/$commentId';
            final commentRef = FirebaseFirestore.instance.doc(path);

            print("Path cập nhật: $path/$postId/comments/$commentId");

            try {
              await commentRef.update({'content': result.trim()});
              onEditSuccess(result.trim());
              print("Sửa thành công");
            } catch (e) {
              print("Lỗi khi sửa: $e");
            }
          }
        },
      ),
      ListTile(
        leading: const Icon(Icons.delete),
        title: const Text("Xoá"),
        onTap: () async {
          Navigator.pop(context);
          final path = isSharedPost
              ? 'shared_post_comments/$postId/comments/$commentId'
              : 'communityGroups/$groupId/posts/$postId/comments/$commentId';
          final commentRef = FirebaseFirestore.instance.doc(path);

          print("Path xoá: $path/$postId/comments/$commentId");

          try {
            await commentRef.delete();
            onDeleteSuccess();
            print("Xoá thành công");
          } catch (e) {
            print("Lỗi khi xoá: $e");
          }

        },
      ),
    ];
  }

  actions.add(
    ListTile(
      leading: const Icon(Icons.copy),
      title: const Text("Sao chép nội dung"),
      onTap: () {
        Clipboard.setData(ClipboardData(text: content));
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đã sao chép bình luận")),
        );
      },
    ),
  );

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      children: actions,
    ),
  );
}