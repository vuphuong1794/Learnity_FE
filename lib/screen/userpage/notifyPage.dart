import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:learnity/models/user_info_model.dart';
import 'package:learnity/screen/userpage/their_profile_page.dart';
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
  Widget buildNotificationItem(Map<String, dynamic> item) {
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
                  ? AppColors.background
                  : const Color.fromARGB(255, 232, 248, 237),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Người dùng không tồn tại')),
                  );
                }
              } catch (e) {
                print('Lỗi khi chuyển đến trang cá nhân: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Lỗi khi tải thông tin người dùng'),
                  ),
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
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(message),
          trailing: Text(
            "${timestamp.day}/${timestamp.month}/${timestamp.year}",
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        );
      },
    );
  }

  /// Nội dung của từng tab
  Widget buildTabContent(String? typeFilter) {
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
              (context, index) => buildNotificationItem(filteredList[index]),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFA0EACF),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              width: 120,
              height: 110,
              child: Image.asset('assets/learnity.png', fit: BoxFit.contain),
            ),
            const SizedBox(height: 5),
            const Text(
              'Thông báo',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.black,
                indicator: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
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
                  buildTabContent(null), // Tất cả
                  buildTabContent('follow'),
                  buildTabContent('like'),
                  buildTabContent('comment'),
                  buildTabContent('share'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
