import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../models/user_info_model.dart';
import 'time_utils.dart';

class PostItem extends StatelessWidget {
  final UserInfoModel user;
  final PostModel post;

  const PostItem({super.key, required this.user, required this.post});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: AssetImage(user.avatarUrl ?? 'assets/avatar.png'),
                  radius: 24,
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.nickname ?? "Không có tên",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      formatTime(post.createdAt),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 8),
            // const Text(
            //   "Biết điều tôn trọng người lớn đấy là kính lão đắc thọ\n"
            //       "Đánh 83 mà nó ra 38 thì đấy là số mày max nhọ\n"
            //       "Nhưng mà thôi không sao, tiền thì đã mất rồi\n"
            //       "Không việc gì phải nhăn nhó\n"
            //       "Nếu mà cảm thấy cuộc sống bế tắc hãy bốc cho mình một bát họ",
            //   style: TextStyle(fontSize: 14),
            // ),
            Text(post.content ?? "Khong co", style: TextStyle(fontSize: 14),),
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
    );
  }

  String _formatTime(DateTime time) {
    return "${time.day}/${time.month}/${time.year} ${time.hour}:${time.minute.toString().padLeft(2, '0')}";
  }
}
