
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'post_model.dart';
import 'user_info_model.dart';
import 'time_utils.dart';

class CommentThread extends StatelessWidget {
  const CommentThread({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildThreadPair(
          parentUser: UserInfoModel(nickname: "binh_gold"),
          parentPost: PostModel(
            content:
            "Biết điều tôn trọng người lớn đấy là kính lão đắc thọ\n"
                "Đánh 83 mà nó ra 38 thì đấy là số mày max nhọ\n"
                "Nhưng mà thôi không sao, tiền thì đã mất rồi\n"
                "không việc gì phải nhăn nhó\n"
                "Nếu mà cảm thấy cuộc sống bế tắc hãy bốc cho mình một bát họ",
            createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
          ),
          childUser: UserInfoModel(nickname: "pink_everlasting"),
          childPost: PostModel(
            content: "Anh Bình hát hay lắm",
            createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
          ),
        ),
        const SizedBox(height: 24),
        _buildThreadPair(
          parentUser: UserInfoModel(nickname: "hoang_hold"),
          parentPost: PostModel(
            content: "Podcast chill chill",
            createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
          ),
          childUser: UserInfoModel(nickname: "pink_everlasting"),
          childPost: PostModel(
            content: "Anh Bình hát hay lắm",
            createdAt: DateTime.now().subtract(const Duration(minutes: 7)),
          ),
        ),
      ],
    );
  }

  Widget _buildThreadPair({
    required UserInfoModel parentUser,
    required PostModel parentPost,
    required UserInfoModel childUser,
    required PostModel childPost,
  }) {
    return Stack(
      children: [
        Positioned(
          left: 35,
          top: 60,
          bottom: 85,
          child: Container(width: 2, color: Colors.black),
        ),
        Column(
          children: [
            _buildCommentBlock(user: parentUser, post: parentPost),
            const SizedBox(height: 8),
            _buildCommentBlock(user: childUser, post: childPost),
          ],
        ),
      ],
    );
  }

  Widget _buildCommentBlock({
    required UserInfoModel user,
    required PostModel post,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundImage: AssetImage(user.avatarPath ?? 'assets/avatar.png'),
            radius: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(user.nickname ?? "Không có tên", style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(formatTime(post.createdAt), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(post.content ?? "khong co"),
                const SizedBox(height: 8),
                Row(
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
                    )
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
