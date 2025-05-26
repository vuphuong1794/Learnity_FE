import 'package:flutter/material.dart';
import 'package:learnity/screen/Group/Create_Group.dart';
import 'package:learnity/theme/theme.dart';

class GroupScreen extends StatefulWidget {
  const GroupScreen({super.key});

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget buildGroupCard({
    required String image,
    required String name,
    required String members,
    required String privacy,
    required VoidCallback onJoin,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 24, backgroundImage: AssetImage(image)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      members,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Text(
                privacy,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onJoin,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey, // xám nhạt
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Tham gia',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          'Nhóm',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 25,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateGroup()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey.shade400,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          indicatorColor: Colors.black,
          indicatorWeight: 2,
          tabs: const [Tab(text: 'Đã tham gia'), Tab(text: 'Chưa tham gia')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Đã tham gia
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white70,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 13),
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  color: Colors.transparent,
                  elevation: 0,
                  child: ListTile(
                    tileColor: Colors.transparent,
                    leading: const CircleAvatar(
                      backgroundImage: AssetImage('assets/group_avatar.png'),
                    ),
                    title: const Text('Đại số'),
                    subtitle: const Text('10 bài viết mới'),
                    trailing: IconButton(
                      icon: const Icon(Icons.exit_to_app),
                      onPressed: () {
                        // Rời nhóm
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  color: Colors.transparent,
                  elevation: 0,
                  child: ListTile(
                    tileColor: Colors.transparent,
                    leading: const CircleAvatar(
                      backgroundImage: AssetImage('assets/group_avatar.png'),
                    ),
                    title: const Text('Đại số'),
                    subtitle: const Text('10 bài viết mới'),
                    trailing: IconButton(
                      icon: const Icon(Icons.exit_to_app),
                      onPressed: () {
                        // Rời nhóm
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tab 2: Chưa tham gia (thiết kế lại)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white70,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 13),

                buildGroupCard(
                  image: 'assets/group_avatar.png',
                  name: 'Đại số',
                  members: '50k thành viên',
                  privacy: 'Công khai',
                  onJoin: () {
                    // Xử lý tham gia nhóm
                  },
                ),

                buildGroupCard(
                  image: 'assets/group_avatar.png',
                  name: 'Đại số',
                  members: '50k thành viên',
                  privacy: 'Riêng tư',
                  onJoin: () {
                    // Xử lý tham gia nhóm
                  },
                ),

                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    'Chưa có nhóm nào để hiển thị',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
