import 'package:flutter/material.dart';

class NotificationScreen extends StatefulWidget {
  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> notifications = [
    {
      'user': 'pink_everlasting',
      'date': '31/03/25',
      'action': 'Đã theo dõi bạn',
      'isFollowing': false,
    },
    {
      'user': 'pink_everlasting',
      'date': '31/03/25',
      'action': 'Đã thích bài viết của bạn',
    },
    {
      'user': 'pink_everlasting',
      'date': '31/03/25',
      'action': 'Đã chia sẻ bài viết bạn',
    },
    {
      'user': 'pink_everlasting',
      'date': '31/03/25',
      'action': 'Đã theo dõi bạn',
      'isFollowing': true,
    },
    {
      'user': 'pink_everlasting',
      'date': '31/03/25',
      'action': 'Đã bình luận vào bài viết của bạn',
    },
  ];

  List<Map<String, dynamic>> get followNotifications =>
      notifications.where((n) => n['action'] == 'Đã theo dõi bạn').toList();

  List<Map<String, dynamic>> get likeNotifications =>
      notifications
          .where((n) => n['action'] == 'Đã thích bài viết của bạn')
          .toList();

  List<Map<String, dynamic>> get commentNotifications =>
      notifications
          .where((n) => n['action'] == 'Đã bình luận vào bài viết của bạn')
          .toList();

  List<Map<String, dynamic>> get shareNotifications =>
      notifications
          .where((n) => n['action'] == 'Đã chia sẻ bài viết bạn')
          .toList();

  @override
  void initState() {
    _tabController = TabController(length: 5, vsync: this);
    super.initState();
  }

  Widget buildNotificationItem(Map<String, dynamic> item) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: const CircleAvatar(
        backgroundColor: Colors.black,
        child: Icon(Icons.person, color: Colors.white),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              item['user'],
              style: const TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            item['date'],
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
      subtitle: Text(item['action']),
      trailing:
          item['isFollowing'] != null
              ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item['isFollowing'] ? 'Đang theo dõi' : '+ Theo dõi',
                  style: const TextStyle(fontSize: 12),
                ),
              )
              : null,
    );
  }

  Widget buildNotificationList(List<Map<String, dynamic>> list) {
    return list.isNotEmpty
        ? ListView.separated(
          itemCount: list.length,
          separatorBuilder:
              (context, index) => const Divider(color: Colors.black),
          itemBuilder: (context, index) => buildNotificationItem(list[index]),
        )
        : const Center(child: Text('Chưa có thông báo'));
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
            // ✅ Scrollable TabBar to avoid overflow
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: TabBar(
                isScrollable: true,
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.black,
                indicator: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                ),
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                tabs: const [
                  Tab(text: 'Tất cả'),
                  Tab(text: 'Theo dõi'),
                  Tab(text: 'Yêu thích'),
                  Tab(text: 'Bình luận'),
                  Tab(text: 'Chia sẻ'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 0: Tất cả
                  buildNotificationList(notifications),
                  // Tab 1: Theo dõi
                  buildNotificationList(followNotifications),
                  // Tab 2: Yêu thích
                  buildNotificationList(likeNotifications),
                  // Tab 3: Bình luận
                  buildNotificationList(commentNotifications),
                  // Tab 4: Chia sẻ
                  buildNotificationList(shareNotifications),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
