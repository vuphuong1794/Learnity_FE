import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:learnity/models/post_model.dart';
import 'package:learnity/theme/theme.dart';
import 'package:learnity/screen/homePage/post_detail_page.dart';
import 'package:share_plus/share_plus.dart';

import '../screen/userPage/shared_post_list.dart';

class PostWidget extends StatefulWidget {
  final PostModel post;
  final bool isDarkMode;
  final VoidCallback? onPostUpdated;

  const PostWidget({
    Key? key,
    required this.post,
    required this.isDarkMode,
    this.onPostUpdated,
  }) : super(key: key);

  Future<void> sharePost(String postId, String originUserId) async {
    final sharerUserId = FirebaseAuth.instance.currentUser?.uid;
    if (sharerUserId == null) return;

    final sharedPost = {
      'postId': postId,
      'originUserId': originUserId,
      'sharerUserId': sharerUserId,
      'sharedAt': Timestamp.now(),
    };

    await FirebaseFirestore.instance.collection('shared_posts').add(sharedPost);
  }


  @override
  State<PostWidget> createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  bool isLiked = false;
  late int likeCount;
  late String currentUserId;

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    likeCount = widget.post.likes;

    _loadLikeState();
  }

  Future<void> _loadLikeState() async {
    if ((widget.post.postId ?? '').isEmpty || (currentUserId ?? '').isEmpty) {
      print('Error: postId or currentUserId is null or empty');
      return;
    }

    final postRef = FirebaseFirestore.instance.collection('posts').doc(widget.post.postId);
    final likeDocRef = FirebaseFirestore.instance
        .collection('post_likes')
        .doc('${widget.post.postId}_$currentUserId');

    final snapshot = await postRef.get();
    final likeSnapshot = await likeDocRef.get();

    if (mounted) {
      setState(() {
        likeCount = snapshot.data()?['likes'] ?? 0;
        isLiked = likeSnapshot.exists;
      });
    }
  }

  Future<void> _toggleLike() async {
    final postRef = FirebaseFirestore.instance.collection('posts').doc(widget.post.postId);
    final likeDocRef = FirebaseFirestore.instance
        .collection('post_likes')
        .doc('${widget.post.postId}_$currentUserId');

    if (isLiked) {
      await postRef.update({'likes': FieldValue.increment(-1)});
      await likeDocRef.delete();
    } else {
      await postRef.update({'likes': FieldValue.increment(1)});
      await likeDocRef.set({
        'postId': widget.post.postId,
        'userId': currentUserId,
        'liked': true,
      });
    }

    await _loadLikeState();
  }

  Future<void> _goToDetail() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostDetailPage(post: widget.post, isDarkMode: widget.isDarkMode),
      ),
    );

    if (result == true) {
      widget.onPostUpdated?.call();
    }
  }
  Future<int> getCommentCount(String postId, {bool isShared = false}) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(isShared ? 'shared_post_comments' : 'posts')
          .doc(postId)
          .collection('comments')
          .get();

      return snapshot.size;
    } catch (e) {
      print('Lỗi khi lấy số comment: $e');
      return 0;
    }
  }


  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final isDarkMode = widget.isDarkMode;
    return GestureDetector(
      onTap: _goToDetail,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isDarkMode ? AppColors.darkTextThird.withOpacity(0.2) : AppColors.textThird.withOpacity(0.2),
              width: 0.5,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User info row
              Row(
                children: [
                  // Profile image
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: isDarkMode ? AppColors.darkButtonBgProfile : AppColors.buttonBgProfile,
                    backgroundImage: post.avatarUrl != null && post.avatarUrl!.isNotEmpty
                        ? NetworkImage(post.avatarUrl!)
                        : null,
                    child: (post.avatarUrl == null || post.avatarUrl!.isEmpty)
                        ? Icon(Icons.person, color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.username ?? '',
                          style: AppTextStyles.subtitle2(isDarkMode)
                        ),
                        if (post.postDescription != null)
                          Text(
                            post.postDescription!,
                            style: AppTextStyles.body(isDarkMode),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  if (post.isVerified)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDarkMode ? AppColors.darkButtonText : Colors.blue,
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              // Post content
              if (post.content != null && post.content!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    post.content!,
                    style: AppTextStyles.body(isDarkMode),
                  ),
                ),
              // Post image nếu có
              if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: post.imageUrl!.startsWith('assets/')
                        ? Image.asset(
                            post.imageUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                color: isDarkMode ? AppColors.darkTextThird.withOpacity(0.2) : AppColors.textThird.withOpacity(0.2),
                                child: Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    color: AppTextStyles.subTextColor(isDarkMode),
                                  ),
                                ),
                              );
                            },
                          )
                        : Image.network(
                            post.imageUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                color: isDarkMode ? AppColors.darkTextThird.withOpacity(0.2) : AppColors.textThird.withOpacity(0.2),
                                child: Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    color: AppTextStyles.subTextColor(isDarkMode),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              // Post actions
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Like
                    InkWell(
                      onTap: () async {
                        await _toggleLike();
                      },
                      child: Row(
                        children: [
                          Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked
                                ? Colors.red
                                : AppTextStyles.subTextColor(isDarkMode),
                            size: 22,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            likeCount.toString(),
                            style: AppTextStyles.bodySecondary(isDarkMode),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 24),
                    // Comments
                    FutureBuilder<int>(
                      future: getCommentCount(post.postId!, isShared: true),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Row(
                            children: [
                              Icon(Icons.comment_outlined, color: AppTextStyles.subTextColor(isDarkMode), size: 22),
                              const SizedBox(width: 4),
                              Text('0', style: AppTextStyles.bodySecondary(isDarkMode)),
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Icon(Icons.comment_outlined, color: AppTextStyles.subTextColor(isDarkMode), size: 22),
                            const SizedBox(width: 4),
                            Text('${snapshot.data}', style: AppTextStyles.bodySecondary(isDarkMode)),
                          ],
                        );
                      },
                    ),


                    const SizedBox(width: 24),
                    // Share
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text('Chia sẻ bài viết'),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.repeat),
                                    title: const Text('Chia sẻ trong ứng dụng'),
                                    onTap: () async {
                                      await shareInternally(context, post, onShared: () {
                                        setState(() {
                                          post.shares += 1; //cập nhật biến shares trong PostModel để hiển thị lên UI
                                        });
                                      });
                                      Navigator.pop(context); // đóng dialog
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.share),
                                    title: const Text('Chia sẻ ra ngoài'),
                                    onTap: () async {
                                      Navigator.pop(context); // đóng dialog
                                      await shareExternally(post);
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },

                      child: Row(
                        children: [
                          Icon(
                            Icons.share_outlined,
                            size: 22,
                            color: AppTextStyles.subTextColor(isDarkMode),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            post.shares.toString(),
                            style: AppTextStyles.bodySecondary(isDarkMode),
                          ),
                        ],
                      ),
                    ),

                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
Future<void> shareInternally(BuildContext context, PostModel post, {VoidCallback? onShared}) async {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) return;

  final existing = await FirebaseFirestore.instance
      .collection('shared_posts')
      .where('postId', isEqualTo: post.postId)
      .where('sharerUserId', isEqualTo: currentUser.uid)
      .get();

  if (existing.docs.isNotEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bạn đã chia sẻ bài viết này rồi.')),
    );
    return;
  }
  // Lấy post gốc để đọc số lần chia sẻ hiện tại
  final originalPostSnap = await FirebaseFirestore.instance
      .collection('posts')
      .doc(post.postId)
      .get();

  final originalPostData = originalPostSnap.data();
  int currentShares = originalPostData?['shares'] ?? 0;

  // Tăng số lần chia sẻ
  await FirebaseFirestore.instance.collection('posts').doc(post.postId).update({
    'shares': currentShares + 1,
  });

  await FirebaseFirestore.instance.collection('shared_posts').add({
    'postId': post.postId,
    'originUserId': post.uid,
    'sharerUserId': currentUser.uid,
    'sharedAt': Timestamp.now(),
  });

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Đã chia sẻ bài viết')),
  );

  if (onShared != null) {
    onShared(); // Gọi callback cập nhật UI
  }
}

Future<void> shareExternally(PostModel post) async {
  final content = post.content ?? '';
  final desc = post.postDescription ?? '';
  final text = '$content\n\n$desc\n(Chia sẻ từ ứng dụng Learnity)';
  await Share.share(text);
}