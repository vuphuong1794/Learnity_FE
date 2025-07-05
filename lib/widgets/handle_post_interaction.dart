import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:learnity/widgets/common/option_modal_item.dart';

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
      onPressed: () => _showPostOptionsBottomSheet(context),
    );
  }

  void _showPostOptionsBottomSheet(BuildContext context) {
    final bool isOwnPost = post.uid == currentUserId;
    String reportReason = '';

    showModalBottomSheet(
      backgroundColor: AppBackgroundStyles.modalBackground(isDarkMode),
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (ctx) {
        return ListView(
          shrinkWrap: true,
          children: [
            // Divider đầu
            Container(
              height: 4,
              margin: EdgeInsets.symmetric(
                vertical: 10,
                horizontal: MediaQuery.of(context).size.width * .4,
              ),
              decoration: BoxDecoration(
                color: AppTextStyles.normalTextColor(isDarkMode),
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
            ),

            if (isOwnPost)
              OptionItem(
                icon: Icon(Icons.edit, color: AppIconStyles.iconPrimary(isDarkMode), size: 26),
                name: 'Chỉnh sửa bài viết',
                onTap: (ctx) async {
                  Navigator.pop(ctx);

                  final descController =
                      TextEditingController(text: post.postDescription);
                  final contentController =
                      TextEditingController(text: post.content);

                  final result = await showDialog<Map<String, String>>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Chỉnh sửa bài viết"),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: descController,
                            decoration:
                                const InputDecoration(labelText: "Mô tả"),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: contentController,
                            decoration:
                                const InputDecoration(labelText: "Nội dung"),
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
                    await FirebaseFirestore.instance
                        .collection('posts')
                        .doc(post.postId)
                        .update({
                      'postDescription': result['postDescription']?.trim(),
                      'content': result['content']?.trim(),
                    });
                    onPostUpdated?.call();
                  }
                },
              ),

            if (isOwnPost)
              OptionItem(
                icon: Icon(Icons.delete_forever,
                    color: AppIconStyles.iconPrimary(isDarkMode), size: 26),
                name: 'Xoá bài viết',
                onTap: (ctx) async {
                  Navigator.pop(ctx);
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
                    await FirebaseFirestore.instance
                        .collection('posts')
                        .doc(post.postId)
                        .delete();
                    onPostUpdated?.call();
                  }
                },
              ),

            OptionItem(
              icon: Icon(Icons.flag, color: AppIconStyles.iconPrimary(isDarkMode), size: 26),
              name: 'Báo cáo bài viết',
              onTap: (ctx) {
                Navigator.pop(ctx);
                showDialog(
                  context: context,
                  builder: (context) => StatefulBuilder(
                    builder: (context, setState) => AlertDialog(
                      backgroundColor:
                          AppBackgroundStyles.modalBackground(isDarkMode),
                      title: Text(
                        'Báo cáo bài viết',
                        style: TextStyle(
                            color: AppTextStyles.normalTextColor(isDarkMode)),
                      ),
                      content: TextField(
                        style: TextStyle(
                            color: AppTextStyles.normalTextColor(isDarkMode)),
                        decoration: InputDecoration(
                          hintText: 'Nhập lý do báo cáo',
                          hintStyle: TextStyle(
                            color: AppTextStyles.normalTextColor(isDarkMode)
                                .withOpacity(0.5),
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (value) => reportReason = value,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Hủy',
                              style: TextStyle(
                                  color:
                                      AppTextStyles.subTextColor(isDarkMode))),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor:
                                AppBackgroundStyles.buttonBackground(isDarkMode),
                            foregroundColor:
                                AppTextStyles.buttonTextColor(isDarkMode),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                          onPressed: () async {
                            if (reportReason.isNotEmpty) {
                              if (reportPost != null) {
                                await reportPost!(
                                    context, postId!, reportReason);
                              }
                              Navigator.pop(context);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Vui lòng nhập lý do báo cáo')),
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
      },
    );
  }
}
