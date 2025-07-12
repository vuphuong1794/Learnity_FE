import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/rendering.dart';
import 'package:learnity/models/user_info_model.dart';
import 'package:learnity/screen/createPostPage/post_upload_controller.dart';
import 'package:learnity/services/admin_service.dart';
import 'package:learnity/services/user_service.dart';
import 'package:learnity/viewmodels/social_feed_viewmodel.dart';
import 'package:learnity/models/post_model.dart';
import 'package:learnity/widgets/homePage/post_widget.dart';
import 'package:learnity/screen/createPostPage/create_post_page.dart';
import 'package:learnity/widgets/homePage/upload_progress.dart';
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

  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
    AnalyticsService.logVisitAndSave();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });

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

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  List<PostModel> _filterPosts(List<PostModel> posts) {
    if (_searchQuery.isEmpty) {
      return posts;
    }

    final lowerQuery = _searchQuery.toLowerCase();

    return posts.where((post) {
      final content = post.content?.toLowerCase() ?? '';
      final tags = post.tagList ?? [];

      final contentMatch = content.contains(lowerQuery);
      final tagMatch = tags.any((tag) => tag.toLowerCase().contains(lowerQuery));

      return contentMatch || tagMatch;
    }).toList();
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
        title:
            _isSearching
                ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm bài viết...',
                    hintStyle: TextStyle(
                      color: AppTextStyles.normalTextColor(isDarkMode),
                    ),
                    border: InputBorder.none,
                  ),
                  style: TextStyle(
                    color: AppTextStyles.normalTextColor(isDarkMode),
                    fontSize: 18,
                  ),
                )
                : Image.asset('assets/learnity.png', height: 50),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: AppIconStyles.iconPrimary(isDarkMode),
              size: 29,
            ),
            onPressed: _toggleSearch,
          ),
          if (!_isSearching)
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
            // Tab bar
            Container(
              color: AppBackgroundStyles.buttonBackground(isDarkMode),
              child: TabBar(
                controller: _tabController,
                labelColor: AppTextStyles.buttonTextColor(isDarkMode),
                unselectedLabelColor: AppTextStyles.buttonTextColor(isDarkMode),
                indicatorColor: AppTextStyles.buttonTextColor(isDarkMode),
                labelStyle: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: TextStyle(
                  fontSize: 20,
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

            UploadProgressWidget(),

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
                      final filteredPosts = _filterPosts(visiblePosts);
                      if (filteredPosts.isEmpty) {
                        return Center(
                          child: Text(
                            'Không tìm thấy bài viết nào',
                            style: AppTextStyles.body(isDarkMode),
                          ),
                        );
                      }
                      return ListView.separated(
                        itemCount:
                            _isSearching
                                ? filteredPosts.length
                                : filteredPosts.length + 1,
                        separatorBuilder:
                            (context, index) => Divider(height: 4, color: AppBackgroundStyles.mainBackground(isDarkMode)),
                        itemBuilder: (context, index) {
                          if (index == 0 && !_isSearching) {
                            return GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const CreatePostPage(),
                                  ),
                                );
                              },
                              child: Container(
                                color: AppBackgroundStyles.boxBackground(isDarkMode),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15), 
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppBackgroundStyles.buttonBackgroundSecondary(isDarkMode),
                                    borderRadius: BorderRadius.circular(12), // bo góc
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1), // màu bóng
                                        blurRadius: 6,
                                        offset: const Offset(0, 2), // hướng đổ bóng
                                      ),
                                    ],
                                  ),
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
                                            currentUser.username?.isNotEmpty ==
                                                    true
                                                ? currentUser.username!
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
                                              color: AppTextStyles.normalTextColor(isDarkMode).withOpacity(0.5),
                                              fontSize: 15,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Spacer(),
                                      Icon(Icons.photo_library, color: AppIconStyles.iconPrimary(isDarkMode)),
                                      const SizedBox(width: 15),
                                      Icon(Icons.camera_alt, color: AppIconStyles.iconPrimary(isDarkMode)),
                                    ],
                                  ),
                                ),
                              )
                            );
                          }

                          final postIndex = _isSearching ? index : index - 1;
                          if (postIndex < 0 ||
                              postIndex >= filteredPosts.length) {
                            return const SizedBox.shrink(); // Safety check
                          }
                          final post = filteredPosts[postIndex];

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
                      final filteredPosts = _filterPosts(snapshot.data!);
                      if (filteredPosts.isEmpty) {
                        return Center(
                          child: Text(
                            'Không tìm thấy bài viết nào',
                            style: AppTextStyles.body(isDarkMode),
                          ),
                        );
                      }
                      return ListView.separated(
                        itemCount: filteredPosts.length,
                        separatorBuilder:
                            (context, index) => Divider(height: 4, color: AppBackgroundStyles.mainBackground(isDarkMode)),
                        itemBuilder: (context, index) {
                          if (index == 0 && !_isSearching) {
                            return GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const CreatePostPage(),
                                  ),
                                );
                              },
                              child: Container(
                                color: AppBackgroundStyles.boxBackground(isDarkMode),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15), 
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppBackgroundStyles.buttonBackgroundSecondary(isDarkMode),
                                    borderRadius: BorderRadius.circular(12), // bo góc
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1), // màu bóng
                                        blurRadius: 6,
                                        offset: const Offset(0, 2), // hướng đổ bóng
                                      ),
                                    ],
                                  ),
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
                                            currentUser.username?.isNotEmpty ==
                                                    true
                                                ? currentUser.username!
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
                                              color: AppTextStyles.normalTextColor(isDarkMode).withOpacity(0.5),
                                              fontSize: 15,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Spacer(),
                                      Icon(Icons.photo_library, color: AppIconStyles.iconPrimary(isDarkMode)),
                                      const SizedBox(width: 15),
                                      Icon(Icons.camera_alt, color: AppIconStyles.iconPrimary(isDarkMode)),
                                    ],
                                  ),
                                ),
                              )
                            );
                          }
                          final post = filteredPosts[index];
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
