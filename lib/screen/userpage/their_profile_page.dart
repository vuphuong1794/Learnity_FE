import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:learnity/theme/theme.dart';
import 'package:provider/provider.dart';
import '../../models/post_model.dart';
import '../../theme/theme_provider.dart';
import '../../viewmodels/social_feed_viewmodel.dart';
import '../../widgets/full_screen_image_page.dart';
import '../../widgets/post_item.dart';
import '../../models/user_info_model.dart';
import '../../widgets/post_widget.dart';
import 'comment_thread.dart';
import 'create_post_page.dart';
import 'shared_post_list.dart';

class TheirProfilePage extends StatefulWidget {
  final UserInfoModel user;

  const TheirProfilePage({super.key, required this.user});

  @override
  State<TheirProfilePage> createState() => _TheirProfilePageState();
}

class _TheirProfilePageState extends State<TheirProfilePage> {
  late SocialFeedViewModel _viewModel;
  String selectedTab = "Bài đăng";
  // bool isFollowing = false;
  // Getter để kiểm tra người dùng hiện tại có đang theo dõi người dùng của trang này không
  bool get isFollowing {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return false;
    // Kiểm tra xem UID của người dùng hiện tại có trong danh sách followers của widget.user không
    return widget.user.followers?.contains(currentUid) ?? false;
  }

  UserInfoModel currentUser = UserInfoModel(
    uid: '',
    username: '',
    displayName: '',
    avatarUrl: '',
  );
  @override
  void initState() {
    super.initState();
    currentUser = widget.user;
    _viewModel = SocialFeedViewModel();
  }

  Future<void> _handleFollow() async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return;

    final isNowFollowing =
        !(widget.user.followers?.contains(currentUid) ?? false);

    setState(() {
      if (isNowFollowing) {
        widget.user.followers ??= [];
        widget.user.followers!.add(currentUid);
      } else {
        widget.user.followers?.remove(currentUid);
      }
    });
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user.uid)
        .update({
          'followers':
              isNowFollowing
                  ? FieldValue.arrayUnion([currentUid])
                  : FieldValue.arrayRemove([currentUid]),
        });

    if (isNowFollowing) {
      final senderSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUid)
              .get();

      final senderData = senderSnapshot.data();
      final senderName =
          senderData?['displayName'] ?? senderData?['username'] ?? 'Người dùng';

      await _sendFollowNotification(senderName, widget.user.uid!);

      await _saveNotificationToFirestore(
        receiverId: widget.user.uid!,
        senderId: currentUid,
        senderName: senderName,
      );
    }
  }

  Future<void> _saveNotificationToFirestore({
    required String receiverId,
    required String senderId,
    required String senderName,
  }) async {
    final notificationData = {
      'receiverId': receiverId,
      'senderId': senderId,
      'senderName': senderName,
      'type': 'follow',
      'message': '$senderName vừa theo dõi bạn.',
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false, // tuỳ bạn xử lý đã đọc/chưa đọc
    };

    await FirebaseFirestore.instance
        .collection('notifications')
        .add(notificationData);
  }

  Future<void> _sendFollowNotification(
    String senderName,
    String receiverId,
  ) async {
    print('Gửi thông báo theo dõi từ $senderName đến $receiverId');

    // Lấy FCM token của người nhận
    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(receiverId)
            .get();
    final deviceId = userDoc.data()?['fcmTokens'];

    if (deviceId == null || deviceId.isEmpty) {
      print('FCM token của người nhận không tồn tại');
      return;
    }

    const apiUrl = 'http://192.168.100.9:3000/notification';

    final body = {
      'title': 'Bạn có người theo dõi mới!',
      'body': '$senderName vừa theo dõi bạn.',
      'deviceId': deviceId,
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        print('Gửi thông báo thất bại: ${response.body}');
      }
    } catch (e) {
      print('Lỗi khi gửi thông báo: $e');
    }
  }

  Future<void> saveFcmTokenToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'fcmTokens': token},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final String? profileOwnerViewPermission = widget.user.viewPermission;
    bool canViewPosts;
    String privacyMessage = '';
    final bool isOwnProfile =
        FirebaseAuth.instance.currentUser?.uid == widget.user.uid;

    if (isOwnProfile) {
      // Người dùng luôn có thể xem bài đăng của chính mình
      canViewPosts = true;
    } else if (profileOwnerViewPermission == 'myself') {
      canViewPosts = false;
      privacyMessage =
          '${widget.user.displayName ?? "Người dùng này"} đã đặt bài viết ở chế độ riêng tư.';
    } else if (profileOwnerViewPermission == 'followers') {
      canViewPosts = isFollowing;
      if (!canViewPosts) {
        privacyMessage =
            'Chỉ những người theo dõi mới có thể xem bài viết của ${widget.user.displayName ?? "người này"}.';
      }
    } else {
      // Mặc định là 'everyone' hoặc null (coi như công khai)
      canViewPosts = true;
    }

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
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                            ),
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
                          Navigator.pop(context, true);
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
                                  Text(
                                    widget.user.displayName ?? "Không có tên",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 30,
                                    ),
                                  ),
                                  Text(
                                    widget.user.username ?? "Không có tên",
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    "${widget.user.followers?.length ?? 0} người theo dõi",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                        ),
                      ),

                      // Avatar bên phải
                      Padding(
                        padding: const EdgeInsets.only(left: 15),
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => FullScreenImagePage(
                                          imageUrl: widget.user.avatarUrl ?? '',
                                        ),
                                  ),
                                );
                              },
                              child: CircleAvatar(
                                radius: 50,
                                backgroundImage:
                                    (widget.user.avatarUrl != null &&
                                            widget.user.avatarUrl!.isNotEmpty)
                                        ? NetworkImage(widget.user.avatarUrl!)
                                        : null,
                                child:
                                    (widget.user.avatarUrl == null ||
                                            widget.user.avatarUrl!.isEmpty)
                                        ? const Icon(Icons.person, size: 50)
                                        : null,
                              ),
                            ),
                            const SizedBox(height: 5),
                            // Nút Theo dõi và Nhắn tin
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 100,
                                  child: ElevatedButton(
                                    onPressed: _handleFollow,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.darkBackground,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),

                                      minimumSize: const Size(0, 30),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      isFollowing ? "Đã theo dõi" : "Theo dõi",
                                      style: TextStyle(
                                        color: AppColors.background,
                                        fontSize: 15,
                                      ),

                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 100,
                                  child: ElevatedButton(
                                    onPressed: _messageUser,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 4,
                                      ),
                                      minimumSize: const Size(0, 30),
                                    ),
                                    child: const Text(
                                      "Nhắn tin",
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
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
                const SizedBox(height: 10),

                // Nội dung theo tab
                if (selectedTab == "Bài đăng")
                  !canViewPosts
                      ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            privacyMessage,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color:
                                  isDarkMode
                                      ? AppColors.black
                                      : AppColors.buttonBg,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      )
                      :
                      // Kiểm tra widget.user.uid để lấy bài đăng của người đang xem
                      widget.user.uid == null || widget.user.uid!.isEmpty
                      ? Center(
                        child: Text(
                          'Không thể tải bài viết, thông tin người dùng không hợp lệ.',
                          style: AppTextStyles.body(isDarkMode),
                        ),
                      )
                      : FutureBuilder<List<PostModel>>(
                        future: _viewModel.getUserPosts(currentUser.uid),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          } else if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                'Lỗi khi tải bài viết: ${snapshot.error}',
                                style: AppTextStyles.error(isDarkMode),
                              ),
                            );
                          } else if (!snapshot.hasData ||
                              snapshot.data!.isEmpty) {
                            return Center(
                              child: Text(
                                'Bạn chưa có bài viết nào',
                                style: AppTextStyles.body(isDarkMode),
                              ),
                            );
                          }
                          // Phần ListView.separated giữ nguyên
                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: snapshot.data!.length + 1,
                            separatorBuilder: (context, index) {
                              if (index == 0 &&
                                  (snapshot.data == null ||
                                      snapshot.data!.isEmpty)) {
                                return const SizedBox.shrink();
                              }
                              if (index == 0) {
                                return const SizedBox.shrink();
                              }
                              return const Divider(height: 1);
                            },
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.of(context)
                                        .push(
                                          MaterialPageRoute(
                                            builder:
                                                (_) => const CreatePostPage(),
                                          ),
                                        )
                                        .then((value) {
                                          if (value == true) {
                                            if (mounted) {
                                              setState(() {});
                                            }
                                          }
                                        });
                                  },
                                  child: Container(
                                    color: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                );
                              }
                              final post = snapshot.data![index - 1];
                              return PostWidget(
                                post: post,
                                isDarkMode: isDarkMode,
                              );
                            },
                          );
                        },
                      ),
                if (selectedTab == "Bình luận") const CommentThread(),
                if (selectedTab == "Bài chia sẻ")
                  SizedBox(
                    height: 500, // hoặc dùng MediaQuery nếu cần linh hoạt
                    child: SharedPostList(sharerUid: widget.user.uid!),
                  ),
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

  // void _followUser() {
  //   setState(() {
  //     isFollowing = !isFollowing;
  //   });
  // }

  void _messageUser() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Mở giao diện nhắn tin")));
  }
}
