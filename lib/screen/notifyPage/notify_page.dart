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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  /// Xóa tất cả thông báo
  Future<void> deleteAllNotifications() async {
    try {
      final QuerySnapshot allNotifications =
          await FirebaseFirestore.instance
              .collection('notifications')
              .where('receiverId', isEqualTo: widget.currentUserId)
              .get();

      if (allNotifications.docs.isEmpty) {
        Get.snackbar(
          "Thông báo",
          "Không có thông báo nào để xóa",
          backgroundColor: Colors.orange.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        return;
      }

      final WriteBatch batch = FirebaseFirestore.instance.batch();

      for (QueryDocumentSnapshot doc in allNotifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      Get.snackbar(
        "Thành công",
        "Đã xóa tất cả ${allNotifications.docs.length} thông báo",
        backgroundColor: Colors.green.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      print("Lỗi xóa tất cả thông báo: $e");
      Get.snackbar(
        "Lỗi",
        "Không thể xóa tất cả thông báo: ${e.toString()}",
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  /// Đánh dấu đã đọc tất cả thông báo
  Future<void> markAllAsRead() async {
    try {
      final QuerySnapshot unreadNotifications =
          await FirebaseFirestore.instance
              .collection('notifications')
              .where('receiverId', isEqualTo: widget.currentUserId)
              .where('isRead', isEqualTo: false)
              .get();

      if (unreadNotifications.docs.isEmpty) {
        Get.snackbar(
          "Thông báo",
          "Không có thông báo chưa đọc nào",
          backgroundColor: Colors.orange.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        return;
      }

      final WriteBatch batch = FirebaseFirestore.instance.batch();

      for (QueryDocumentSnapshot doc in unreadNotifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();

      Get.snackbar(
        "Thành công",
        "Đã đánh dấu ${unreadNotifications.docs.length} thông báo là đã đọc",
        backgroundColor: Colors.green.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      print("Lỗi đánh dấu đã đọc tất cả: $e");
      Get.snackbar(
        "Lỗi",
        "Không thể đánh dấu tất cả thông báo: ${e.toString()}",
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

  /// Hiển thị dialog xác nhận xóa tất cả
  void showDeleteAllConfirmDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Xóa tất cả thông báo'),
        content: const Text(
          'Bạn có chắc chắn muốn xóa tất cả thông báo không? Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              Get.back(); // Đóng dialog trước
              await deleteAllNotifications(); // Thực hiện hành động
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa tất cả'),
          ),
        ],
      ),
    );
  }

  /// Hiển thị dialog xác nhận đánh dấu đã đọc tất cả
  void showMarkAllAsReadDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Đánh dấu đã đọc tất cả'),
        content: const Text(
          'Bạn có muốn đánh dấu tất cả thông báo là đã đọc không?',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              Get.back(); // Đóng dialog trước
              await markAllAsRead(); // Thực hiện hành động
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
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
            return false;
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              // Màu nền tương phản cao cho thông báo chưa đọc
              color:
                  isRead
                      ? Colors.transparent
                      : isDarkMode
                      ? Colors.blue.withOpacity(0.15)
                      : Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    isRead
                        ? Colors.transparent
                        : isDarkMode
                        ? Colors.blue.withOpacity(0.4)
                        : Colors.blue.withOpacity(0.3),
                width: isRead ? 0 : 1.5,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              onTap: () async {
                // Đánh dấu đã đọc
                if (!isRead) {
                  await FirebaseFirestore.instance
                      .collection('notifications')
                      .doc(item['docId'])
                      .update({'isRead': true});
                }

                // Xử lý navigation
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
                        viewPermission:
                            userData?['viewPermission'] ?? 'everyone',
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
                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  builder:
                      (context) => Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (!isRead)
                              ListTile(
                                leading: const Icon(
                                  Icons.mark_email_read,
                                  color: Colors.blue,
                                ),
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
                radius: 24,
                backgroundImage:
                    avatarUrl != null ? NetworkImage(avatarUrl) : null,
                backgroundColor: Colors.grey[300],
                child:
                    avatarUrl == null
                        ? const Icon(Icons.person, color: Colors.white)
                        : null,
              ),
              title: Text(
                senderName,
                style: TextStyle(
                  fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                  color:
                      isRead
                          ? AppTextStyles.normalTextColor(isDarkMode)
                          : isDarkMode
                          ? Colors.white
                          : Colors.black87,
                  fontSize: 16,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  message,
                  style: TextStyle(
                    color:
                        isRead
                            ? AppTextStyles.subTextColor(isDarkMode)
                            : isDarkMode
                            ? Colors.white70
                            : Colors.black54,
                    fontSize: 14,
                    fontWeight: isRead ? FontWeight.w400 : FontWeight.w500,
                  ),
                ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "${timestamp.day}/${timestamp.month}/${timestamp.year}",
                    style: TextStyle(
                      color: AppTextStyles.subTextColor(isDarkMode),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (!isRead)
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.5),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_off,
                  size: 64,
                  color: AppTextStyles.subTextColor(isDarkMode),
                ),
                const SizedBox(height: 16),
                Text(
                  'Chưa có thông báo',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppTextStyles.subTextColor(isDarkMode),
                  ),
                ),
              ],
            ),
          );
        }

        final filteredList = filterByType(snapshot.data!, typeFilter);

        if (filteredList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.filter_list_off,
                  size: 64,
                  color: AppTextStyles.subTextColor(isDarkMode),
                ),
                const SizedBox(height: 16),
                Text(
                  'Không có thông báo phù hợp',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppTextStyles.subTextColor(isDarkMode),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: filteredList.length,
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
              // Header với title và action buttons
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppBackgroundStyles.mainBackground(isDarkMode),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 48),
                        Text(
                          'Thông báo',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppTextStyles.normalTextColor(isDarkMode),
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert,
                            color: AppTextStyles.normalTextColor(isDarkMode),
                          ),
                          onSelected: (value) async {
                            if (value == 'mark_all_read') {
                              showMarkAllAsReadDialog();
                            } else if (value == 'delete_all') {
                              showDeleteAllConfirmDialog();
                            }
                          },
                          itemBuilder:
                              (BuildContext context) => [
                                const PopupMenuItem<String>(
                                  value: 'mark_all_read',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.mark_email_read,
                                        color: Colors.blue,
                                      ),
                                      SizedBox(width: 8),
                                      Text('Đánh dấu đã đọc tất cả'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem<String>(
                                  value: 'delete_all',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete_sweep,
                                        color: Colors.red,
                                      ),
                                      SizedBox(width: 8),
                                      Text('Xóa tất cả'),
                                    ],
                                  ),
                                ),
                              ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Tabs
                    Container(
                      height: 50,
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
                          borderRadius: BorderRadius.circular(25),
                        ),
                        labelStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                        tabs: const [
                          Tab(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text('Tất cả'),
                            ),
                          ),
                          Tab(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text('Theo dõi'),
                            ),
                          ),
                          Tab(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text('Yêu thích'),
                            ),
                          ),
                          Tab(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text('Bình luận'),
                            ),
                          ),
                          Tab(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text('Chia sẻ'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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
