import 'package:flutter/material.dart';
import 'package:learnity/theme/theme.dart';
import 'package:learnity/screen/userpage/edit_profile-page.dart';
import '../../models/post_model.dart';
import '../../widgets/post_item.dart';
import '../../models/user_info_model.dart';
import 'comment_thread.dart';
import 'shared_post_list.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatefulWidget {
  final UserInfoModel user;

  const ProfilePage({super.key, required this.user});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String selectedTab = "Bài đăng";
  late UserInfoModel currentUser;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    currentUser = widget.user;
    _refreshUserData();
  }

  // Phương thức để refresh dữ liệu người dùng từ Firestore
  Future<void> _refreshUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (doc.exists && mounted) {
        final data = doc.data();
        if (data != null) {
          setState(() {
            // Cập nhật thông tin người dùng hiện tại
            currentUser = UserInfoModel(
              id: uid,
              username: data['username'],
              displayName: data['displayName'],
              avatarPath: data['avatarUrl'] ?? currentUser.avatarPath,
              bio: data['bio'] ?? currentUser.bio,
              followers: currentUser.followers,
            );
          });
        }
      }
    } catch (e) {
      debugPrint('Lỗi khi tải dữ liệu người dùng: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      children: [
                        // Nút quay lại
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back, size: 28),
                            onPressed: () {
                              Navigator.pop(context, true);
                            },
                          ),
                        ),

                        const Text(
                          "Trang cá nhân",
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(thickness: 1, color: Colors.black),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      currentUser.displayName ?? "Không có tên",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 30,
                                      ),
                                    ),
                                    Text(
                                      currentUser.bio ?? "chưa có thông tin gì",
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      "${currentUser.followers} người theo dõi",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ElevatedButton(
                                      onPressed: () async {
                                        // Điều hướng đến trang chỉnh sửa và đợi kết quả
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) => EditProfilePage(
                                                  currentUser: currentUser,
                                                ),
                                          ),
                                        );

                                        // Nếu có dữ liệu trả về hoặc đơn giản là đã quay lại
                                        // thì refresh lại dữ liệu người dùng
                                        if (result == true || result != null) {
                                          _refreshUserData();
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            AppColors.buttonEditProfile,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        minimumSize: const Size(0, 36),
                                      ),
                                      child: const Text(
                                        "Chỉnh sửa trang cá nhân",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: AppColors.background,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: _buildAvatar(currentUser.avatarPath),
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
                            itemBuilder:
                                (context, index) => PostItem(
                                  user: currentUser,
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
                        if (selectedTab == "Bình luận") const CommentThread(),
                        if (selectedTab == "Bài chia sẻ")
                          const SharedPostList(),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }

  Widget _buildAvatar(String? avatarPath) {
    if (avatarPath != null && avatarPath.startsWith('http')) {
      // Nếu là URL từ Cloudinary hoặc bất kỳ server nào
      return CircleAvatar(
        radius: 50,
        backgroundColor: Colors.white,
        backgroundImage: NetworkImage(avatarPath),
        onBackgroundImageError: (_, __) {
          // Nếu load ảnh bị lỗi thì có thể xử lý ở đây, ví dụ: setState để đổi sang ảnh mặc định
        },
      );
    } else {
      // Nếu là đường dẫn local hoặc null
      return CircleAvatar(
        radius: 50,
        backgroundColor: Colors.white,
        backgroundImage: AssetImage(avatarPath ?? 'assets/avatar.png'),
      );
    }
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
}
