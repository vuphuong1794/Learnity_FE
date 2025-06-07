import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Future<void> handlePostInteraction({
//   required BuildContext context,
//   required String postId,
//   required String postDescription,
//   required String content,
//   required String postOwnerId,
//   required Function(String newDesc, String newContent) onEditSuccess,
//   required VoidCallback onDeleteSuccess,
// }) async {
//   final currentUser = FirebaseAuth.instance.currentUser;
//   final isOwnPost = currentUser?.uid == postOwnerId;
//
//   List<Widget> actions = [];
//
//   if (isOwnPost) {
//     actions = [
//       ListTile(
//         leading: const Icon(Icons.edit),
//         title: const Text("Sửa bài viết"),
//         onTap: () async {
//           Navigator.pop(context);
//           final descController = TextEditingController(text: postDescription);
//           final contentController = TextEditingController(text: content);
//
//           final result = await showDialog<Map<String, String>>(
//             context: context,
//             builder: (context) => AlertDialog(
//               title: const Text("Chỉnh sửa bài viết"),
//               content: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   TextField(
//                     controller: descController,
//                     decoration: const InputDecoration(labelText: "Mô tả"),
//                   ),
//                   const SizedBox(height: 10),
//                   TextField(
//                     controller: contentController,
//                     decoration: const InputDecoration(labelText: "Nội dung"),
//                     maxLines: null,
//                   ),
//                 ],
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(context),
//                   child: const Text("Huỷ"),
//                 ),
//                 TextButton(
//                   onPressed: () => Navigator.pop(context, {
//                     'postDescription': descController.text,
//                     'content': contentController.text,
//                   }),
//                   child: const Text("Cập nhật"),
//                 ),
//               ],
//             ),
//           );
//
//           if (result != null &&
//               (result['postDescription']?.trim().isNotEmpty ?? false ||
//                   result['content']!.trim().isNotEmpty ?? false)) {
//             try {
//               await FirebaseFirestore.instance.collection('posts').doc(postId).update({
//                 'postDescription': result['postDescription']?.trim() ?? '',
//                 'content': result['content']?.trim() ?? '',
//               });
//               onEditSuccess(
//                 result['postDescription'] ?? '',
//                 result['content'] ?? '',
//               );
//               debugPrint("Cập nhật bài viết thành công");
//             } catch (e) {
//               debugPrint("Lỗi khi cập nhật bài viết: $e");
//             }
//           }
//         },
//       ),
//       ListTile(
//         leading: const Icon(Icons.delete),
//         title: const Text("Xoá bài viết"),
//         onTap: () async {
//           Navigator.pop(context);
//           try {
//             await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
//             onDeleteSuccess();
//             debugPrint("Đã xoá bài viết");
//           } catch (e) {
//             debugPrint("Lỗi khi xoá bài viết: $e");
//           }
//         },
//       ),
//     ];
//   }
//
//   actions.add(
//     ListTile(
//       leading: const Icon(Icons.copy),
//       title: const Text("Sao chép nội dung"),
//       onTap: () {
//         final fullText = "$postDescription\n\n$content";
//         Clipboard.setData(ClipboardData(text: fullText));
//         Navigator.pop(context);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Đã sao chép nội dung bài viết")),
//         );
//       },
//     ),
//   );
//
//   showModalBottomSheet(
//     context: context,
//     builder: (context) => Column(
//       mainAxisSize: MainAxisSize.min,
//       children: actions,
//     ),
//   );
// }
Future<void> handlePostInteraction({
  required BuildContext context,
  required String postId,
  required String postDescription,
  required String content,
  required String postOwnerId,
  required Function(String newDesc, String newContent) onEditSuccess,
  required VoidCallback onDeleteSuccess,
}) async {
  final currentUser = FirebaseAuth.instance.currentUser;
  final isOwnPost = currentUser?.uid == postOwnerId;

  List<Widget> actions = [];

  if (isOwnPost) {
    actions = [
      ListTile(
        leading: const Icon(Icons.edit),
        title: const Text("Sửa bài viết"),
        onTap: () async {
          Navigator.pop(context);
          final descController = TextEditingController(text: postDescription);
          final contentController = TextEditingController(text: content);

          final result = await showDialog<Map<String, String>>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Chỉnh sửa bài viết"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: "Mô tả"),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: contentController,
                    decoration: const InputDecoration(labelText: "Nội dung"),
                    maxLines: null,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Huỷ"),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, {
                    'postDescription': descController.text,
                    'content': contentController.text,
                  }),
                  child: const Text("Cập nhật"),
                ),
              ],
            ),
          );

          if (result != null) {
            await FirebaseFirestore.instance.collection('posts').doc(postId).update({
              'postDescription': result['postDescription']?.trim() ?? '',
              'content': result['content']?.trim() ?? '',
            });
            onEditSuccess(
              result['postDescription'] ?? '',
              result['content'] ?? '',
            );
          }
        },
      ),
      ListTile(
        leading: const Icon(Icons.delete),
        title: const Text("Xoá bài viết"),
        onTap: () async {
          Navigator.pop(context);
          await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
          onDeleteSuccess();
        },
      ),
    ];
  }

  actions.add(
    ListTile(
      leading: const Icon(Icons.copy),
      title: const Text("Sao chép nội dung"),
      onTap: () {
        Clipboard.setData(ClipboardData(text: "$postDescription\n\n$content"));
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đã sao chép nội dung bài viết")),
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
