import 'package:flutter/material.dart';
import 'package:learnity/screen/userPage/edit_profile_page.dart';
import '../../models/post_model.dart';
import '../../viewmodels/social_feed_viewmodel.dart';
import '../../models/user_info_model.dart';
import '../../widgets/homePage/post_widget.dart';
import 'comment_thread.dart';
import '../createPostPage/create_post_page.dart';
import 'shared_post_list.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:provider/provider.dart';
import 'package:learnity/theme/theme.dart';
import 'package:learnity/theme/theme_provider.dart';

class ProfilePage extends StatefulWidget {
  final UserInfoModel user;

  const ProfilePage({super.key, required this.user});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String selectedTab = "Bài đăng";
  late SocialFeedViewModel _viewModel;
  UserInfoModel currentUser = UserInfoModel(
    uid: '',
    username: '',
    displayName: '',
    avatarUrl: '',
  );
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    currentUser = widget.user;
    _viewModel = SocialFeedViewModel();
    _refreshUserData();
  }

  // Phương thức để refresh dữ liệu người dùng từ Firestore
  Future<void> _refreshUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (doc.exists && mounted) {
        final data = doc.data();
        if (data != null) {
          setState(() {
            // Cập nhật thông tin người dùng hiện tại
            currentUser = UserInfoModel(
              uid: uid,
              username: data['username'],
              displayName: data['displayName'],
              avatarUrl: data['avatarUrl'],
              bio: data['bio'] ?? currentUser.bio,
              followers: List<String>.from(data['followers'] ?? []),
            );
          });
        }
      }
    } catch (e) {
      debugPrint('Lỗi khi tải dữ liệu người dùng: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: AppBackgroundStyles.mainBackground(isDarkMode),
      body: SafeArea(
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      children: [
                        // Nút quay lại
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: Icon(
                              Icons.arrow_back,
                              size: 28,
                              color: AppTextStyles.buttonTextColor(isDarkMode),
                            ),
                            onPressed: () {
                              Navigator.pop(context, true);
                            },
                          ),
                        ),

                        Text(
                          "Trang cá nhân",
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: AppTextStyles.buttonTextColor(isDarkMode),
                          ),
                        ),
                        Divider(
                          thickness: 1,
                          color: AppTextStyles.buttonTextColor(
                            isDarkMode,
                          ).withOpacity(0.2),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (currentUser.displayName?.trim().isNotEmpty == true)
                                          ? currentUser.displayName!
                                          : (currentUser.username?.trim().isNotEmpty == true
                                          ? currentUser.username!
                                          : "Name less"),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 30,
                                        color: AppTextStyles.buttonTextColor(
                                          isDarkMode,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      currentUser.username ?? "Name less",
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w500,
                                        color: AppTextStyles.buttonTextColor(
                                          isDarkMode,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      currentUser.bio ?? "Không có thông tin",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: AppTextStyles.buttonTextColor(
                                          isDarkMode,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      "${currentUser.followers?.length ?? 0} người theo dõi",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: AppTextStyles.buttonTextColor(
                                          isDarkMode,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ElevatedButton(
                                      onPressed: () async {
                                        // Điều hướng đến trang chỉnh sửa và đợi kết quả
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) => EditProfilePage(
                                                  currentUser: currentUser,
                                                ),
                                          ),
                                        );

                                        // Nếu có dữ liệu trả về hoặc đơn giản là đã quay lại
                                        // thì refresh lại dữ liệu người dùng
                                        if (result == true || result != null) {
                                          _refreshUserData();
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            AppBackgroundStyles.buttonBackground(
                                              isDarkMode,
                                            ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        minimumSize: const Size(0, 36),
                                      ),
                                      child: Text(
                                        "Chỉnh sửa trang cá nhân",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: AppTextStyles.buttonTextColor(
                                            isDarkMode,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: _buildAvatar(currentUser.avatarUrl),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),
                        // Tabs
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildTabButton(isDarkMode, "Bài đăng"),
                            // _buildTabButton(isDarkMode, "Bình luận"),
                            _buildTabButton(isDarkMode, "Bài chia sẻ"),
                          ],
                        ),
                        Divider(
                          thickness: 1,
                          color: AppTextStyles.buttonTextColor(
                            isDarkMode,
                          ).withOpacity(0.2),
                        ),

                        if (selectedTab == "Bài đăng")
                          // Kiểm tra xem currentUser.uid có rỗng không trước khi gọi API
                          currentUser.uid!.isEmpty
                              ? Center(
                                child: Text(
                                  'Không thể tải bài viết, thông tin người dùng không hợp lệ.',
                                  style: AppTextStyles.body(isDarkMode),
                                ),
                              )
                              : FutureBuilder<List<PostModel>>(
                                future: _viewModel.getUserPosts(
                                  currentUser.uid,
                                ),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  } else if (snapshot.hasError) {
                                    return Center(
                                      child: Text(
                                        'Lỗi khi tải bài viết: ${snapshot.error}',
                                        style: AppTextStyles.error(isDarkMode),
                                      ),
                                    );
                                  }

                                  // Lọc các bài không bị ẩn
                                  final visiblePosts =
                                      snapshot.data!
                                          .where(
                                            (post) => post.isHidden != true,
                                          )
                                          .toList();

                                  if (visiblePosts.isEmpty) {
                                    return Center(
                                      child: Text(
                                        'Bạn chưa có bài viết nào đang hiển thị',
                                        style: AppTextStyles.body(isDarkMode),
                                      ),
                                    );
                                  }

                                  return ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: visiblePosts.length + 1,
                                    separatorBuilder: (context, index) {
                                      if (index == 0)
                                        return const SizedBox.shrink();
                                      return const Divider(height: 1);
                                    },
                                    itemBuilder: (context, index) {
                                      if (index == 0) {
                                        return GestureDetector(
                                          onTap: () {
                                            Navigator.of(context)
                                                .push(
                                                  MaterialPageRoute(
                                                    builder:
                                                        (_) =>
                                                            const CreatePostPage(),
                                                  ),
                                                )
                                                .then((value) {
                                                  if (value == true &&
                                                      mounted) {
                                                    setState(() {});
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
                                      final post = visiblePosts[index - 1];
                                      return PostWidget(
                                        post: post,
                                        isDarkMode: isDarkMode,
                                      );
                                    },
                                  );
                                },
                              ),
                        if (selectedTab == "Bài chia sẻ")
                          SizedBox(
                            child: SharedPostList(sharerUid: currentUser.uid!),
                          ),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }

  Widget _buildAvatar(String? avatarUrl) {
    ImageProvider backgroundImage;
    if (avatarUrl != null &&
        avatarUrl.isNotEmpty &&
        avatarUrl.startsWith('http')) {
      backgroundImage = NetworkImage(avatarUrl);
    } else if (avatarUrl != null && avatarUrl.isNotEmpty) {
      backgroundImage = AssetImage(avatarUrl);
    } else {
      backgroundImage = const AssetImage('assets/avatar.png');
    }

    return CircleAvatar(
      radius: 50,
      backgroundColor: Colors.grey[200],
      backgroundImage: backgroundImage,
      onBackgroundImageError:
          (avatarUrl != null && avatarUrl.startsWith('http'))
              ? (_, __) {
                debugPrint("Failed to load network image for avatar.");
              }
              : null,
    );
  }

  Widget _buildTabButton(bool isDarkMode, String label) {
    final isSelected = selectedTab == label;
    return ElevatedButton(
      onPressed: () {
        if (mounted) {
          setState(() {
            selectedTab = label;
          });
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isSelected
                ? AppBackgroundStyles.buttonBackground(isDarkMode)
                : AppBackgroundStyles.buttonBackgroundSecondary(isDarkMode),
        foregroundColor:
            isSelected
                ? AppTextStyles.buttonTextColor(isDarkMode)
                : Colors.grey[500],
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        minimumSize: const Size(150, 30),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: isSelected ? 4 : 0,
        shadowColor:
            isSelected ? Colors.black.withOpacity(0.5) : Colors.transparent,
      ),
      child: Text(label, style: const TextStyle(fontSize: 16)),
    );
  }
}

class SharedPost {
  final String sharedPostId;
  final String postId;
  final String originUserId;
  final String sharerUserId;
  final DateTime sharedAt;

  SharedPost({
    required this.sharedPostId,
    required this.postId,
    required this.originUserId,
    required this.sharerUserId,
    required this.sharedAt,
  });
}
