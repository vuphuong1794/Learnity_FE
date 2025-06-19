import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:learnity/models/post_model.dart';
import 'package:learnity/theme/theme.dart';
import 'package:learnity/widgets/time_utils.dart';
import 'package:provider/provider.dart';
import 'package:learnity/theme/theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../widgets/handle_comment_interaction.dart';

class PostDetailPage extends StatefulWidget {
  final PostModel post;
  final bool isDarkMode;
  final String? sharedPostId;

  const PostDetailPage({
    super.key,
    required this.post,
    required this.isDarkMode,
    this.sharedPostId,
  });

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final TextEditingController _commentController = TextEditingController();
  final List<Map<String, dynamic>> _comments = [];
  late bool isLiked;
  late int likeCount;
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    isLiked = false;
    likeCount = 0;
    _loadLikeState();
    _loadComments();
  }

  void _loadComments() async {
    final targetPostId = widget.post.postId!;
    final snapshot =
        await FirebaseFirestore.instance
            .collection('shared_post_comments')
            .doc(targetPostId)
            .collection('comments')
            .orderBy('createdAt', descending: true)
            .get();

    setState(() {
      _comments.clear();
      _comments.addAll(
        snapshot.docs.map(
          (doc) => {
            'commentId': doc.id,
            'userId': doc['userId'],
            'username': doc['username'] ?? 'Ẩn danh',
            'userAvatar': doc['userAvatar'] ?? '',
            'content': doc['content'],
            'createdAt': (doc['createdAt'] as Timestamp).toDate(),
          },
        ),
      );
    });
  }

  Future<void> _loadLikeState() async {
    final postRef = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.post.postId);
    final likeDocRef = FirebaseFirestore.instance
        .collection('post_likes')
        .doc('${widget.post.postId}_${user?.uid}');

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
    final postRef = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.post.postId);
    final likeDocRef = FirebaseFirestore.instance
        .collection('post_likes')
        .doc('${widget.post.postId}_${user?.uid}');

    if (isLiked) {
      await postRef.update({'likes': FieldValue.increment(-1)});
      await likeDocRef.delete();
    } else {
      await postRef.update({'likes': FieldValue.increment(1)});
      await likeDocRef.set({
        'postId': widget.post.postId,
        'userId': user?.uid,
        'liked': true,
      });
    }

    await _loadLikeState(); // cập nhật lại UI chính xác
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty || user == null) return;

    final targetPostId = widget.post.postId!;
    final post = widget.post;
    final userInfo = await FirebaseFirestore.instance.collection('users').doc(user?.uid).get();

    final comment = {
      // Thông tin người comment
      'userId': user!.uid,
      'username': user?.displayName ?? 'Người dùng',
      'content': content,
      'createdAt': Timestamp.now(),
      'userAvatar': userInfo.data()?['avatarUrl'] ?? '',

      // Thông tin bài post được comment
      'postId': post.postId,
      'postContent': post.content,
      'postImageUrl': post.imageUrl,
      'postDescription': post.postDescription,
      'postCreateAt': post.createdAt,

      // Thông tin người tạo bài post
      'postAuthorId': post.uid,
      'postAuthorName': post.username,
      'postAuthorAvatar': post.avatarUrl,
    };

    try {
      await FirebaseFirestore.instance
          .collection('shared_post_comments')
          .doc(targetPostId)
          .collection('comments')
          .add(comment);

      setState(() {
        _comments.insert(0, {
          ...comment,
          'createdAt': DateTime.now(),
        });
        _commentController.clear();
      });
    } catch (e) {
      print("Lỗi khi gửi comment: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final post = widget.post;
    final mq = MediaQuery.of(context);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppBackgroundStyles.mainBackground(isDarkMode),
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 70,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: widget.isDarkMode ? Colors.white : Colors.black,
          ),
          onPressed: () {
            Navigator.pop(context, true);
          },
        ),
        flexibleSpace: SafeArea(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Center(
                child: Image.asset("assets/learnity.png", height: 70),
              ),
            ],
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(color: AppColors.black, height: 1.0),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100), // chừa chỗ cho input
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor:
                              isDarkMode
                                  ? AppColors.darkButtonBgProfile
                                  : AppColors.buttonBgProfile,
                          backgroundImage:
                              post.avatarUrl != null &&
                                      post.avatarUrl!.isNotEmpty
                                  ? NetworkImage(post.avatarUrl!)
                                  : null,
                          child:
                              (post.avatarUrl == null ||
                                      post.avatarUrl!.isEmpty)
                                  ? Icon(
                                    Icons.person,
                                    color:
                                        isDarkMode
                                            ? AppColors.darkTextPrimary
                                            : AppColors.textPrimary,
                                  )
                                  : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post.username ?? "",
                                style: AppTextStyles.subtitle2(isDarkMode),
                              ),
                              if (post.postDescription != null)
                                Text(
                                  post.postDescription!,
                                  style: AppTextStyles.body(isDarkMode),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (post.content != null && post.content!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Text(
                        post.content!,
                        style: AppTextStyles.body(isDarkMode),
                      ),
                    ),
                  if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child:
                            post.imageUrl!.startsWith('assets/')
                                ? Image.asset(
                                  post.imageUrl!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                )
                                : Image.network(
                                  post.imageUrl!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () async {
                            await _toggleLike();
                          },
                          child: Row(
                            children: [
                              Icon(
                                isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color:
                                    isLiked
                                        ? Colors.red
                                        : (isDarkMode
                                            ? AppColors.darkTextThird
                                            : AppColors.textThird),
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
                        const SizedBox(width: 18),
                        Icon(
                          Icons.comment_outlined,
                          size: 22,
                          color:
                              isDarkMode
                                  ? AppColors.darkTextThird
                                  : AppColors.textThird,
                        ),
                        const SizedBox(width: 4),
                        StreamBuilder<QuerySnapshot>(
                          stream:
                              FirebaseFirestore.instance
                                  .collection('shared_post_comments')
                                  .doc(
                                widget.post.postId!,
                                  )
                                  .collection('comments')
                                  .snapshots(),
                          builder: (context, snapshot) {
                            final count = snapshot.data?.docs.length ?? 0;

                            return Text(
                              '$count',
                              style: AppTextStyles.bodySecondary(isDarkMode),
                            );
                          },
                        ),
                        const SizedBox(width: 18),
                        Icon(
                          Icons.share_outlined,
                          size: 22,
                          color:
                              isDarkMode
                                  ? AppColors.darkTextThird
                                  : AppColors.textThird,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          post.shares.toString(),
                          style: AppTextStyles.bodySecondary(isDarkMode),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      'Bình luận',
                      style: AppTextStyles.subtitle2(isDarkMode),
                    ),
                  ),
                  ..._comments.map(
                        (c) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: GestureDetector(
                        onLongPress: () {
                          print("commentId: ${c['commentId']}, content: ${c['content']}");
                          handleCommentInteraction(
                            context: context,
                            commentId: c['commentId'],
                            postId: (widget.post.postId)!,
                            content: c['content'],
                            userId: c['userId'],
                            isSharedPost: widget.sharedPostId != null,
                            onEditSuccess: (newContent) {
                              setState(() {
                                c['content'] = newContent;
                              });
                            },
                            onDeleteSuccess: () {
                              setState(() {
                                _comments.removeWhere((comment) => comment['commentId'] == c['commentId']);
                              });
                            },
                          );
                        },
                        child: ListTile(
                          leading: (c['userAvatar'] != null && c['userAvatar'].toString().isNotEmpty)
                              ? CircleAvatar(
                            radius: 18,
                            backgroundImage: NetworkImage(c['userAvatar']),
                            backgroundColor: Colors.transparent,
                          )
                              : CircleAvatar(
                            radius: 18,
                            backgroundColor: isDarkMode
                                ? AppColors.darkButtonBgProfile
                                : AppColors.buttonBgProfile,
                            child: Icon(
                              Icons.person,
                              color: isDarkMode
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          title: Text(
                            c['username'] ?? '',
                            style: AppTextStyles.body(isDarkMode).copyWith(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            c['content'] ?? '',
                            style: AppTextStyles.body(isDarkMode),
                          ),
                          trailing: Text(
                            formatTime(c['createdAt'] as DateTime?),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          dense: true,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildCommentInput(isDarkMode),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput(bool isDarkMode) {
    return Container(
      color: AppBackgroundStyles.mainBackground(isDarkMode),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: 'Viết bình luận...',
                  filled: true,
                  fillColor:
                      isDarkMode
                          ? AppColors.darkBackgroundSecond
                          : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.image_outlined,
              size: 28,
              color: isDarkMode ? AppColors.darkTextThird : Colors.black54,
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _submitComment,
              child: Icon(
                Icons.send,
                size: 28,
                color: isDarkMode ? AppColors.darkTextThird : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
