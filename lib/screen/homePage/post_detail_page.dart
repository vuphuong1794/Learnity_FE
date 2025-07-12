import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:learnity/models/post_model.dart';
import 'package:learnity/theme/theme.dart';
import 'package:learnity/widgets/common/time_utils.dart';
import 'package:provider/provider.dart';
import 'package:learnity/theme/theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../api/notification_api.dart';
import '../../models/user_info_model.dart';
import '../../viewmodels/navigate_user_profile_viewmodel.dart';
import '../../widgets/handle_comment_interaction.dart';
import '../../widgets/homePage/post_widget.dart';

class PostDetailPage extends StatefulWidget {
  final PostModel post;
  final bool isDarkMode;
  final String? sharedPostId;
  final UserInfoModel? postUserInfo;

  const PostDetailPage({
    super.key,
    required this.post,
    required this.isDarkMode,
    this.sharedPostId,
    this.postUserInfo,
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
  UserInfoModel? currentUserInfo;
  Stream<DocumentSnapshot>? userInfoStream;
  UserInfoModel? postUserInfo;
  int _currentImagePage = 0;
  late String currentUserId;

  final _likeQueue = Queue<Future<void>>();
  bool _isProcessingQueue = false;

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    isLiked = false;
    likeCount = widget.post.likes;
    _loadLikeState();
    _loadComments();

    final postOwnerId = widget.post.uid;
    if (postOwnerId != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(postOwnerId)
          .get()
          .then((doc) {
        if (doc.exists) {
          setState(() {
            postUserInfo = UserInfoModel.fromDocument(doc);
          });
        }
      });
    }
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
    final snapshot = await FirebaseFirestore.instance
        .collection('posts')
        .doc(targetPostId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .get();

    if (mounted) {
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
  }

  Future<int> getCommentCount(String postId, {bool isShared = false}) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .get();
      return snapshot.size;
    } catch (e) {
      print('Error getting comment count: $e');
      return 0;
    }
  }
  Future<void> _loadLikeState() async {
    if (widget.post.postId == null || widget.post.postId!.isEmpty) {
      print('Error: postId is null');
      return;
    }

    final postRef = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.post.postId);

    final userLikeDocRef = postRef
        .collection('likes')
        .doc(currentUserId);
    try {
      final postSnapshot = await postRef.get();
      final userLikeSnapshot = await userLikeDocRef.get();

      if (mounted) {
        final postData = postSnapshot.data();
        likeCount = postData?['likes'] ?? 0;
        isLiked = userLikeSnapshot.exists;
        setState(() {});
      }
    } catch (e) {
      print("Error loading like state: $e");
    }
  }
  Future<void> _processLikeQueue() async {
    if (_isProcessingQueue || _likeQueue.isEmpty) return;

    _isProcessingQueue = true;
    try {
      while (_likeQueue.isNotEmpty) {
        await _likeQueue.removeFirst();
      }
    } finally {
      _isProcessingQueue = false;
    }
  }

  Future<void> _toggleLike() async {
    // Cập nhật UI ngay lập tức
    setState(() {
      isLiked = !isLiked;
      likeCount = isLiked ? likeCount + 1 : likeCount - 1;
    });

    // Thêm vào hàng đợi
    _likeQueue.add(_executeLikeOperation());
    _processLikeQueue();
  }

  Future<void> _executeLikeOperation() async {
    final postRef = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.post.postId);

    final likeDocRef = postRef
        .collection('likes')
        .doc(currentUserId);

    try {
      if (isLiked) {
        await postRef.update({'likes': FieldValue.increment(1)});
        await likeDocRef.set({
          'userId': currentUserId,
          'likedAt': FieldValue.serverTimestamp(),
        });

        if (currentUserId != widget.post.uid) {
          final currentUserDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUserId)
              .get();

          final senderName = currentUserDoc.data()?['displayName'] ?? 'Một người dùng';
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
        }
      } else {
        await postRef.update({'likes': FieldValue.increment(-1)});
        await likeDocRef.delete();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLiked = !isLiked;
          likeCount += isLiked ? 1 : -1;
        });
      }
      print("Lỗi khi thực hiện like: $e");
    }
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
        'postImageUrl': post.imageUrls,
        'postDescription': post.postDescription,
        'postCreateAt': post.createdAt,

        // Tác giả post
        'postAuthorId': post.uid,
        'postAuthorName': postAuthorName,
        'postAuthorAvatar': postAuthorAvatar,
      };

      await FirebaseFirestore.instance
          .collection('posts')
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
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(color: AppColors.black, height: 1.0),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
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
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(widget.post.uid)
                              .snapshots(),
                          builder: (context, snapshot) {
                            String? avatarUrl;

                            if (snapshot.hasData && snapshot.data!.exists) {
                              avatarUrl = snapshot.data!.get('avatarUrl') ?? '';
                            }

                            return GestureDetector(
                              onTap: () => navigateToUserProfile(context, postUserInfo!),
                              child: CircleAvatar(
                                radius: 22,
                                backgroundColor: isDarkMode
                                    ? AppColors.darkButtonBgProfile
                                    : AppColors.buttonBgProfile,
                                backgroundImage:
                                (avatarUrl != null && avatarUrl.isNotEmpty)
                                    ? NetworkImage(avatarUrl)
                                    : null,
                                child: (avatarUrl == null || avatarUrl.isEmpty)
                                    ? Icon(
                                  Icons.person,
                                  color: isDarkMode
                                      ? AppColors.darkTextPrimary
                                      : AppColors.textPrimary,
                                )
                                    : null,
                              ),
                            );
                          },
                        ),

                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => navigateToUserProfile(context, postUserInfo!),
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

                  if (widget.post.imageUrls != null && widget.post.imageUrls!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            // PageView để vuốt qua các ảnh
                            PageView.builder(
                              itemCount: widget.post.imageUrls!.length,
                              onPageChanged: (index) {
                                setState(() {
                                  _currentImagePage = index;
                                });
                              },
                              itemBuilder: (context, index) {
                                final imageUrl = widget.post.imageUrls![index];
                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 16),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                );
                              },
                            ),

                            if (widget.post.imageUrls!.length > 1)
                              Positioned(
                                bottom: 10.0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(widget.post.imageUrls!.length, (index) {
                                    return AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                                      height: 8.0,
                                      width: _currentImagePage == index ? 24.0 : 8.0,
                                      decoration: BoxDecoration(
                                        color: _currentImagePage == index
                                            ? AppColors.background
                                            : AppColors.background.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                          ],
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
                          color: isDarkMode
                              ? AppColors.darkTextThird
                              : AppColors.textThird,
                        ),
                        const SizedBox(width: 4),

                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('posts')
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
                                  backgroundColor:
                                  AppBackgroundStyles.modalBackground(
                                    isDarkMode,
                                  ),
                                  title: Text(
                                    'Chia sẻ bài viết',
                                    style: TextStyle(
                                      color: AppTextStyles.normalTextColor(
                                        isDarkMode,
                                      ),
                                    ),
                                  ),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ListTile(
                                        leading: Icon(
                                          Icons.repeat,
                                          color: AppIconStyles.iconPrimary(
                                            isDarkMode,
                                          ),
                                        ),
                                        title: Text(
                                          'Chia sẻ trong ứng dụng',
                                          style: TextStyle(
                                            color: AppTextStyles.normalTextColor(
                                              isDarkMode,
                                            ),
                                          ),
                                        ),
                                        onTap: () async {
                                          await shareInternally(context, post, onShared: () {
                                            setState(() {
                                              post.shares += 1; //cập nhật biến shares trong PostModel để hiển thị lên UI
                                            });
                                          });
                                          Navigator.pop(context);
                                        },
                                      ),
                                      ListTile(
                                        leading: Icon(
                                          Icons.share,
                                          color: AppIconStyles.iconPrimary(
                                            isDarkMode,
                                          ),
                                        ),
                                        title: Text(
                                          'Chia sẻ ra ngoài',
                                          style: TextStyle(
                                            color: AppTextStyles.normalTextColor(
                                              isDarkMode,
                                            ),
                                          ),
                                        ),
                                        onTap: () async {
                                          Navigator.pop(context);
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
                            isDarkMode: isDarkMode, // Add dark mode detection
                            commentId: c['commentId'],
                            postId: widget.post.postId!, // Make sure postId is not null
                            content: c['content'],
                            userId: c['userId'],
                            isSharedPost: widget.sharedPostId != null, // Correctly identifying shared posts
                            onEditSuccess: (newContent) {
                              setState(() {
                                c['content'] = newContent; // Update local comment content
                              });
                            },
                            onDeleteSuccess: () {
                              setState(() {
                                _comments.removeWhere(
                                  (comment) => comment['commentId'] == c['commentId'],
                                ); // Remove comment from local list
                              });
                            },
                          );
                        },
                        child: StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(c['userId'])
                              .snapshots(),
                          builder: (context, snapshot) {
                            final userData = snapshot.data?.data() as Map<String, dynamic>?;

                            final avatarUrl = userData?['avatarUrl'] ?? '';
                            final username = userData?['username'] ?? c['username'] ?? 'Ẩn danh';

                            return ListTile(
                              onTap: () {
                                if (c['userId'] != null && c['userId'].toString().isNotEmpty) {
                                  navigateToUserProfileById(context, c['userId']);
                                }
                              },
                              leading: GestureDetector(
                                onTap: () {
                                  if (c['userId'] != null && c['userId'].toString().isNotEmpty) {
                                    navigateToUserProfileById(context, c['userId']);
                                  }
                                },
                                child: (avatarUrl.toString().isNotEmpty)
                                    ? CircleAvatar(
                                  radius: 18,
                                  backgroundImage: NetworkImage(avatarUrl),
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
                              ),
                              title: GestureDetector(
                                onTap: () {
                                  if (c['userId'] != null && c['userId'].toString().isNotEmpty) {
                                    navigateToUserProfileById(context, c['userId']);
                                  }
                                },
                                child: Text(
                                  username,
                                  style: AppTextStyles.body(isDarkMode).copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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
                            );
                          },
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