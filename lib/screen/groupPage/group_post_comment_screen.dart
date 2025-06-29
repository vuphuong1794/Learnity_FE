import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:learnity/theme/theme.dart';
import 'package:provider/provider.dart';

import '../../api/group_api.dart';
import '../../models/group_post_model.dart';
import '../../models/user_info_model.dart';
import '../../theme/theme_provider.dart';
import '../../viewmodels/navigate_user_profile_viewmodel.dart';

class GroupPostCommentScreen extends StatefulWidget {
  final String groupId;
  final String postId;
  final bool isDarkMode;

  const GroupPostCommentScreen({
    super.key,
    required this.groupId,
    required this.postId,
    this.isDarkMode = false,
  });

  @override
  State<GroupPostCommentScreen> createState() => _GroupPostCommentScreenState();
}

class _GroupPostCommentScreenState extends State<GroupPostCommentScreen> {
  final GroupApi _groupApi = GroupApi();
  final TextEditingController _commentController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;

  GroupPostModel? _post;
  bool _isLoadingPost = true;
  bool _isLiked = false;
  int _likeCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchPostDetails();
  }

  Future<void> _fetchPostDetails() async {
    if (!mounted) return;
    setState(() => _isLoadingPost = true);

    final postData = await _groupApi.getPostDetails(
      widget.groupId,
      widget.postId,
    );

    if (mounted && postData != null) {
      setState(() {
        _post = postData;
        _isLiked = postData.isLikedByCurrentUser;
        _likeCount = postData.likedBy.length;
        _isLoadingPost = false;
      });
    } else if (mounted) {
      setState(() => _isLoadingPost = false);
    }
  }

  Future<void> _toggleLike() async {
    if (_post == null) return;

    final newLikedState = !_isLiked;
    final newLikeCount = newLikedState ? _likeCount + 1 : _likeCount - 1;

    setState(() {
      _isLiked = newLikedState;
      _likeCount = newLikeCount;
    });

    try {
      await _groupApi.handleLikePost(
        widget.groupId,
        widget.postId,
        !newLikedState,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLiked = !newLikedState;
          _likeCount = newLikedState ? newLikeCount - 1 : newLikeCount + 1;
        });
      }
    }
  }

  Future<void> _submitComment() async {
    final commentText = _commentController.text.trim();
    if (commentText.isEmpty) return;

    _commentController.clear();
    FocusScope.of(context).unfocus();
    await _groupApi.postComment(widget.groupId, widget.postId, commentText);
  }

  String formatTime(Timestamp? timestamp) {
    if (timestamp == null) return 'Vừa xong';
    final DateTime dateTime = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return DateFormat('dd MMM, HH:mm').format(dateTime);
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m trước';
    } else {
      return 'Vừa xong';
    }
  }

  Widget _buildCommentInput() {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return Container(
      color: AppBackgroundStyles.secondaryBackground(isDarkMode),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                style: TextStyle(color: AppTextStyles.normalTextColor(isDarkMode)),
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: 'Viết bình luận...',
                  hintStyle: TextStyle(
                    color: AppTextStyles.normalTextColor(isDarkMode).withOpacity(0.5),
                  ),
                  filled: true,
                  fillColor: AppBackgroundStyles.buttonBackgroundSecondary(isDarkMode),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
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
              color: AppIconStyles.iconPrimary(isDarkMode),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _submitComment,
              child: Icon(
                Icons.send,
                size: 28,
                color: AppIconStyles.iconPrimary(isDarkMode),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    if (_isLoadingPost) {
      return Scaffold(
        backgroundColor: AppBackgroundStyles.mainBackground(isDarkMode),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
            onPressed: () => Navigator.pop(context,true),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_post == null) {
      return Scaffold(
        backgroundColor: AppBackgroundStyles.mainBackground(isDarkMode),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Text(
            'Không tìm thấy bài viết.',
            style: AppTextStyles.body(isDarkMode),
          ),
        ),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppBackgroundStyles.mainBackground(isDarkMode),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'Bài viết',
                      style: AppTextStyles.title(isDarkMode),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(thickness: 1),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance.collection('users').doc(_post!.authorUid).snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || !snapshot.data!.exists) {
                          return Row(
                            children: [
                              const CircleAvatar(radius: 22, child: Icon(Icons.person)),
                              const SizedBox(width: 10),
                              Text("Người dùng", style: AppTextStyles.subtitle2(isDarkMode)),
                            ],
                          );
                        }

                        final userData = snapshot.data!.data() as Map<String, dynamic>;
                        final avatarUrl = userData['avatarUrl'] ?? '';
                        final username = userData['username'] ?? 'Không tên';

                        return Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: isDarkMode
                                  ? AppColors.darkButtonBgProfile
                                  : AppColors.buttonBgProfile,
                              backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                              child: avatarUrl.isEmpty
                                  ? Icon(
                                Icons.person,
                                color: isDarkMode
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
                                    username,
                                    style: AppTextStyles.subtitle2(isDarkMode),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                  ),
                  if (_post!.title != null && _post!.title!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Text(
                        _post!.title!,
                        style: AppTextStyles.subtitle(
                          isDarkMode,
                        ).copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  if (_post!.text != null && _post!.text!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Text(
                        _post!.text!,
                        style: AppTextStyles.body(isDarkMode),
                      ),
                    ),
                  if (_post!.imageUrl != null && _post!.imageUrl!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _post!.imageUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                              ),
                            );
                          },
                          errorBuilder:
                              (context, error, stackTrace) => Container(
                                height: 200,
                                width: double.infinity,
                                color: Colors.grey[300],
                                child: Icon(
                                  Icons.broken_image,
                                  color: Colors.grey[600],
                                  size: 40,
                                ),
                              ),
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
                          onTap: _toggleLike,
                          child: Row(
                            children: [
                              Icon(
                                _isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color:
                                    _isLiked
                                        ? Colors.red
                                        : (isDarkMode
                                            ? AppColors.darkTextThird
                                            : AppColors.textThird),
                                size: 22,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _likeCount.toString(),
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
                              _firestore
                                  .collection('communityGroups')
                                  .doc(widget.groupId)
                                  .collection('posts')
                                  .doc(widget.postId)
                                  .collection('comments')
                                  .snapshots(),
                          builder: (context, snapshot) {
                            final count =
                                snapshot.data?.docs.length ??
                                _post!.commentsCount;
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
                        // const SizedBox(width: 4),
                        // Text(_post!.sharesCount.toString(), style: AppTextStyles.bodySecondary(isDarkMode)),
                      ],
                    ),
                  ),
                  const Divider(indent: 16, endIndent: 16),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Text(
                      'Bình luận',
                      style: AppTextStyles.subtitle2(isDarkMode),
                    ),
                  ),
                  StreamBuilder<QuerySnapshot>(
                    stream:
                        _firestore
                            .collection('communityGroups')
                            .doc(widget.groupId)
                            .collection('posts')
                            .doc(widget.postId)
                            .collection('comments')
                            .orderBy('createdAt', descending: true)
                            .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Text(
                              'Chưa có bình luận nào',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.normal,
                                color: AppTextStyles.subTextColor(isDarkMode),
                              ),
                            ),
                          ),
                        );
                      }

                      final commentsDocs = snapshot.data!.docs;
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: commentsDocs.length,
                        itemBuilder: (context, index) {
                          final commentDoc = commentsDocs[index];
                          final commentData = commentDoc.data() as Map<String, dynamic>;
                          final commentTimestamp = commentData['createdAt'] as Timestamp?;
                          final authorUid = commentData['authorUid'] as String?;
                          final commentContent = commentData['content'] ?? '';

                          if (authorUid == null) {
                            return const SizedBox(); // Trường hợp thiếu UID, bỏ qua
                          }

                          return StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance.collection('users').doc(authorUid).snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData || !snapshot.data!.exists) {
                                return ListTile(
                                  leading: CircleAvatar(
                                    radius: 18,
                                    backgroundColor: isDarkMode
                                        ? AppColors.darkButtonBgProfile
                                        : AppColors.buttonBgProfile,
                                    child: Icon(
                                      Icons.person,
                                      size: 18,
                                      color: isDarkMode
                                          ? AppColors.darkTextPrimary
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  title: Text(
                                    'Người dùng',
                                    style: AppTextStyles.body(isDarkMode).copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    commentContent,
                                    style: AppTextStyles.body(isDarkMode),
                                  ),
                                  trailing: Text(
                                    formatTime(commentTimestamp),
                                    style: AppTextStyles.bodySecondary(isDarkMode).copyWith(fontSize: 10),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                  dense: true,
                                );
                              }

                              final userData = snapshot.data!.data() as Map<String, dynamic>;
                              final avatarUrl = userData['avatarUrl'] ?? '';
                              final username = userData['username'] ?? 'Không tên';
                              final uid = snapshot.data!.id;

                              final userInfo = UserInfoModel(
                                uid: uid,
                                username: username,
                                avatarUrl: avatarUrl,
                                // bổ sung thêm các trường nếu cần (email, bio,...)
                              );
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: ListTile(
                                  leading: GestureDetector(
                                    onTap: () => navigateToUserProfileById(context, authorUid),
                                    child: CircleAvatar(
                                      radius: 18,
                                      backgroundColor: isDarkMode
                                          ? AppColors.darkButtonBgProfile
                                          : AppColors.buttonBgProfile,
                                      backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                                      child: avatarUrl.isEmpty
                                          ? Icon(
                                        Icons.person,
                                        size: 18,
                                        color: isDarkMode
                                            ? AppColors.darkTextPrimary
                                            : AppColors.textPrimary,
                                      )
                                          : null,
                                    ),
                                  ),
                                  title: GestureDetector(
                                    onTap: () => navigateToUserProfileById(context, authorUid),
                                    child: Text(
                                      username,
                                      style: AppTextStyles.body(isDarkMode)
                                          .copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  subtitle: Text(
                                    commentContent,
                                    style: AppTextStyles.body(isDarkMode),
                                  ),
                                  trailing: Text(
                                    formatTime(commentTimestamp),
                                    style: AppTextStyles.bodySecondary(isDarkMode).copyWith(fontSize: 10),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                  dense: true,
                                ),
                              );

                            },
                          );
                        },
                      );

                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          Positioned(bottom: 0, left: 0, right: 0, child: _buildCommentInput()),
        ],
      ),
    );
  }
}
