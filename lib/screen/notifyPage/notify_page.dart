import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:learnity/models/user_info_model.dart';
import 'package:learnity/screen/userPage/their_profile_page.dart';
import 'package:provider/provider.dart';
import 'package:learnity/theme/theme_provider.dart';
import 'package:learnity/theme/theme.dart';

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

  /// Lấy stream thông báo có kèm theo `docId` để cập nhật trạng thái đọc
  Stream<List<Map<String, dynamic>>> getNotificationsStream() {
    return FirebaseFirestore.instance
        .collection('notifications')
        .where('receiverId', isEqualTo: widget.currentUserId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => {...doc.data(), 'docId': doc.id})
                  .toList(),
        );
  }

  /// Lọc thông báo theo loại
  List<Map<String, dynamic>> filterByType(
    List<Map<String, dynamic>> list,
    String? type,
  ) {
    if (type == null) return list;
    return list.where((item) => item['type'] == type).toList();
  }

  /// Tải avatar từ người gửi
  Future<String?> fetchSenderAvatar(String senderId) async {
    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(senderId)
            .get();
    return userDoc.data()?['avatarUrl'];
  }

  /// Hiển thị từng item thông báo
  Widget buildNotificationItem(bool isDarkMode, Map<String, dynamic> item) {
    final senderName = item['senderName'] ?? 'Người dùng';
    final message = item['message'] ?? '';
    final timestamp = (item['timestamp'] as Timestamp).toDate();
    final senderId = item['senderId'];
    final isRead = item['isRead'] ?? false;

    return FutureBuilder<String?>(
      future: fetchSenderAvatar(senderId),
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
              color: AppTextStyles.normalTextColor(isDarkMode),
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
      stream: getNotificationsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Chưa có thông báo'));
        }

        final filteredList = filterByType(snapshot.data!, typeFilter);

        if (filteredList.isEmpty) {
          return const Center(child: Text('Không có thông báo phù hợp'));
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
      backgroundColor: AppBackgroundStyles.mainBackground(isDarkMode),
      body: SafeArea(
        child: Column(
          children: [
            // SizedBox(
            //   // width: 120,
            //   // height: 110,
            //   child: Image.asset('assets/learnity.png', height: 60),
            // ),
            // const SizedBox(height: 5),
            Text(
              'Thông báo',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: AppTextStyles.normalTextColor(isDarkMode),
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: AppTextStyles.buttonTextColor(isDarkMode),
                unselectedLabelColor: AppTextStyles.subTextColor(isDarkMode),
                indicator: BoxDecoration(
                  color: AppBackgroundStyles.buttonBackground(isDarkMode),
                  borderRadius: BorderRadius.circular(15),
                ),
                labelStyle: TextStyle(
                  fontSize: 18, // Chữ khi được chọn
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: TextStyle(
                  fontSize: 16, // Chữ khi KHÔNG được chọn
                  fontWeight: FontWeight.normal,
                ),
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
            const SizedBox(height: 8),
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
    );
  }
}
