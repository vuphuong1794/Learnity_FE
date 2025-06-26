import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:learnity/theme/theme.dart';
import 'package:provider/provider.dart';

import '../../api/group_api.dart';
import '../../models/group_post_model.dart';
import '../../theme/theme_provider.dart';

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
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                style: AppTextStyles.body(isDarkMode),
                decoration: InputDecoration(
                  hintText: 'Viết bình luận...',
                  hintStyle: AppTextStyles.bodySecondary(isDarkMode),
                  filled: true,
                  fillColor:
                      isDarkMode
                          ? AppColors.darkBackgroundSecond
                          : Colors.grey[200],
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
              color: isDarkMode ? AppColors.darkTextThird : Colors.black54,
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _submitComment,
              child: Icon(
                Icons.send,
                size: 28,
                color:
                    isDarkMode
                        ? AppColors.darkTextThird
                        : Theme.of(context).primaryColor,
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
                              _post!.authorAvatarUrl != null &&
                                      _post!.authorAvatarUrl!.isNotEmpty
                                  ? NetworkImage(_post!.authorAvatarUrl!)
                                  : null,
                          child:
                              (_post!.authorAvatarUrl == null ||
                                      _post!.authorAvatarUrl!.isEmpty)
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
                                _post!.authorUsername ?? " ",
                                style: AppTextStyles.subtitle2(isDarkMode),
                              ),
                            ],
                          ),
                        ),
                      ],
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
                              'Chưa có bình luận nào.',
                              style: AppTextStyles.body(isDarkMode),
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
                          final commentData =
                              commentsDocs[index].data()
                                  as Map<String, dynamic>;
                          final commentTimestamp =
                              commentData['createdAt'] as Timestamp?;
                          final commentAuthorAvatarUrl =
                              commentData['authorAvatarUrl'] as String?;

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                radius: 18,
                                backgroundColor:
                                    isDarkMode
                                        ? AppColors.darkButtonBgProfile
                                        : AppColors.buttonBgProfile,
                                backgroundImage:
                                    commentAuthorAvatarUrl != null &&
                                            commentAuthorAvatarUrl.isNotEmpty
                                        ? NetworkImage(commentAuthorAvatarUrl)
                                        : null,
                                child:
                                    (commentAuthorAvatarUrl == null ||
                                            commentAuthorAvatarUrl.isEmpty)
                                        ? Icon(
                                          Icons.person,
                                          size: 18,
                                          color:
                                              isDarkMode
                                                  ? AppColors.darkTextPrimary
                                                  : AppColors.textPrimary,
                                        )
                                        : null,
                              ),
                              title: Text(
                                commentData['authorUsername'] ?? '',
                                style: AppTextStyles.body(
                                  isDarkMode,
                                ).copyWith(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                commentData['content'] ?? '',
                                style: AppTextStyles.body(isDarkMode),
                              ),
                              trailing: Text(
                                formatTime(commentTimestamp),
                                style: AppTextStyles.bodySecondary(
                                  isDarkMode,
                                ).copyWith(fontSize: 10),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 2,
                              ),
                              dense: true,
                            ),
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
