import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:learnity/theme/theme.dart';
import 'package:provider/provider.dart';
import '../../models/post_model.dart';
import '../../theme/theme_provider.dart';
import '../../viewmodels/social_feed_viewmodel.dart';
import '../../widgets/full_screen_image_page.dart';
import '../../widgets/post_item.dart';
import '../../models/user_info_model.dart';
import '../../widgets/post_widget.dart';
import 'comment_thread.dart';
import 'create_post_page.dart';
import 'shared_post_list.dart';

class TheirProfilePage extends StatefulWidget {
  final UserInfoModel user;

  const TheirProfilePage({super.key, required this.user});

  @override
  State<TheirProfilePage> createState() => _TheirProfilePageState();
}

class _TheirProfilePageState extends State<TheirProfilePage> {
  late SocialFeedViewModel _viewModel;
  String selectedTab = "Bài đăng";
  // bool isFollowing = false;
  bool get isFollowing {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    return widget.user.followers?.contains(currentUid) ?? false;
  }
  UserInfoModel currentUser = UserInfoModel(
    uid: '',
    username: '',
    displayName: '',
    avatarUrl: '',
  );
  @override
  void initState() {
    super.initState();
    currentUser = widget.user;
    _viewModel = SocialFeedViewModel();
  }
  Future<void> _handleFollow() async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return;

    final isNowFollowing = !(widget.user.followers?.contains(currentUid) ?? false);

    await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).update({
      'followers': isNowFollowing
          ? FieldValue.arrayUnion([currentUid])
          : FieldValue.arrayRemove([currentUid]),
    });

    setState(() {
      if (isNowFollowing) {
        widget.user.followers ??= [];
        widget.user.followers!.add(currentUid);
      } else {
        widget.user.followers?.remove(currentUid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                // Logo + tiêu đề
                Stack(
                  children: [
                    Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          Image.asset('assets/learnity.png', height: 110),
                          const Text(
                            "Trang cá nhân",
                            style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold),
                          ),
                          const Divider(thickness: 1, color: Colors.black),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, size: 30),
                        onPressed: () {
                          Navigator.pop(context, true);
                        },
                      ),
                    ),
                  ],
                ),
                // Thông tin người dùng + nút + avatar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Bên trái: thông tin + 2 nút
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Thông tin cá nhân
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(widget.user.displayName ?? "Không có tên",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold, fontSize: 30)),
                                  Text(widget.user.username ?? "Không có tên",
                                      style: const TextStyle(fontSize: 20)),
                                  const SizedBox(height: 10),
                                  Text("${widget.user.followers?.length ?? 0} người theo dõi",
                                      style: const TextStyle(
                                          fontSize: 16, color: Colors.black54)
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 12),


                          ],
                        ),
                      ),

                      // Avatar bên phải
                      Padding(
                        padding: const EdgeInsets.only(left: 15),
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FullScreenImagePage(imageUrl: widget.user.avatarUrl ?? ''),
                                  ),
                                );
                              },
                              child: CircleAvatar(
                                radius: 50,
                                backgroundImage: (widget.user.avatarUrl != null && widget.user.avatarUrl!.isNotEmpty)
                                    ? NetworkImage(widget.user.avatarUrl!)
                                    : null,
                                child: (widget.user.avatarUrl == null || widget.user.avatarUrl!.isEmpty)
                                    ? const Icon(Icons.person, size: 50)
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 5),
                            // Nút Theo dõi và Nhắn tin
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 100,
                                  child: ElevatedButton(
                                    onPressed: _handleFollow,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.darkBackground,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      padding: const EdgeInsets.symmetric(vertical:4),
                                      minimumSize: const Size(0, 30),
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      isFollowing ? "Đã theo dõi" : "Theo dõi",
                                      style: TextStyle(color: AppColors.background, fontSize: 15),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 100,
                                  child: ElevatedButton(
                                    onPressed: _messageUser,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                      minimumSize: const Size(0, 30),
                                    ),
                                    child: const Text("Nhắn tin", style: TextStyle(color: Colors.black, fontSize: 15)),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),

                      // Avatar bên phải
                      // Padding(
                      //   padding: const EdgeInsets.only(left: 15),
                      //   child: CircleAvatar(
                      //     radius: 50,
                      //     backgroundColor: Colors.white,
                      //     backgroundImage: AssetImage(widget.user.avatarUrl ?? 'assets/avatar.png'),
                      //   ),
                      // ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Tabs
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTabButton("Bài đăng"),
                    _buildTabButton("Bình luận"),
                    _buildTabButton("Bài chia sẻ"),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(thickness: 1, color: Colors.black),
                const SizedBox(height: 10),

                // Nội dung theo tab
                if (selectedTab == "Bài đăng")
                // Kiểm tra widget.user.uid để lấy bài đăng của người đang xem
                  widget.user.uid == null || widget.user.uid!.isEmpty
                      ? Center(
                    child: Text(
                      'Không thể tải bài viết, thông tin người dùng không hợp lệ.',
                      style: AppTextStyles.body(isDarkMode),
                    ),
                  )
                      : FutureBuilder<List<PostModel>>(
                    future: _viewModel.getUserPosts(currentUser.uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Lỗi khi tải bài viết: ${snapshot.error}',
                            style: AppTextStyles.error(isDarkMode),
                          ),
                        );
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Text(
                            'Bạn chưa có bài viết nào',
                            style: AppTextStyles.body(isDarkMode),
                          ),
                        );
                      }
                      // Phần ListView.separated giữ nguyên
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: snapshot.data!.length + 1,
                        separatorBuilder: (context, index) {
                          if (index == 0 && (snapshot.data == null || snapshot.data!.isEmpty)) {
                            return const SizedBox.shrink();
                          }
                          if (index == 0) {
                            return const SizedBox.shrink();
                          }
                          return const Divider(height: 1);
                        },
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const CreatePostPage(),
                                  ),
                                ).then((value) {
                                  if (value == true) {
                                    if (mounted) {
                                      setState(() {
                                      });
                                    }
                                  }
                                });
                              },
                              child: Container(
                                color: Colors.transparent,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            );
                          }
                          final post = snapshot.data![index - 1];
                          return PostWidget(post: post, isDarkMode: isDarkMode);
                        },
                      );
                    },
                  ),
                if (selectedTab == "Bình luận") const CommentThread(),
                if (selectedTab == "Bài chia sẻ") const SharedPostList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(String label) {
    final isSelected = selectedTab == label;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          selectedTab = label;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? AppColors.buttonEditProfile : Colors.grey,
        foregroundColor: isSelected ? AppColors.background : Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        minimumSize: const Size(0, 30),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 16)),
    );
  }

  // void _followUser() {
  //   setState(() {
  //     isFollowing = !isFollowing;
  //   });
  // }

  void _messageUser() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Mở giao diện nhắn tin")),
    );
  }
}
