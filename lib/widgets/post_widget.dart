import 'package:flutter/material.dart';
import 'package:learnity/models/post_model.dart';
import 'package:learnity/theme/theme.dart';
import 'package:learnity/widgets/post_detail_page.dart';

class PostWidget extends StatefulWidget {
  final PostModel post;
  final bool isDarkMode;

  const PostWidget({
    Key? key,
    required this.post,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  State<PostWidget> createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  late bool isLiked;
  late int likeCount;

  @override
  void initState() {
    super.initState();
    isLiked = widget.post.isLiked;
    likeCount = widget.post.likes;
  }

  void _toggleLike() {
    setState(() {
      isLiked = !isLiked;
      likeCount += isLiked ? 1 : -1;
    });
  }

  void _goToDetail() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PostDetailPage(post: widget.post, isDarkMode: widget.isDarkMode),
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
                    backgroundImage: post.userImage != null ? NetworkImage(post.userImage!) : null,
                    child: post.userImage == null
                        ? Icon(
                            Icons.person,
                            color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.username?? "",
                          style: AppTextStyles.subtitle2(isDarkMode).copyWith(
                            color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
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
                                    color: isDarkMode ? AppColors.darkTextThird : AppColors.textThird,
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
                                    color: isDarkMode ? AppColors.darkTextThird : AppColors.textThird,
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
                      onTap: () {
                        _toggleLike();
                      },
                      child: Row(
                        children: [
                          Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? Colors.red : (isDarkMode ? AppColors.darkTextThird : AppColors.textThird),
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
                    InkWell(
                      onTap: _goToDetail,
                      child: Row(
                        children: [
                          Icon(
                            Icons.comment_outlined,
                            color: isDarkMode ? AppColors.darkTextThird : AppColors.textThird,
                            size: 22,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            post.comments.toString(),
                            style: AppTextStyles.bodySecondary(isDarkMode),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Share
                    Row(
                      children: [
                        Icon(
                          Icons.share_outlined,
                          color: isDarkMode ? AppColors.darkTextThird : AppColors.textThird,
                          size: 22,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          post.shares.toString(),
                          style: AppTextStyles.bodySecondary(isDarkMode),
                        ),
                      ],
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