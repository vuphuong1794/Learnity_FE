import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/rendering.dart';
import 'package:learnity/models/user_info_model.dart';
import 'package:learnity/screen/createPostPage/post_upload_controller.dart';
import 'package:learnity/services/user_service.dart';
import 'package:learnity/viewmodels/social_feed_viewmodel.dart';
import 'package:learnity/models/post_model.dart';
import 'package:learnity/widgets/homePage/post_widget.dart';
import 'package:learnity/screen/createPostPage/create_post_page.dart';
import 'package:learnity/widgets/homePage/upload_progress.dart';

import '../../api/user_apis.dart';
import '../../widgets/handle_post_interaction.dart';
import '../chatPage/chat_page.dart';
import '../startPage/intro.dart';

import 'package:provider/provider.dart';
import 'package:learnity/theme/theme.dart';
import 'package:learnity/theme/theme_provider.dart';

class SocialFeedPage extends StatefulWidget {
  final void Function(bool)? onFooterVisibilityChanged;
  const SocialFeedPage({super.key, this.onFooterVisibilityChanged});

  @override
  State<SocialFeedPage> createState() => _SocialFeedPageState();
}

class _SocialFeedPageState extends State<SocialFeedPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  bool _lastShowFooter = true;
  late TabController _tabController;
  late SocialFeedViewModel _viewModel;
  bool _isLoading = false;
  late PostUploadController _uploadController;

  UserInfoModel currentUser = UserInfoModel(
    uid: '',
    username: '',
    displayName: '',
    avatarUrl: '',
  );

  UserInfoResult? userInfo;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _viewModel = SocialFeedViewModel();
    _uploadController = Get.put(PostUploadController());
    _refreshUserData();

    // Listen to upload success to refresh posts
    ever(_uploadController.uploadSuccess, (success) {
      if (success) {
        _refreshPosts();
      }
    });
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
              username: data['username'] ?? '',
              displayName: data['displayName'] ?? '',
              avatarUrl: data['avatarUrl'] ?? '',
              following: List<String>.from(data['following'] ?? []),
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

  // Phương thức để refresh posts
  Future<void> _refreshPosts() async {
    setState(() {
      // This will trigger a rebuild of the FutureBuilder
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void signOut() async {
    await FirebaseAuth.instance.signOut();
    Get.offAll(() => const IntroScreen());
  }

  void _notifyFooter(bool show) {
    if (_lastShowFooter != show) {
      _lastShowFooter = show;
      widget.onFooterVisibilityChanged?.call(show);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: AppBackgroundStyles.mainBackground(isDarkMode),
      appBar: AppBar(
        automaticallyImplyLeading:
            false, // Ngăn AppBar tự động hiển thị nút back khi có thể pop
        backgroundColor: AppBackgroundStyles.secondaryBackground(isDarkMode),
        elevation: 0,
        centerTitle: true,
        title: Image.asset('assets/learnity.png', height: 50),
        actions: [
          IconButton(
            icon: Icon(
              Icons.chat_bubble_outline,
              color: AppIconStyles.iconPrimary(isDarkMode),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ChatPage()),
              );
            },
          ),
        ],
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (scrollNotification) {
          if (scrollNotification is UserScrollNotification) {
            final direction = scrollNotification.direction;
            if (direction == ScrollDirection.forward) {
              _notifyFooter(true);
            } else if (direction == ScrollDirection.reverse) {
              _notifyFooter(false);
            }
          }
          return false;
        },
        child: Column(
          children: [
            UploadProgressWidget(),

            // Tab bar
            Container(
              color: AppBackgroundStyles.buttonBackground(
                isDarkMode,
              ), // Màu nền bạn muốn đặt
              child: TabBar(
                controller: _tabController,
                labelColor: AppTextStyles.buttonTextColor(isDarkMode),
                unselectedLabelColor: AppTextStyles.buttonTextColor(isDarkMode),
                indicatorColor: AppTextStyles.buttonTextColor(isDarkMode),
                labelStyle: TextStyle(
                  fontSize: 22, // Chữ khi được chọn
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: TextStyle(
                  fontSize: 20, // Chữ khi KHÔNG được chọn
                  fontWeight: FontWeight.normal,
                ),
                tabs: [
                  Tab(
                    child: Text(
                      'Dành cho bạn',
                      // style: AppTextStyles.subtitle2(isDarkMode),
                    ),
                  ),
                  Tab(
                    child: Text(
                      'Đang theo dõi',
                      // style: AppTextStyles.subtitle2(isDarkMode),
                    ),
                  ),
                ],
              ),
            ),

            // Tab bar view
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // For You tab
                  FutureBuilder<List<PostModel>>(
                    future: _viewModel.getPosts(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Lỗi khi tải bài viết',
                            style: AppTextStyles.error(isDarkMode),
                          ),
                        );
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Text(
                            'Không có bài viết nào',
                            style: AppTextStyles.body(isDarkMode),
                          ),
                        );
                      }

                      // Lọc bài viết không bị ẩn (isHidden != true)
                      final visiblePosts =
                          snapshot.data!
                              .where((post) => post.isHidden != true)
                              .toList();

                      return ListView.separated(
                        itemCount: visiblePosts.length + 1,
                        separatorBuilder:
                            (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const CreatePostPage(),
                                  ),
                                );
                              },
                              child: Container(
                                color: Colors.transparent,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundImage: NetworkImage(
                                        currentUser.avatarUrl?.isNotEmpty ==
                                                true
                                            ? currentUser.avatarUrl!
                                            : "https://example.com/default_avatar.png",
                                      ),
                                      radius: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          currentUser.displayName?.isNotEmpty ==
                                                  true
                                              ? currentUser.displayName!
                                              : 'Đang tải...',
                                          style: TextStyle(
                                            color:
                                                AppTextStyles.normalTextColor(
                                                  isDarkMode,
                                                ),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Hãy đăng một gì đó?',
                                          style: TextStyle(
                                            color:
                                                isDarkMode
                                                    ? AppColors.darkTextThird
                                                    : AppColors.textThird,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          final post = visiblePosts[index - 1];

                          return GestureDetector(
                            child: PostWidget(
                              post: post,
                              isDarkMode: isDarkMode,
                              onPostUpdated: () async {
                                final _ = await _viewModel.getPosts();
                                setState(() {});
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),

                  // Following tab
                  FutureBuilder<List<PostModel>>(
                    future: _viewModel.getFollowingPosts(
                      currentUser.following ?? [],
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Lỗi khi tải bài viết',
                            style: AppTextStyles.error(isDarkMode),
                          ),
                        );
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Text(
                            'Không có bài viết từ người bạn theo dõi',
                            style: AppTextStyles.body(isDarkMode),
                          ),
                        );
                      }

                      return ListView.separated(
                        itemCount: snapshot.data!.length,
                        separatorBuilder:
                            (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final post = snapshot.data![index];
                          return PostWidget(
                            post: post,
                            isDarkMode: isDarkMode,
                            onPostUpdated: () async {
                              final _ = await _viewModel.getFollowingPosts(
                                currentUser.following ?? [],
                              );
                              setState(() {});
                            },
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
