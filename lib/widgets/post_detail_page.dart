import 'package:flutter/material.dart';
import 'package:learnity/models/post_model.dart';
import 'package:learnity/theme/theme.dart';
import 'package:provider/provider.dart';
import 'package:learnity/theme/theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostDetailPage extends StatefulWidget {
  final PostModel post;
  final bool isDarkMode;
  const PostDetailPage({super.key, required this.post, required this.isDarkMode});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final TextEditingController _commentController = TextEditingController();
  final List<Map<String, String>> _comments = [];
  late bool isLiked;
  late int likeCount;
  final user = FirebaseAuth.instance.currentUser;

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

  void _sendComment() {
    final text = _commentController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _comments.add({
          'username': user?.displayName ?? user?.email?.split('@').first ?? 'User',
          'content': text,
        });
        _commentController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final post = widget.post;
    final mq = MediaQuery.of(context);
    return Scaffold(
      backgroundColor: AppBackgroundStyles.mainBackground(isDarkMode),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: mq.size.height - mq.padding.top - mq.padding.bottom),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Center(child: Image.asset('assets/learnity.png', height: 60)),
                  const SizedBox(height: 8),
                  Center(
                    child: Text('Bài viết',
                        style: AppTextStyles.title(isDarkMode)),
                  ),
                  const SizedBox(height: 8),
                  const Divider(thickness: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: isDarkMode ? AppColors.darkButtonBgProfile : AppColors.buttonBgProfile,
                          child: Icon(Icons.person, color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(post.username, style: AppTextStyles.subtitle2(isDarkMode)),
                              if (post.postDescription != null)
                                Text(post.postDescription!, style: AppTextStyles.body(isDarkMode)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (post.content != null && post.content!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Text(post.content!, style: AppTextStyles.body(isDarkMode)),
                    ),
                  if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: post.imageUrl!.startsWith('assets/')
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: _toggleLike,
                          child: Row(
                            children: [
                              Icon(
                                isLiked ? Icons.favorite : Icons.favorite_border,
                                color: isLiked ? Colors.red : (isDarkMode ? AppColors.darkTextThird : AppColors.textThird),
                                size: 22,
                              ),
                              const SizedBox(width: 4),
                              Text(likeCount.toString(), style: AppTextStyles.bodySecondary(isDarkMode)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 18),
                        Icon(Icons.comment_outlined, size: 22, color: isDarkMode ? AppColors.darkTextThird : AppColors.textThird),
                        const SizedBox(width: 4),
                        Text(post.comments.toString(), style: AppTextStyles.bodySecondary(isDarkMode)),
                        const SizedBox(width: 18),
                        Icon(Icons.share_outlined, size: 22, color: isDarkMode ? AppColors.darkTextThird : AppColors.textThird),
                        const SizedBox(width: 4),
                        Text(post.shares.toString(), style: AppTextStyles.bodySecondary(isDarkMode)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text('Bình luận', style: AppTextStyles.subtitle2(isDarkMode)),
                  ),
                  ..._comments.map((c) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: isDarkMode ? AppColors.darkButtonBgProfile : AppColors.buttonBgProfile,
                              child: Icon(Icons.person, color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c['username'] ?? '', style: AppTextStyles.body(isDarkMode).copyWith(fontWeight: FontWeight.bold)),
                                Text(c['content'] ?? '', style: AppTextStyles.body(isDarkMode)),
                              ],
                            ),
                          ],
                        ),
                      )),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            decoration: InputDecoration(
                              hintText: 'Viết bình luận...',
                              filled: true,
                              fillColor: isDarkMode ? AppColors.darkBackgroundSecond : Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.image_outlined, size: 28, color: isDarkMode ? AppColors.darkTextThird : Colors.black54),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _sendComment,
                          child: Icon(Icons.send, size: 28, color: isDarkMode ? AppColors.darkTextThird : Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 