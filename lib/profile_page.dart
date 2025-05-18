import 'package:flutter/material.dart';
import 'package:learnity/theme/theme.dart';
import 'package:learnity/widgets/edit_profile-page.dart';
import 'models/post_model.dart';
import 'widgets/post_item.dart';
import 'models/user_info_model.dart';
import 'widgets/comment_thread.dart';
import 'widgets/shared_post_list.dart';

class ProfilePage extends StatefulWidget {
  final UserInfoModel user;

  const ProfilePage({super.key, required this.user});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String selectedTab = "Bài đăng";

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
                //logo + header
                Center(
                  child: Image.asset('assets/learnity.png', height: 110),
                ),
                const Text("Trang cá nhân", style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold)),
                const Divider(thickness: 1, color: Colors.black),

                //Info user (nickname - avatar)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.user.nickname ?? "Không có tên", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 30)),
                            Text(widget.user.fullName ?? "Không có tên", style: const TextStyle(fontSize: 20)),
                            const SizedBox(height: 10),
                            Text("${widget.user.followers} người theo dõi", style: const TextStyle(fontSize: 16, color: Colors.black54)),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const EditProfilePage()),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.buttonEditProfile,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                minimumSize: const Size(0, 36),
                              ),
                              child: const Text(
                                "Chỉnh sửa trang cá nhân",
                                style: TextStyle(fontSize: 16, color: AppColors.background),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          backgroundImage: AssetImage(widget.user.avatarPath ?? 'assets/avatar.png'),
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
                    _buildTabButton("Bình luận"),
                    _buildTabButton("Bài chia sẻ"),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(thickness: 1, color: Colors.black),

                if (selectedTab == "Bài đăng")
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 2,
                    itemBuilder: (context, index) => PostItem(
                      user: widget.user,
                      post: PostModel(
                        content:
                        "Biết điều tôn trọng người lớn đấy là kính lão đắc thọ\n"
                            "Đánh 83 mà nó ra 38 thì đấy là số mày max nhọ\n"
                            "Nhưng mà thôi không sao, tiền thì đã mất rồi\n"
                            "Không việc gì phải nhăn nhó\n"
                            "Nếu mà cảm thấy cuộc sống bế tắc hãy bốc cho mình một bát họ",
                        createdAt: DateTime.now(),
                      ),
                    ),
                  ),
                if (selectedTab == "Bình luận")
                  const CommentThread(),
                if (selectedTab == "Bài chia sẻ")
                  const SharedPostList(),
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
      child: Text(label, style: const TextStyle(fontSize: 16),),
    );
  }
}
