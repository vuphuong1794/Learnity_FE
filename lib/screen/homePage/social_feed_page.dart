import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:learnity/theme/theme.dart';
import 'package:learnity/theme/theme_provider.dart';
import 'package:learnity/viewmodels/social_feed_viewmodel.dart';
import 'package:learnity/models/post_model.dart';
import 'package:learnity/widgets/post_widget.dart';
import 'package:learnity/screen/userpage/create_post_page.dart';

import '../chatPage/chatPage.dart';
import '../startScreen/intro.dart';

class SocialFeedPage extends StatefulWidget {
  final void Function(bool)? onFooterVisibilityChanged;
  const SocialFeedPage({super.key, this.onFooterVisibilityChanged});

  @override
  State<SocialFeedPage> createState() => _SocialFeedPageState();
}

class _SocialFeedPageState extends State<SocialFeedPage>
    with SingleTickerProviderStateMixin {
  final user = FirebaseAuth.instance.currentUser;
  bool _lastShowFooter = true;
  late TabController _tabController;
  late SocialFeedViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _viewModel = SocialFeedViewModel();
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
        backgroundColor: AppBackgroundStyles.mainBackground(isDarkMode),
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
              Navigator.push(context, MaterialPageRoute(builder: (_)=>ChatPage()));
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
            TabBar(
              controller: _tabController,
              labelColor: AppColors.textPrimary,
              unselectedLabelColor: AppColors.textThird,
              indicatorColor: AppColors.textPrimary,
              tabs: [
                Tab(
                  child: Text(
                    'Dành cho bạn',
                    style: AppTextStyles.subtitle2(isDarkMode),
                  ),
                ),
                Tab(
                  child: Text(
                    'Đang theo dõi',
                    style: AppTextStyles.subtitle2(isDarkMode),
                  ),
                ),
              ],
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
                      return ListView.separated(
                        itemCount: snapshot.data!.length + 1,
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
                                    const CircleAvatar(
                                      radius: 22,
                                      backgroundColor: Colors.grey,
                                      child: Icon(
                                        Icons.person,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user?.displayName ??
                                              user?.email?.split('@').first ??
                                              'User',
                                          style: TextStyle(
                                            color:
                                                isDarkMode
                                                    ? AppColors.darkTextPrimary
                                                    : AppColors.textPrimary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Có gì mới?',
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
                          final post = snapshot.data![index - 1];
                          return PostWidget(post: post, isDarkMode: isDarkMode);
                        },
                      );
                    },
                  ),
                  // Following tab
                  Center(
                    child: Text(
                      'Chưa có người theo dõi',
                      style: AppTextStyles.body(isDarkMode),
                    ),
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
