import 'package:flutter/material.dart';
import 'package:learnity/theme/theme.dart';
import '../../models/post_model.dart';
import '../../widgets/post_item.dart';
import '../../models/user_info_model.dart';
import 'shared_post_list.dart';

class TheirProfilePage extends StatefulWidget {
  final UserInfoModel user;

  const TheirProfilePage({super.key, required this.user});

  @override
  State<TheirProfilePage> createState() => _TheirProfilePageState();
}

class _TheirProfilePageState extends State<TheirProfilePage> {
  String selectedTab = "Bài đăng";
  bool isFollowing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                // Logo + tiêu đề
                Stack(
                  children: [
                    Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          Image.asset('assets/learnity.png', height: 110),
                          const Text(
                            "Trang cá nhân",
                            style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold),
                          ),
                          const Divider(thickness: 1, color: Colors.black),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, size: 30),
                        onPressed: () {
                          // Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ),
                // Thông tin người dùng + nút + avatar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Bên trái: thông tin + 2 nút
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Thông tin cá nhân
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(widget.user.nickname ?? "Không có tên",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold, fontSize: 30)),
                                  Text(widget.user.fullName ?? "Không có tên",
                                      style: const TextStyle(fontSize: 20)),
                                  const SizedBox(height: 10),
                                  Text("${widget.user.followers} người theo dõi",
                                      style: const TextStyle(
                                          fontSize: 16, color: Colors.black54)),
                                ],
                              ),
                            ),

                            const SizedBox(width: 12),

                            // Nút Theo dõi và Nhắn tin
                            Column(
                              children: [
                                SizedBox(
                                  width: 100,
                                  child: ElevatedButton(
                                    onPressed: _followUser,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.darkBackground,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                      minimumSize: const Size(0, 36),
                                    ),
                                    child: Text(
                                      isFollowing ? "Đã theo dõi" : "Theo dõi",
                                      style: TextStyle(color: AppColors.background, fontSize: 15),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: _messageUser,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20)),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                    minimumSize: const Size(0, 36),
                                  ),
                                  child: const Text("Nhắn tin", style: TextStyle(color: Colors.black, fontSize: 15)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Avatar bên phải
                      Padding(
                        padding: const EdgeInsets.only(left: 15),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          backgroundImage: AssetImage(widget.user.avatarUrl ?? 'assets/avatar.png'),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Tabs
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTabButton("Bài đăng"),
                    _buildTabButton("Bài chia sẻ"),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(thickness: 1, color: Colors.black),
                const SizedBox(height: 10),

                // Nội dung theo tab
                if (selectedTab == "Bài đăng")
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 4,
                    itemBuilder: (context, index) => PostItem(
                      user: widget.user,
                      post: PostModel(
                        content: "Nội dung bài đăng demo",
                        createdAt: DateTime.now(),
                      ),
                    ),
                  ),
                if (selectedTab == "Bài chia sẻ") const SharedPostList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(String label) {
    final isSelected = selectedTab == label;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          selectedTab = label;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? AppColors.buttonEditProfile : Colors.grey,
        foregroundColor: isSelected ? AppColors.background : Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        minimumSize: const Size(0, 30),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 16)),
    );
  }

  void _followUser() {
    setState(() {
      isFollowing = !isFollowing;
    });
  }

  void _messageUser() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Mở giao diện nhắn tin")),
    );
  }
}
