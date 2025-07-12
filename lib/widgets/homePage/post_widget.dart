import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:learnity/models/post_model.dart';
import 'package:learnity/theme/theme.dart';
import 'package:learnity/screen/homePage/post_detail_page.dart';
import 'package:share_plus/share_plus.dart';

import '../../api/notification_api.dart';
import '../../screen/homePage/ImageViewerPage.dart';
import '../../viewmodels/navigate_user_profile_viewmodel.dart';
import '../handle_post_interaction.dart';

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
  bool isReport = false;
  String reportReason = '';
  final _likeQueue = Queue<Future<void>>();
  bool _isProcessingQueue = false;

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    likeCount = widget.post.likes;
    _loadLikeState();
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

  Future<void> _goToDetail() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostDetailPage(
          post: widget.post,
          isDarkMode: widget.isDarkMode,
        ),
      ),
    );

    if (result == true) {
      widget.onPostUpdated?.call();
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

  Widget _buildImageDisplay(List<String>? imageUrls, bool isDarkMode) {
    if (imageUrls == null || imageUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: _buildImageGrid(imageUrls, isDarkMode),
    );
  }

  Widget _buildImageGrid(List<String> imageUrls, bool isDarkMode) {
    if (imageUrls.length == 1) {
      return _buildSingleImage(imageUrls[0], isDarkMode);
    } else if (imageUrls.length == 2) {
      return _buildTwoImages(imageUrls, isDarkMode);
    } else if (imageUrls.length == 3) {
      return _buildThreeImages(imageUrls, isDarkMode);
    } else {
      return _buildFourPlusImages(imageUrls, isDarkMode);
    }
  }

  Widget _buildSingleImage(String imageUrl, bool isDarkMode) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: GestureDetector(
        onTap: () => _showImageViewer([imageUrl], 0),
        child: _buildImageWidget(
          imageUrl,
          isDarkMode,
          width: double.infinity,
          height: 250,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildTwoImages(List<String> imageUrls, bool isDarkMode) {
    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8.0),
                bottomLeft: Radius.circular(8.0),
              ),
              child: GestureDetector(
                onTap: () => _showImageViewer(imageUrls, 0),
                child: _buildImageWidget(
                  imageUrls[0],
                  isDarkMode,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(8.0),
                bottomRight: Radius.circular(8.0),
              ),
              child: GestureDetector(
                onTap: () => _showImageViewer(imageUrls, 1),
                child: _buildImageWidget(
                  imageUrls[1],
                  isDarkMode,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThreeImages(List<String> imageUrls, bool isDarkMode) {
    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8.0),
                bottomLeft: Radius.circular(8.0),
              ),
              child: GestureDetector(
                onTap: () => _showImageViewer(imageUrls, 0),
                child: _buildImageWidget(
                  imageUrls[0],
                  isDarkMode,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(8.0),
                    ),
                    child: GestureDetector(
                      onTap: () => _showImageViewer(imageUrls, 1),
                      child: _buildImageWidget(
                        imageUrls[1],
                        isDarkMode,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(8.0),
                    ),
                    child: GestureDetector(
                      onTap: () => _showImageViewer(imageUrls, 2),
                      child: _buildImageWidget(
                        imageUrls[2],
                        isDarkMode,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFourPlusImages(List<String> imageUrls, bool isDarkMode) {
    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8.0),
                bottomLeft: Radius.circular(8.0),
              ),
              child: GestureDetector(
                onTap: () => _showImageViewer(imageUrls, 0),
                child: _buildImageWidget(
                  imageUrls[0],
                  isDarkMode,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(8.0),
                    ),
                    child: GestureDetector(
                      onTap: () => _showImageViewer(imageUrls, 1),
                      child: _buildImageWidget(
                        imageUrls[1],
                        isDarkMode,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(8.0),
                    ),
                    child: GestureDetector(
                      onTap: () => _showImageViewer(imageUrls, 2),
                      child: Stack(
                        children: [
                          _buildImageWidget(
                            imageUrls[2],
                            isDarkMode,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                          if (imageUrls.length > 3)
                            Container(
                              width: double.infinity,
                              height: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.only(
                                  bottomRight: Radius.circular(8.0),
                                ),
                                color: Colors.black54,
                              ),
                              child: Center(
                                child: Text(
                                  '+${imageUrls.length - 3}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageWidget(
    String imageUrl,
    bool isDarkMode, {
    required double width,
    required double height,
    required BoxFit fit,
  }) {
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorImage(isDarkMode);
        },
      );
    } else {
      return Image.network(
        imageUrl,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorImage(isDarkMode);
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width,
            height: height,
            color:
                isDarkMode
                    ? AppColors.darkTextThird.withOpacity(0.1)
                    : AppColors.textThird.withOpacity(0.1),
            child: Center(
              child: CircularProgressIndicator(
                value:
                    loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
              ),
            ),
          );
        },
      );
    }
  }

  Widget _buildErrorImage(bool isDarkMode) {
    return Container(
      color:
          isDarkMode
              ? AppColors.darkTextThird.withOpacity(0.2)
              : AppColors.textThird.withOpacity(0.2),
      child: Center(
        child: Icon(
          Icons.image_not_supported,
          color: AppTextStyles.subTextColor(isDarkMode),
        ),
      ),
    );
  }

  void _showImageViewer(List<String> imageUrls, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => ImageViewerPage(
              imageUrls: imageUrls,
              initialIndex: initialIndex,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final isDarkMode = widget.isDarkMode;
    return GestureDetector(
      onTap: _goToDetail,
      child: Container(
        decoration: BoxDecoration(
          color: AppBackgroundStyles.boxBackground(isDarkMode),
          border: Border(
            bottom: BorderSide(
              color:
                  AppBackgroundStyles.mainBackground(isDarkMode),
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
              StreamBuilder<DocumentSnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(post.uid)
                        .snapshots(),
                builder: (context, snapshot) {
                  final userData =
                      snapshot.data?.data() as Map<String, dynamic>?;

                  final avatarUrl = userData?['avatarUrl'] ?? '';
                  final username = userData?['username'] ?? 'Người dùng';
                  final displayName = userData?['displayName']?.toString().trim() ?? '';
                  final displayText = displayName.isNotEmpty ? displayName : (username.isNotEmpty ? username : 'Người dùng');

                  return Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (post.uid != null) {
                            navigateToUserProfileById(context, post.uid!);
                          }
                        },
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor:
                              isDarkMode
                                  ? AppColors.darkButtonBgProfile
                                  : AppColors.buttonBgProfile,
                          backgroundImage:
                              avatarUrl.isNotEmpty
                                  ? NetworkImage(avatarUrl)
                                  : null,
                          child:
                              avatarUrl.isEmpty
                                  ? Icon(
                                    Icons.person,
                                    color:
                                        isDarkMode
                                            ? AppColors.darkTextPrimary
                                            : AppColors.textPrimary,
                                  )
                                  : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (post.uid != null) {
                              navigateToUserProfileById(context, post.uid!);
                            }
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayText,
                                style: AppTextStyles.subtitle2(isDarkMode),
                              ),
                              if (post.tagList != null && post.tagList!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: post.tagList!.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppBackgroundStyles.buttonBackgroundSecondary(isDarkMode), // bạn có thể định nghĩa hàm này
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tag,
                    style: AppTextStyles.caption(isDarkMode), // hoặc bodySmall tùy bạn
                  ),
                );
              }).toList(),
            ),
          ),
                            ],
                          ),
                        ),
                      ),
                      if (post.isVerified)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  isDarkMode
                                      ? AppColors.darkButtonText
                                      : Colors.blue,
                            ),
                            child: const Icon(
                              Icons.verified,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      const SizedBox(width: 10),
                      ReusablePostActionButton(
                        isDarkMode: isDarkMode,
                        postId: post.postId,
                        currentUserId: currentUserId,
                        post: post,
                        onPostUpdated: widget.onPostUpdated,
                        reportPost: reportPost,
                      ),
                    ],
                  );
                },
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
              _buildImageDisplay(post.imageUrls, isDarkMode),
              // Post actions
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                            color:
                                isLiked
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
                              Icon(
                                Icons.comment_outlined,
                                color: AppTextStyles.subTextColor(isDarkMode),
                                size: 22,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '0',
                                style: AppTextStyles.bodySecondary(isDarkMode),
                              ),
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Icon(
                              Icons.comment_outlined,
                              color: AppTextStyles.subTextColor(isDarkMode),
                              size: 22,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${snapshot.data}',
                              style: AppTextStyles.bodySecondary(isDarkMode),
                            ),
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
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
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
                                      await shareInternally(
                                        context,
                                        post,
                                        onShared: () {
                                          setState(() {
                                            post.shares +=
                                                1; //cập nhật biến shares trong PostModel để hiển thị lên UI
                                          });
                                        },
                                      );
                                      Navigator.pop(context); // đóng dialog
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

Future<void> shareInternally(
  BuildContext context,
  PostModel post, {
  VoidCallback? onShared,
}) async {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) return;

  final existing =
      await FirebaseFirestore.instance
          .collection('shared_posts')
          .where('postId', isEqualTo: post.postId)
          .where('sharerUserId', isEqualTo: currentUser.uid)
          .get();

  if (existing.docs.isNotEmpty) {
    Get.snackbar(
      "Thông báo",
      "Bạn đã chia sẻ bài viết này rồi.",
      backgroundColor: Colors.blue.withOpacity(0.9),
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
    );
    return;
  }
  // Lấy post gốc để đọc số lần chia sẻ hiện tại
  final originalPostSnap =
      await FirebaseFirestore.instance
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

  if (currentUser.uid != post.uid) {
    final currentUserDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
    final senderName =
        currentUserDoc.data()?['displayName'] ?? 'Một người dùng';
    final postContent = post.content ?? post.postDescription ?? '';

    await Notification_API.sendShareNotification(
      senderName,
      post.uid!,
      postContent,
      post.postId!,
    );

    await Notification_API.saveShareNotificationToFirestore(
      receiverId: post.uid!,
      senderId: currentUser.uid,
      senderName: senderName,
      postId: post.postId!,
      postContent: postContent,
    );
  }

  Get.snackbar(
    "Thành công",
    "Đã chia sẻ bài viết thành công!",
    backgroundColor: Colors.blue.withOpacity(0.9),
    colorText: Colors.white,
    duration: const Duration(seconds: 4),
  );

  if (onShared != null) {
    onShared(); // Gọi callback cập nhật UI
  }
}

Future<void> reportPost(
  BuildContext context,
  String postId,
  String reason,
) async {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) return;

  final reportData = {
    'postId': postId,
    'reason': reason,
    'userId': currentUser.uid,
    'reportedAt': Timestamp.now(),
  };

  await FirebaseFirestore.instance.collection('post_reports').add(reportData);

  Get.snackbar(
    "Thành công",
    "Bài viết đã được báo cáo thành công. Chúng tôi sẽ xem xét và xử lý sớm nhất có thể.",
    backgroundColor: Colors.blue.withOpacity(0.9),
    colorText: Colors.white,
    duration: const Duration(seconds: 4),
  );
}

Future<void> shareExternally(PostModel post) async {
  final content = post.content ?? '';
  final desc = post.postDescription ?? '';
  // final text = '$content\n\n$desc\n(Bài viết chia sẻ từ Learnity)';
  final text = '$content\n\n$desc';
  const subject = 'Bài viết chia sẻ từ Learnity';
  await Share.share(text, subject: subject,);
}
