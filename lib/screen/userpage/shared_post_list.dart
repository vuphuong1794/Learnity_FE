import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/user_info_model.dart';
import '../../models/post_model.dart';
import '../../viewmodels/navigate_user_profile_viewmodel.dart';
import '../../widgets/handle_shared_post_interaction.dart';
import '../homePage/ImageViewerPage.dart';
import '../homePage/post_detail_page.dart';
import '../../widgets/common/time_utils.dart';

import 'package:provider/provider.dart';
import 'package:learnity/theme/theme.dart';
import 'package:learnity/theme/theme_provider.dart';

class SharedPostList extends StatefulWidget {
  final String sharerUid;
  const SharedPostList({super.key, required this.sharerUid});

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

    if (currentUser == null) {
      if (mounted) setState(() => isLoading = false);
      return;
    }

    final sharedPostQuery =
        await FirebaseFirestore.instance
            .collection('shared_posts')
            .where('sharerUserId', isEqualTo: widget.sharerUid)
            .orderBy('sharedAt', descending: true)
            .get();

    print('Tìm thấy ${sharedPostQuery.docs.length} bài đã chia sẻ');

    final results = await Future.wait(
      sharedPostQuery.docs.map((doc) async {
        final data = doc.data();
        final bool isGroupShare =
            data.containsKey('sharedInfo') && data['sharedInfo'] != null;

        final sharerUserId = data['sharerUserId'];
        final originUserId = data['originUserId'];

        final sharerSnap =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(sharerUserId)
                .get();
        final posterSnap =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(originUserId)
                .get();

        if (!sharerSnap.exists || !posterSnap.exists) return null;

        final sharer = UserInfoModel.fromDocument(sharerSnap);
        final poster = UserInfoModel.fromDocument(posterSnap);

        if (isGroupShare) {
          print('→ Đang xử lý bài chia sẻ từ nhóm: ${doc.id}');
          // Nếu là group share và bị đánh dấu ẩn thì bỏ qua
          if (data['isHidden'] == true) {
            print('→ Bỏ qua bài chia sẻ nhóm bị ẩn: ${doc.id}');
            return null;
          }
          final postFromGroupShare = PostModel(
            createdAt: (data['sharedAt'] as Timestamp).toDate(),
            content: data['text'],
            uid: data['originUserId'],
            postId: data['postId'] ?? doc.id,
            imageUrls:
                (data['imageUrls'] as List?)?.map((e) => e.toString()).toList(),
            postDescription: data['postDescription'] ?? '',
          );

          return {
            'post': postFromGroupShare,
            'sharer': sharer,
            'poster': poster,
            'sharedAt': doc['sharedAt'],
            'sharedPostId': doc.id,
            'originalGroupName': data['sharedInfo']['originalGroupName'],
          };
        } else {
          // Bài viết chia sẻ từ người dùng khác (
          final postId = data['postId'];
          final postSnap =
              await FirebaseFirestore.instance
                  .collection('posts')
                  .doc(postId)
                  .get();

          if (!postSnap.exists) {
            print(
              '→ Không tìm thấy bài viết gốc với postId: $postId trong collection "posts"',
            );
            return null;
          }
          final postData = postSnap.data();
          if (postData == null || postData['isHidden'] == true) {
            print('→ Bỏ qua bài viết bị ẩn: $postId');
            return null;
          }

          print('→ Đang xử lý bài chia sẻ từ người dùng: ${doc.id}');
          return {
            'post': PostModel.fromDocument(postSnap),
            'sharer': sharer,
            'poster': poster,
            'sharedAt': doc['sharedAt'],
            'sharedPostId': doc.id,
            'originalGroupName': null,
          };
        }
      }),
    );

    if (mounted) {
      setState(() {
        postUserPairs = results.whereType<Map<String, dynamic>>().toList();
        isLoading = false;
      });
    }
  }

  Future<int> getCommentCount(String docId, {bool isShared = false}) async {
    final collection =
        isShared
            ? 'shared_post_comments'
            : 'shared_post_comments';

    final snapshot =
        await FirebaseFirestore.instance
            .collection(collection)
            .doc(docId)
            .collection('comments')
            .get();

    return snapshot.docs.length;
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
        child: _buildImageWidget(imageUrl, isDarkMode,
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
                child: _buildImageWidget(imageUrls[0], isDarkMode,
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
                child: _buildImageWidget(imageUrls[1], isDarkMode,
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
                child: _buildImageWidget(imageUrls[0], isDarkMode,
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
                      child: _buildImageWidget(imageUrls[1], isDarkMode,
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
                      child: _buildImageWidget(imageUrls[2], isDarkMode,
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
                child: _buildImageWidget(imageUrls[0], isDarkMode,
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
                      child: _buildImageWidget(imageUrls[1], isDarkMode,
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
                          _buildImageWidget(imageUrls[2], isDarkMode,
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

  Widget _buildImageWidget(String imageUrl, bool isDarkMode, {
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
            color: isDarkMode
                ? AppColors.darkTextThird.withOpacity(0.1)
                : AppColors.textThird.withOpacity(0.1),
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
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
      color: isDarkMode
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
        builder: (context) => ImageViewerPage(
          imageUrls: imageUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    if (isLoading) return const Center(child: CircularProgressIndicator());

    if (postUserPairs.isEmpty) {
      return Text("Chưa chia sẻ bài viết nào", style: AppTextStyles.body(isDarkMode));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: postUserPairs.length,
      itemBuilder: (context, index) {
        final post = postUserPairs[index]['post'] as PostModel;
        final sharedPostId = postUserPairs[index]['sharedPostId'] as String?;
        final sharerUserId = postUserPairs[index]['sharer'].uid;
        final item = postUserPairs[index];
        return _buildSharedPost(
          sharer: item['sharer'],
          originalPoster: item['poster'],
          post: post,
          sharedAt:
              (item['sharedAt'] != null)
                  ? (item['sharedAt'] as Timestamp).toDate()
                  : DateTime.now(),
          sharedPostId: sharedPostId ?? '',
          sharerUserId: sharerUserId,
          isDarkMode: isDarkMode,
          originalGroupName: item['originalGroupName'],
        );
      },
    );
  }

  Widget _buildSharedPost({
    required UserInfoModel sharer,
    required UserInfoModel originalPoster,
    required PostModel post,
    required DateTime sharedAt,
    required String sharedPostId,
    required String sharerUserId,
    required bool isDarkMode,
    String? originalGroupName,
  }) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    return Container(
      // margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppBackgroundStyles.boxBackground(isDarkMode),
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
                  backgroundImage:
                      (sharer.avatarUrl != null && sharer.avatarUrl!.isNotEmpty)
                          ? NetworkImage(sharer.avatarUrl!)
                          : const AssetImage('assets/default_avatar.png')
                              as ImageProvider,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      // style: const TextStyle(color: Colors.black),
                      children: [
                        TextSpan(
                          text: sharer.displayName ?? "",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTextStyles.normalTextColor(isDarkMode),
                          ),
                        ),
                        TextSpan(
                          text: " đã chia sẻ bài viết của ",
                          style: TextStyle(
                            color: AppTextStyles.normalTextColor(isDarkMode),
                          ),
                        ),
                        TextSpan(
                          text: originalPoster.displayName ?? "",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTextStyles.normalTextColor(isDarkMode),
                          ),
                        ),
                        if (originalGroupName != null &&
                            originalGroupName.isNotEmpty) ...[
                          TextSpan(
                            text: " từ nhóm ",
                            style: TextStyle(
                              color: AppTextStyles.normalTextColor(isDarkMode),
                            ),
                          ),
                          TextSpan(
                            text: originalGroupName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTextStyles.normalTextColor(isDarkMode),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Text(
                  formatTime(sharedAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTextStyles.subTextColor(isDarkMode),
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Shared content block
          GestureDetector(
            onLongPress: () {
              handleSharedPostInteraction(
                context: context,
                sharedPostId: sharedPostId,
                sharerUserId: sharerUserId,
                onDeleteSuccess: () {
                  if (mounted) {
                    setState(() {
                      postUserPairs.removeWhere(
                        (item) => item['sharedPostId'] == sharedPostId,
                      );
                    });
                  }
                },
                isDarkMode: isDarkMode
              );
            },
            child: Container(
              margin: const EdgeInsets.only(left: 40),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppBackgroundStyles.boxBackground(isDarkMode),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTextStyles.normalTextColor(
                    isDarkMode,
                  ).withOpacity(0.2), // Màu viền
                  width: 1, // Độ dày viền
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap:
                            () =>
                                navigateToUserProfile(context, originalPoster),
                        child: CircleAvatar(
                          backgroundColor: Colors.white,
                          backgroundImage:
                              (originalPoster.avatarUrl != null &&
                                      originalPoster.avatarUrl!.isNotEmpty)
                                  ? NetworkImage(originalPoster.avatarUrl!)
                                  : const AssetImage(
                                        'assets/default_avatar.png',
                                      )
                                      as ImageProvider,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap:
                              () => navigateToUserProfile(
                                context,
                                originalPoster,
                              ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                originalPoster.displayName ?? "",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppTextStyles.normalTextColor(
                                    isDarkMode,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                formatTime(post.createdAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTextStyles.subTextColor(isDarkMode),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),
                  if (post.postDescription != null &&
                      post.postDescription!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        post.postDescription!,
                        style: TextStyle(
                          fontSize: 14,
                          // fontStyle: FontStyle.italic,
                          color: AppTextStyles.normalTextColor(isDarkMode),
                        ),
                      ),
                    ),
                  const SizedBox(height: 6),
                  if (post.content != null && post.content!.isNotEmpty) ...[
                    Text(
                      post.content!,
                      style: TextStyle(
                        color: AppTextStyles.normalTextColor(isDarkMode),
                        fontSize: 15,
                      ),
                    ),
                    if (post.imageUrls != null && post.imageUrls!.isNotEmpty)
                      const SizedBox(height: 10),
                  ],
                  _buildImageDisplay(post.imageUrls, isDarkMode),
                ],
              ),
            ),
          ),

          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 40, top: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // LIKE BUTTON + COUNT
                StreamBuilder<DocumentSnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('shared_posts')
                          .doc(sharedPostId)
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Row(
                        children: [
                          Icon(
                            Icons.favorite_border,
                            size: 22,
                            color: AppTextStyles.subTextColor(isDarkMode),
                          ),
                          SizedBox(width: 4),
                          Text(
                            "0",
                            style: TextStyle(
                              fontSize: 16,
                              color: AppTextStyles.subTextColor(isDarkMode),
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      );
                    }

                    final doc = snapshot.data!;
                    final data = doc.data() as Map<String, dynamic>;
                    final likeBy = List<String>.from(data['likeBy'] ?? []);
                    final currentUid = FirebaseAuth.instance.currentUser?.uid;
                    final isLiked =
                        currentUid != null && likeBy.contains(currentUid);

                    return GestureDetector(
                      onTap: () async {
                        final ref = FirebaseFirestore.instance
                            .collection('shared_posts')
                            .doc(sharedPostId);
                        if (isLiked) {
                          await ref.update({
                            'likeBy': FieldValue.arrayRemove([currentUid]),
                          });
                        } else {
                          await ref.update({
                            'likeBy': FieldValue.arrayUnion([currentUid]),
                          });
                        }
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
                            "${likeBy.length}",
                            style: TextStyle(
                              fontSize: 16,
                              color: AppTextStyles.subTextColor(isDarkMode),
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(width: 22),

                FutureBuilder<int>(
                  future: getCommentCount(sharedPostId, isShared: true),
                  builder: (context, snapshot) {
                    final commentCount = snapshot.data ?? 0;

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => PostDetailPage(
                                  post: post,
                                  isDarkMode: isDarkMode,
                                  sharedPostId: sharedPostId,
                                ),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/chat_bubble.png',
                            width: 22,
                            color: AppTextStyles.subTextColor(isDarkMode),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "$commentCount",
                            style: TextStyle(
                              fontSize: 16,
                              color: AppTextStyles.subTextColor(isDarkMode),
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                Row(
                  children: [
                    if (currentUid != widget.sharerUid) ...[
                      const SizedBox(width: 22),
                      GestureDetector(
                        onTap: () {
                          _showShareOptions(
                            isDarkMode,
                            context,
                            post,
                            originalPoster,
                            sharedPostId,
                          );
                        },
                        child: Row(
                          children: [
                            Image.asset(
                              'assets/Share.png',
                              width: 22,
                              color: AppTextStyles.subTextColor(isDarkMode),
                            ),
                            const SizedBox(width: 4),
                            FutureBuilder<DocumentSnapshot>(
                              future:
                                  FirebaseFirestore.instance
                                      .collection('shared_post_stats')
                                      .doc(sharedPostId)
                                      .get(),
                              builder: (context, snapshot) {
                                final count =
                                    snapshot.hasData && snapshot.data!.exists
                                        ? (snapshot.data!.data()
                                                as Map<
                                                  String,
                                                  dynamic
                                                >)['shareCount'] ??
                                            0
                                        : 0;

                                return Text(
                                  "$count",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppTextStyles.subTextColor(
                                      isDarkMode,
                                    ),
                                    decoration: TextDecoration.none,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
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

Future<void> _shareInternally(
  BuildContext context,
  String postId,
  String originUserId, {
  String? parentSharedPostId,
}) async {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) return;

  final existing =
      await FirebaseFirestore.instance
          .collection('shared_posts')
          .where('postId', isEqualTo: postId)
          .where('sharerUserId', isEqualTo: currentUser.uid)
          .get();

  final stillExist = existing.docs.where((doc) => doc.exists).toList();

  if (stillExist.isNotEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn đã chia sẻ bài viết này rồi.')),
      );
    }
    return;
  }

  await FirebaseFirestore.instance.collection('shared_posts').add({
    'postId': postId,
    'originUserId': originUserId,
    'sharerUserId': currentUser.uid,
    'sharedAt': Timestamp.now(),
    'likeBy': [],
  });
  //  Nếu là share từ bài đã được chia sẻ → tăng shareCount riêng
  if (parentSharedPostId != null) {
    final statRef = FirebaseFirestore.instance
        .collection('shared_post_stats')
        .doc(parentSharedPostId);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final statSnap = await tx.get(statRef);
      if (statSnap.exists) {
        tx.update(statRef, {
          'shareCount': (statSnap.data()?['shareCount'] ?? 0) + 1,
        });
      } else {
        tx.set(statRef, {'shareCount': 1});
      }
    });
  }

  if (context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã chia sẻ bài viết')));
  }
}

Future<void> _shareExternally(PostModel post) async {
  final text = '${post.content ?? ''}\n\n${post.postDescription ?? ''}';
  await Share.share('$text\n(Chia sẻ từ Learnity)');
}

void _showShareOptions(
  bool isDarkMode,
  BuildContext context,
  PostModel post,
  UserInfoModel originUser,
  String? sharedPostId,
) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: AppBackgroundStyles.modalBackground(isDarkMode),
        title: Text(
          'Chia sẻ bài viết',
          style: TextStyle(color: AppTextStyles.normalTextColor(isDarkMode)),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                Icons.repeat,
                color: AppIconStyles.iconPrimary(isDarkMode),
              ),
              title: Text(
                'Chia sẻ trong ứng dụng',
                style: TextStyle(
                  color: AppTextStyles.normalTextColor(isDarkMode),
                ),
              ),
              onTap: () async {
                if (post.postId != null && originUser.uid != null) {
                  await _shareInternally(
                    context,
                    post.postId!,
                    originUser.uid!,
                    parentSharedPostId: sharedPostId,
                  );
                }
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.share,
                color: AppIconStyles.iconPrimary(isDarkMode),
              ),
              title: Text(
                'Chia sẻ ra ngoài',
                style: TextStyle(
                  color: AppTextStyles.normalTextColor(isDarkMode),
                ),
              ),
              onTap: () async {
                Navigator.pop(context);
                await _shareExternally(post);
              },
            ),
          ],
        ),
      );
    },
  );
}
