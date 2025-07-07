import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:learnity/api/user_apis.dart';
import 'package:learnity/models/user_info_model.dart';
import 'package:learnity/screen/userPage/their_profile_page.dart';
import 'package:provider/provider.dart';
import 'package:learnity/theme/theme_provider.dart';
import 'package:learnity/theme/theme.dart';

import '../../models/post_model.dart';
import '../homePage/post_detail_page.dart';

class NotificationScreen extends StatefulWidget {
  final String currentUserId;
  const NotificationScreen({super.key, required this.currentUserId});

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    _tabController = TabController(length: 5, vsync: this);
    super.initState();
  }

  /// Lọc thông báo theo loại
  List<Map<String, dynamic>> filterByType(
    List<Map<String, dynamic>> list,
    String? type,
  ) {
    if (type == null) return list;
    return list.where((item) => item['type'] == type).toList();
  }

  /// Hiển thị từng item thông báo
  Widget buildNotificationItem(bool isDarkMode, Map<String, dynamic> item) {
    final senderName = item['senderName'] ?? 'Người dùng';
    final message = item['message'] ?? '';
    final timestamp = (item['timestamp'] as Timestamp).toDate();
    final senderId = item['senderId'];
    final isRead = item['isRead'] ?? false;

    return FutureBuilder<String?>(
      future: APIs.fetchSenderAvatar(senderId),
      builder: (context, snapshot) {
        final avatarUrl = snapshot.data;

        return ListTile(
          tileColor:
              isRead
                  ? AppBackgroundStyles.buttonBackgroundSecondary(isDarkMode)
                  : AppBackgroundStyles.buttonBackground(isDarkMode),
          onTap: () async {
            // Đánh dấu đã đọc
            await FirebaseFirestore.instance
                .collection('notifications')
                .doc(item['docId'])
                .update({'isRead': true});

            // Nếu là thông báo theo dõi => chuyển đến trang cá nhân người gửi
            if (item['type'] == 'follow') {
              try {
                final userDoc =
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(senderId)
                        .get();

                if (userDoc.exists) {
                  final userData = userDoc.data();

                  final user = UserInfoModel(
                    uid: senderId,
                    username: userData?['username'] ?? '',
                    displayName: userData?['displayName'] ?? '',
                    avatarUrl: userData?['avatarUrl'] ?? '',
                    followers: List<String>.from(userData?['followers'] ?? []),
                    viewPermission: userData?['viewPermission'] ?? 'everyone',
                  );

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TheirProfilePage(user: user),
                    ),
                  );
                } else {
                  Get.snackbar(
                    "Lỗi",
                    "Không tìm thấy người dùng",
                    backgroundColor: Colors.red.withOpacity(0.9),
                    colorText: Colors.white,
                    duration: const Duration(seconds: 4),
                  );
                }
              } catch (e) {
                Get.snackbar(
                  "Lỗi",
                  "Không thể chuyển đến trang cá nhân",
                  backgroundColor: Colors.red.withOpacity(0.9),
                  colorText: Colors.white,
                  duration: const Duration(seconds: 4),
                );
              }
            } else if (item['type'] == 'like' ||
                item['type'] == 'comment' ||
                item['type'] == 'share') {
              final String? postId = item['postId'];
              if (postId == null) {
                Get.snackbar("Lỗi", "Không tìm thấy thông tin bài viết.");
                return;
              }
              try {
                final postDoc =
                    await FirebaseFirestore.instance
                        .collection('posts')
                        .doc(postId)
                        .get();
                if (postDoc.exists) {
                  final post = PostModel.fromDocument(postDoc);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => PostDetailPage(
                            post: post,
                            isDarkMode: isDarkMode,
                          ),
                    ),
                  );
                } else {
                  Get.snackbar("Lỗi", "Bài viết này không còn tồn tại.");
                }
              } catch (e) {
                Get.snackbar("Lỗi", "Không thể mở bài viết.");
              }
            }
          },
          leading: CircleAvatar(
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            backgroundColor: Colors.black,
            child:
                avatarUrl == null
                    ? const Icon(Icons.person, color: Colors.white)
                    : null,
          ),
          title: Text(
            senderName,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTextStyles.normalTextColor(isDarkMode),
            ),
          ),
          subtitle: Text(
            message,
            style: TextStyle(color: AppTextStyles.normalTextColor(isDarkMode)),
          ),
          trailing: Text(
            "${timestamp.day}/${timestamp.month}/${timestamp.year}",
            style: TextStyle(
              color: AppTextStyles.subTextColor(isDarkMode),
              fontSize: 12,
            ),
          ),
        );
      },
    );
  }

  /// Nội dung của từng tab
  Widget buildTabContent(bool isDarkMode, String? typeFilter) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: APIs.getNotificationsStream(widget.currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Chưa có thông báo'));
        }

        final filteredList = filterByType(snapshot.data!, typeFilter);

        if (filteredList.isEmpty) {
          return Center(
            child: Text(
              'Không có thông báo phù hợp',
              style: TextStyle(color: AppTextStyles.subTextColor(isDarkMode)),
            ),
          );
        }

        return ListView.separated(
          itemCount: filteredList.length,
          separatorBuilder:
              (context, index) => const Divider(color: Colors.black),
          itemBuilder:
              (context, index) =>
                  buildNotificationItem(isDarkMode, filteredList[index]),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      body: Container(
        color: AppBackgroundStyles.mainBackground(isDarkMode),
        child: SafeArea(
          child: Column(
            children: [
              // 🔶 Nền bao quanh tiêu đề + tab
              Container(
                // margin: const EdgeInsets.symmetric(horizontal: 16),
                // padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                  color: AppBackgroundStyles.mainBackground(isDarkMode),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        'Thông báo',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppTextStyles.normalTextColor(isDarkMode),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        labelColor: AppTextStyles.buttonTextColor(isDarkMode),
                        unselectedLabelColor: AppTextStyles.subTextColor(
                          isDarkMode,
                        ),
                        indicator: BoxDecoration(
                          color: AppBackgroundStyles.buttonBackground(
                            isDarkMode,
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        labelStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        unselectedLabelStyle: const TextStyle(fontSize: 16),
                        tabs: const [
                          Tab(
                            child: Padding(
                              padding: EdgeInsets.all(8),
                              child: Text('Tất cả'),
                            ),
                          ),
                          Tab(
                            child: Padding(
                              padding: EdgeInsets.all(8),
                              child: Text('Theo dõi'),
                            ),
                          ),
                          Tab(
                            child: Padding(
                              padding: EdgeInsets.all(8),
                              child: Text('Yêu thích'),
                            ),
                          ),
                          Tab(
                            child: Padding(
                              padding: EdgeInsets.all(8),
                              child: Text('Bình luận'),
                            ),
                          ),
                          Tab(
                            child: Padding(
                              padding: EdgeInsets.all(8),
                              child: Text('Chia sẻ'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Nội dung tab
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    buildTabContent(isDarkMode, null), // Tất cả
                    buildTabContent(isDarkMode, 'follow'),
                    buildTabContent(isDarkMode, 'like'),
                    buildTabContent(isDarkMode, 'comment'),
                    buildTabContent(isDarkMode, 'share'),
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
