import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/user_info_model.dart';
import '../../models/post_model.dart';
import '../../widgets/time_utils.dart';
import '../../theme/theme.dart';

class SharedPostList extends StatefulWidget {
  const SharedPostList({super.key});

  @override
  State<SharedPostList> createState() => _SharedPostListState();
}

class _SharedPostListState extends State<SharedPostList> {
  bool isLoading = true;
  List<Map<String, dynamic>> postUserPairs = [];

  @override
  void initState() {
    super.initState();
    loadSharedPosts();
  }

  Future<void> loadSharedPosts() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    print("Đang login với UID: ${FirebaseAuth.instance.currentUser?.uid}");

    if (currentUser == null) return;

    final sharedPostQuery = await FirebaseFirestore.instance
        .collection('shared_posts')
        .where('sharerUserId', isEqualTo: currentUser.uid)
        .orderBy('sharedAt', descending: true)
        .get();

    print('Tìm thấy ${sharedPostQuery.docs.length} bài đã chia sẻ');
    for (var doc in sharedPostQuery.docs) {
      print('→ postId: ${doc['postId']} | sharer: ${doc['sharerUserId']} | time: ${doc['sharedAt']}');
    }

    final results = await Future.wait(sharedPostQuery.docs.map((doc) async {
      final postId = doc['postId'];
      final originUserId = doc['originUserId'];
      final sharerUserId = doc['sharerUserId'];

      final postSnap = await FirebaseFirestore.instance.collection('posts').doc(postId).get();
      if (!postSnap.exists) {
        print(' Không tìm thấy postId: $postId trong collection posts');
        return null;
      }

      print(' Đang load postId: $postId');
      print(postSnap.data());

      final sharerSnap = await FirebaseFirestore.instance.collection('users').doc(sharerUserId).get();
      final posterSnap = await FirebaseFirestore.instance.collection('users').doc(originUserId).get();

      if (!sharerSnap.exists || !posterSnap.exists) return null;

      return {
        'post': PostModel.fromDocument(postSnap),
        'sharer': UserInfoModel.fromDocument(sharerSnap),
        'poster': UserInfoModel.fromDocument(posterSnap),
        'sharedAt': doc['sharedAt'],
      };
    }));

    setState(() {
      postUserPairs = results.whereType<Map<String, dynamic>>().toList();
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    if (postUserPairs.isEmpty) {
      return const Center(child: Text("Chưa chia sẻ bài viết nào"));
    }

    return ListView.builder(
      itemCount: postUserPairs.length,
      itemBuilder: (context, index) {
        final item = postUserPairs[index];
        return _buildSharedPost(
          sharer: item['sharer'],
          originalPoster: item['poster'],
          post: item['post'],
          sharedAt: (item['sharedAt'] != null)
              ? (item['sharedAt'] as Timestamp).toDate()
              : DateTime.now(), // hoặc bạn có thể return null tuỳ yêu cầu
        );
      },
    );
  }

  Widget _buildSharedPost({
    required UserInfoModel sharer,
    required UserInfoModel originalPoster,
    required PostModel post,
    required DateTime sharedAt,
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
                  backgroundImage: (sharer.avatarUrl != null && sharer.avatarUrl!.isNotEmpty)
                      ? NetworkImage(sharer.avatarUrl!)
                      : const AssetImage('assets/default_avatar.png') as ImageProvider,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.black),
                      children: [
                        TextSpan(
                          text: sharer.displayName ?? "",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(text: " đã chia sẻ bài viết của "),
                        TextSpan(
                          text: originalPoster.displayName ?? "",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                Text(
                  formatTime(sharedAt),
                  style: const TextStyle(fontSize: 12, color: Colors.grey, decoration: TextDecoration.none),
                ),
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
                      backgroundImage: (originalPoster.avatarUrl != null && originalPoster.avatarUrl!.isNotEmpty)
                          ? NetworkImage(originalPoster.avatarUrl!)
                          : const AssetImage('assets/default_avatar.png') as ImageProvider,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            originalPoster.displayName ?? "",
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            formatTime(post.createdAt),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (post.imageUrl?.isNotEmpty == true) ...[
                  if (post.content?.isNotEmpty == true)
                    Text(post.content!),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(post.imageUrl!, fit: BoxFit.cover),
                  ),
                ] else if (post.content?.isNotEmpty == true) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      post.content!,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
                if (post.postDescription?.isNotEmpty == true)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      post.postDescription!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 40, top: 6),
            child: Row(
              children: [
                Icon(Icons.favorite_border, size: 22),
                const SizedBox(width: 4),
                const Text("123", style: TextStyle(fontSize: 16, color: Colors.black, decoration: TextDecoration.none)),
                const SizedBox(width: 22),
                Image.asset('assets/chat_bubble.png', width: 22),
                const SizedBox(width: 4),
                const Text("123", style: TextStyle(fontSize: 16, color: Colors.black, decoration: TextDecoration.none)),
                const SizedBox(width: 22),
                Image.asset('assets/Share.png', width: 22),
                const SizedBox(width: 4),
                const Text("123", style: TextStyle(fontSize: 16, color: Colors.black, decoration: TextDecoration.none)),
                const SizedBox(width: 25),
                Image.asset('assets/dots.png', width: 22),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
