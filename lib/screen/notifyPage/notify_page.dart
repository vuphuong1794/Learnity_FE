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

  /// Xóa thông báo
  Future<void> deleteNotification(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(docId)
          .delete();

      Get.snackbar(
        "Thành công",
        "Đã xóa thông báo",
        backgroundColor: Colors.green.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        "Lỗi",
        "Không thể xóa thông báo",
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  /// Đánh dấu đã đọc tất cả thông báo
  Future<void> markAllAsRead() async {
    try {
      // Lấy tất cả thông báo chưa đọc của user hiện tại
      final QuerySnapshot unreadNotifications =
          await FirebaseFirestore.instance
              .collection('notifications')
              .where('recipientId', isEqualTo: widget.currentUserId)
              .where('isRead', isEqualTo: false)
              .get();

      // Tạo batch để update nhiều document cùng lúc
      final WriteBatch batch = FirebaseFirestore.instance.batch();

      for (QueryDocumentSnapshot doc in unreadNotifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();

      Get.snackbar(
        "Thành công",
        "Đã đánh dấu tất cả thông báo là đã đọc",
        backgroundColor: Colors.green.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        "Lỗi",
        "Không thể đánh dấu tất cả thông báo",
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  /// Hiển thị dialog xác nhận xóa
  void showDeleteConfirmDialog(String docId) {
    Get.dialog(
      AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa thông báo này không?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Hủy')),
          TextButton(
            onPressed: () {
              Get.back();
              deleteNotification(docId);
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// Hiển thị dialog xác nhận đánh dấu đã đọc tất cả
  void showMarkAllAsReadDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text(
          'Bạn có muốn đánh dấu tất cả thông báo là đã đọc không?',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Hủy')),
          TextButton(
            onPressed: () {
              Get.back();
              markAllAsRead();
            },
            child: const Text('Đồng ý'),
          ),
        ],
      ),
    );
  }

  /// Hiển thị từng item thông báo
  Widget buildNotificationItem(bool isDarkMode, Map<String, dynamic> item) {
    final senderName = item['senderName'] ?? 'Người dùng';
    final message = item['message'] ?? '';
    final timestamp = (item['timestamp'] as Timestamp).toDate();
    final senderId = item['senderId'];
    final isRead = item['isRead'] ?? false;
    final docId = item['docId'];

    return FutureBuilder<String?>(
      future: APIs.fetchSenderAvatar(senderId),
      builder: (context, snapshot) {
        final avatarUrl = snapshot.data;

        return Dismissible(
          key: Key(docId),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white, size: 30),
          ),
          confirmDismiss: (direction) async {
            showDeleteConfirmDialog(docId);
            return false; // Không tự động dismiss, chờ user xác nhận
          },
          child: ListTile(
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
                      followers: List<String>.from(
                        userData?['followers'] ?? [],
                      ),
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
            onLongPress: () {
              // Hiển thị menu context khi long press
              showModalBottomSheet(
                context: context,
                builder:
                    (context) => Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isRead)
                            ListTile(
                              leading: const Icon(Icons.mark_email_read),
                              title: const Text('Đánh dấu đã đọc'),
                              onTap: () async {
                                Navigator.pop(context);
                                await FirebaseFirestore.instance
                                    .collection('notifications')
                                    .doc(docId)
                                    .update({'isRead': true});
                              },
                            ),
                          ListTile(
                            leading: const Icon(
                              Icons.delete,
                              color: Colors.red,
                            ),
                            title: const Text(
                              'Xóa thông báo',
                              style: TextStyle(color: Colors.red),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              showDeleteConfirmDialog(docId);
                            },
                          ),
                        ],
                      ),
                    ),
              );
            },
            leading: CircleAvatar(
              backgroundImage:
                  avatarUrl != null ? NetworkImage(avatarUrl) : null,
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
              style: TextStyle(
                color: AppTextStyles.normalTextColor(isDarkMode),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "${timestamp.day}/${timestamp.month}/${timestamp.year}",
                  style: TextStyle(
                    color: AppTextStyles.subTextColor(isDarkMode),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                if (!isRead)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
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
              Container(
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 48), // Để cân bằng layout
                        Text(
                          'Thông báo',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppTextStyles.normalTextColor(isDarkMode),
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert,
                            color: AppTextStyles.normalTextColor(isDarkMode),
                          ),
                          onSelected: (value) {
                            if (value == 'mark_all_read') {
                              showMarkAllAsReadDialog();
                            }
                          },
                          itemBuilder:
                              (BuildContext context) => [
                                const PopupMenuItem<String>(
                                  value: 'mark_all_read',
                                  child: Row(
                                    children: [
                                      Icon(Icons.mark_email_read),
                                      SizedBox(width: 8),
                                      Text('Đánh dấu đã đọc tất cả'),
                                    ],
                                  ),
                                ),
                              ],
                        ),
                      ],
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
