import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:learnity/models/post_model.dart';
import 'package:learnity/theme/theme.dart';
import 'package:learnity/widgets/time_utils.dart';
import 'package:provider/provider.dart';
import 'package:learnity/theme/theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../api/Notification.dart';
import '../../models/user_info_model.dart';
import '../../widgets/handle_comment_interaction.dart';
import '../../widgets/post_widget.dart';

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
  UserInfoModel? currentUserInfo; // thông tin user cập nhật động
  Stream<DocumentSnapshot>? userInfoStream; // stream realtime

  @override
  void initState() {
    super.initState();
    isLiked = false;
    likeCount = 0;
    _loadLikeState();
    _loadComments();
    // Lắng nghe thay đổi của thông tin người dùng hiện tại (username/avatar)
    if (user != null) {
      userInfoStream =
          FirebaseFirestore.instance
              .collection('users')
              .doc(user!.uid)
              .snapshots();

      userInfoStream!.listen((snapshot) {
        if (snapshot.exists) {
          setState(() {
            currentUserInfo = UserInfoModel.fromDocument(snapshot);
          });
        }
      });
    }
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
        snapshot.docs.map((doc) {
          final data = doc.data();

          return {
            'commentId': doc.id,
            'userId': data['userId'] ?? '',
            'username': data['username'] ?? 'Ẩn danh',
            'userAvatar': data['userAvatar'] ?? '',
            'content': data['content'] ?? '[Không có nội dung]',
            'createdAt':
            (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          };
        }),
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
    if (user == null) return;
    final currentUserId = user!.uid;

    final postRef = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.post.postId);
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

      // Gửi thông báo khi thích bài viết
      if (currentUserId != widget.post.uid) {
        try {
          final senderName = currentUserInfo?.displayName ?? 'Một người dùng';
          final postContent = widget.post.content ?? widget.post.postDescription ?? '';

          await Notification_API.sendLikeNotification(
            senderName,
            widget.post.uid!,
            postContent,
            widget.post.postId!,
          );

          await Notification_API.saveLikeNotificationToFirestore(
            receiverId: widget.post.uid!,
            senderId: currentUserId,
            senderName: senderName,
            postId: widget.post.postId!,
            postContent: postContent,
          );
        } catch (e) {
          print("Lỗi khi gửi thông báo lượt thích: $e");
        }
      }
    }

    // Cập nhật lại UI chính xác sau khi hoàn tất
    await _loadLikeState();
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty || currentUserInfo == null) return;

    final targetPostId = widget.post.postId!;
    final post = widget.post;
    final currentUserId = currentUserInfo!.uid;
    final senderName = currentUserInfo!.displayName ?? 'Một người dùng';

    try {
      // Lấy thông tin mới nhất của tác giả post (gọi 1 lần là đủ)
      final authorSnapshot =
      await FirebaseFirestore.instance
          .collection('users')
          .doc(post.uid)
          .get();
      final authorData = authorSnapshot.data();
      final postAuthorName = authorData?['username'] ?? 'Unknown';
      final postAuthorAvatar = authorData?['avatarUrl'] ?? '';

      // Tạo comment object
      final comment = {
        // Người comment (luôn cập nhật động)
        'userId': currentUserInfo!.uid,
        'username': currentUserInfo!.username ?? 'Người dùng',
        'userAvatar': currentUserInfo!.avatarUrl ?? '',
        'content': content,
        'createdAt': Timestamp.now(),

        // Bài post
        'postId': post.postId,
        'postContent': post.content,
        'postImageUrl': post.imageUrl,
        'postDescription': post.postDescription,
        'postCreateAt': post.createdAt,

        // Tác giả post
        'postAuthorId': post.uid,
        'postAuthorName': postAuthorName,
        'postAuthorAvatar': postAuthorAvatar,
      };

      await FirebaseFirestore.instance
          .collection('shared_post_comments')
          .doc(targetPostId)
          .collection('comments')
          .add(comment);

      if (currentUserId != widget.post.uid) {
        try {
          await Notification_API.sendCommentNotification(
            senderName,
            widget.post.uid!,
            content,
            widget.post.postId!,
          );

          await Notification_API.saveCommentNotificationToFirestore(
            receiverId: widget.post.uid!,
            senderId: currentUserId!,
            senderName: senderName,
            postId: widget.post.postId!,
            commentText: content,
          );
        } catch (e) {
          print("Lỗi khi gửi thông báo bình luận: $e");
        }
      }

      if(mounted) {
        setState(() {
          _comments.insert(0, {...comment, 'createdAt': DateTime.now()});
          _commentController.clear();
          FocusScope.of(context).unfocus();
        });
      }
    } catch (e) {
      print(" Lỗi khi gửi comment: $e");
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
        backgroundColor: AppBackgroundStyles.secondaryBackground(isDarkMode),
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 70,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppIconStyles.iconPrimary(isDarkMode),
          ),
          onPressed: () {
            Navigator.pop(context, true);
          },
        ),
        flexibleSpace: SafeArea(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Center(child: Image.asset("assets/learnity.png", height: 70)),
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
                              .doc(widget.post.postId!)
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: GestureDetector(
                        onLongPress: () {
                          print(
                            "commentId: ${c['commentId']}, content: ${c['content']}",
                          );
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
                                _comments.removeWhere(
                                      (comment) =>
                                  comment['commentId'] == c['commentId'],
                                );
                              });
                            },
                          );
                        },
                        child: ListTile(
                          leading:
                          (c['userAvatar'] != null &&
                              c['userAvatar'].toString().isNotEmpty)
                              ? CircleAvatar(
                            radius: 18,
                            backgroundImage: NetworkImage(
                              c['userAvatar'],
                            ),
                            backgroundColor: Colors.transparent,
                          )
                              : CircleAvatar(
                            radius: 18,
                            backgroundColor:
                            isDarkMode
                                ? AppColors.darkButtonBgProfile
                                : AppColors.buttonBgProfile,
                            child: Icon(
                              Icons.person,
                              color:
                              isDarkMode
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          title: Text(
                            c['username'] ?? '',
                            style: AppTextStyles.body(
                              isDarkMode,
                            ).copyWith(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            c['content'] ?? '',
                            style: AppTextStyles.body(isDarkMode),
                          ),
                          trailing: Text(
                            formatTime(c['createdAt'] as DateTime?),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
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