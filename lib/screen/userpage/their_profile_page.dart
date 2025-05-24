import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:learnity/theme/theme.dart';
import '../../models/post_model.dart';
import '../../widgets/full_screen_image_page.dart';
import '../../widgets/post_item.dart';
import '../../models/user_info_model.dart';
import 'comment_thread.dart';
import 'shared_post_list.dart';

class TheirProfilePage extends StatefulWidget {
  final UserInfoModel user;

  const TheirProfilePage({super.key, required this.user});

  @override
  State<TheirProfilePage> createState() => _TheirProfilePageState();
}

class _TheirProfilePageState extends State<TheirProfilePage> {
  String selectedTab = "Bài đăng";
  // bool isFollowing = false;
  bool get isFollowing {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    return widget.user.followers?.contains(currentUid) ?? false;
  }

  Future<void> _handleFollow() async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return;

    final isNowFollowing =
        !(widget.user.followers?.contains(currentUid) ?? false);

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
    }

    setState(() {
      if (isNowFollowing) {
        widget.user.followers ??= [];
        widget.user.followers!.add(currentUid);
      } else {
        widget.user.followers?.remove(currentUid);
      }
    });
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

    const apiUrl = 'http://192.168.1.8:3000/notification';

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

                      // Avatar bên phải
                      // Padding(
                      //   padding: const EdgeInsets.only(left: 15),
                      //   child: CircleAvatar(
                      //     radius: 50,
                      //     backgroundColor: Colors.white,
                      //     backgroundImage: AssetImage(widget.user.avatarUrl ?? 'assets/avatar.png'),
                      //   ),
                      // ),
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
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 4,
                    itemBuilder:
                        (context, index) => PostItem(
                          user: widget.user,
                          post: PostModel(
                            content: "Nội dung bài đăng demo",
                            createdAt: DateTime.now(),
                          ),
                        ),
                  ),
                if (selectedTab == "Bình luận") const CommentThread(),
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
