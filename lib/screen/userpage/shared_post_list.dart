
import 'package:flutter/material.dart';
import '../../models/user_info_model.dart';
import '../../models/post_model.dart';
import '../../widgets/time_utils.dart';
import '../../theme/theme.dart';

class SharedPostList extends StatelessWidget {
  const SharedPostList({super.key});

  @override
  Widget build(BuildContext context) {
    final sharedPosts = [
      {
        "sharer": UserInfoModel(nickname: "pink_everlasting", avatarUrl: "assets/avatar.png"),
        "original": UserInfoModel(nickname: "pink_everlasting", avatarUrl: "assets/avatar.png"),
        "post": PostModel(
          content: "Sách này hay quá",
          createdAt: DateTime.now(),
          imageUrl: "assets/book.png",
        ),
      },
      {
        "sharer": UserInfoModel(nickname: "pink_everlasting", avatarUrl: "assets/avatar.png"),
        "original": UserInfoModel(nickname: "Phương Vũ", avatarUrl: "assets/avatar2.png"),
        "post": PostModel(
          content: "tính tìm meme ngồi ê 1 chân mà ko thấy =))",
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
      },
    ];

    return Column(
      children: sharedPosts.map((item) {
        final sharer = item["sharer"] as UserInfoModel;
        final original = item["original"] as UserInfoModel;
        final post = item["post"] as PostModel;

        return _buildSharedPost(
          sharer: sharer,
          originalPoster: original,
          post: post,
        );
      }).toList(),
    );
  }

  Widget _buildSharedPost({
    required UserInfoModel sharer,
    required UserInfoModel originalPoster,
    required PostModel post,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: const Border(bottom: BorderSide(width: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage: AssetImage(sharer.avatarUrl ?? 'assets/avatar.png'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.black),
                      children: [
                        TextSpan(text: sharer.nickname ?? "", style: const TextStyle(fontWeight: FontWeight.bold)),
                        const TextSpan(text: " đã chia sẻ bài viết của "),
                        TextSpan(
                          text: originalPoster.nickname ?? "",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                Text(formatTime(post.createdAt), style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Shared content block
          Container(
            margin: const EdgeInsets.only(left: 40),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      backgroundImage: AssetImage(originalPoster.avatarUrl ?? 'assets/default_avatar.png'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(originalPoster.nickname ?? "", style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(formatTime(post.createdAt), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (post.content != null) Text(post.content!),
                if (post.imageUrl != null) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(post.imageUrl!, fit: BoxFit.cover),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 40, top: 6),
            child: Row(
              children: [
                Icon(Icons.favorite_border, size: 22),
                SizedBox(width: 4),
                Text("123"),
                SizedBox(width: 22),
                Image.asset(
                  'assets/chat_bubble.png',
                  width: 22,
                ),
                SizedBox(width: 4),
                Text("123"),
                SizedBox(width: 22),
                Image.asset(
                  'assets/Share.png',
                  width: 22,
                ),
                SizedBox(width: 4),
                Text("123"),
                SizedBox(width: 25),
                Image.asset(
                  'assets/dots.png',
                  width: 22,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
