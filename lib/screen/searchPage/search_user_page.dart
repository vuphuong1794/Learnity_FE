import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:learnity/api/Notification.dart';
import 'package:learnity/api/user_apis.dart';
import 'package:learnity/theme/theme.dart';
import '../../models/user_info_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../chatPage/chat_page.dart';
import '../userpage/their_profile_page.dart';

class SearchUserPage extends StatefulWidget {
  const SearchUserPage({super.key});

  @override
  State<SearchUserPage> createState() => _SearchUserPageState();
}

class _SearchUserPageState extends State<SearchUserPage> {
  List<UserInfoModel> displayedUsers = [];
  List<bool> isFollowingList = [];
  bool isLoading = false;
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  void _filterUsers(String query) {
    final filtered =
        displayedUsers.where((user) {
          if (user.uid == currentUserId) return false; // Bỏ qua chính mình
          final username = (user.username ?? '').toLowerCase();
          final displayName = (user.displayName ?? '').toLowerCase();
          return username.contains(query.toLowerCase()) ||
              displayName.contains(query.toLowerCase());
        }).toList();

    setState(() {
      displayedUsers = filtered;
      isFollowingList = List.generate(filtered.length, (index) => false);
    });
  }

  Future<void> fetchUsers() async {
    setState(() => isLoading = true);
    try {
      final FirebaseFirestore _firestore = FirebaseFirestore.instance;
      final snapshot = await _firestore.collection('users').get();
      final users =
          snapshot.docs
              .map((doc) {
                final data = doc.data();
                return UserInfoModel.fromMap(data, doc.id);
              })
              .where(
                (user) => user.uid != currentUserId,
              ) // Lọc bỏ user hiện tại
              .toList();

      setState(() {
        isLoading = false;
        displayedUsers = users;
        isFollowingList = List.generate(users.length, (index) => false);
      });
    } catch (e) {
      setState(() => isLoading = false);
      print('Lỗi khi tải danh sách người dùng: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải danh sách người dùng: $e')),
      );
    }
  }

  Future<void> _handleFollow(UserInfoModel user) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return;

    try {
      final isNowFollowing = !(user.followers?.contains(currentUid) ?? false);

      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      final currentUserRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUid);

      // Cập nhật lại UI
      setState(() {
        if (isNowFollowing) {
          user.followers ??= [];
          user.followers!.add(currentUid);
        } else {
          user.followers?.remove(currentUid);
        }
      });

      // Cập nhật followers và following
      await userRef.update({
        'followers':
            isNowFollowing
                ? FieldValue.arrayUnion([currentUid])
                : FieldValue.arrayRemove([currentUid]),
      });

      await currentUserRef.update({
        'following':
            isNowFollowing
                ? FieldValue.arrayUnion([user.uid])
                : FieldValue.arrayRemove([user.uid]),
      });

      if (isNowFollowing) {
        final senderSnapshot = await currentUserRef.get();
        final senderData = senderSnapshot.data();
        final senderName =
            senderData?['displayName'] ??
            senderData?['username'] ??
            'Người dùng';

        // Gửi notification push
        await Notification_API.sendFollowNotification(senderName, user.uid!);

        // Lưu notification vào Firestore
        await Notification_API.saveFollowNotificationToFirestore(
          receiverId: user.uid!,
          senderId: currentUid,
          senderName: senderName,
        );

        // Thêm user vào chat
        if (user.email != null && user.email!.isNotEmpty) {
          await APIs.addChatUser(user.email!);
        }
      }



      // Hiển thị thông báo thành công
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isNowFollowing
                ? 'Đã theo dõi ${user.displayName ?? user.username}'
                : 'Đã bỏ theo dõi ${user.displayName ?? user.username}',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Lỗi khi xử lý follow/unfollow: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi xử lý: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header với logo và nút chat
              Stack(
                alignment: Alignment.center,
                children: [
                  Center(
                    child: Image.asset('assets/learnity.png', height: 110),
                  ),
                  Positioned(
                    right: 5,
                    child: IconButton(
                      icon: const Icon(Icons.chat_bubble_outline, size: 30),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ChatPage()),
                        );
                      },
                    ),
                  ),
                ],
              ),

              // Tiêu đề
              const Text(
                "Tìm kiếm",
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),

              // Thanh tìm kiếm
              TextField(
                onChanged: _filterUsers,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Tìm kiếm theo tên hoặc username',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Danh sách người dùng
              Expanded(
                child:
                    isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : displayedUsers.isEmpty
                        ? const Center(
                          child: Text(
                            'Không tìm thấy người dùng nào',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        )
                        : RefreshIndicator(
                          onRefresh: fetchUsers,
                          child: ListView.builder(
                            itemCount: displayedUsers.length,
                            itemBuilder: (context, index) {
                              final user = displayedUsers[index];
                              final currentUser =
                                  FirebaseAuth.instance.currentUser;
                              final isFollowing =
                                  user.followers?.contains(currentUser?.uid) ??
                                  false;

                              return InkWell(
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              TheirProfilePage(user: user),
                                    ),
                                  );

                                  if (result == true) {
                                    setState(() {
                                      fetchUsers();
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    children: [
                                      // Avatar
                                      CircleAvatar(
                                        radius: 26,
                                        backgroundColor: Colors.grey.shade300,
                                        backgroundImage:
                                            (user.avatarUrl != null &&
                                                    user.avatarUrl!.isNotEmpty)
                                                ? NetworkImage(user.avatarUrl!)
                                                : null,
                                        child:
                                            (user.avatarUrl == null ||
                                                    user.avatarUrl!.isEmpty)
                                                ? const Icon(
                                                  Icons.person,
                                                  size: 30,
                                                )
                                                : null,
                                      ),
                                      const SizedBox(width: 12),

                                      // Thông tin user
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              user.displayName ??
                                                  'Không có tên',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '@${user.username ?? ''}',
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 14,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (user.followers != null &&
                                                user.followers!.isNotEmpty)
                                              Text(
                                                '${user.followers!.length} người theo dõi',
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),

                                      // Nút theo dõi
                                      SizedBox(
                                        width: 120,
                                        height: 36,
                                        child: ElevatedButton(
                                          onPressed: () => _handleFollow(user),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                isFollowing
                                                    ? Colors.grey.shade300
                                                    : Colors.black,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                            ),
                                          ),
                                          child: Text(
                                            isFollowing
                                                ? "Đang theo dõi"
                                                : "Theo dõi",
                                            style: TextStyle(
                                              color:
                                                  isFollowing
                                                      ? Colors.black
                                                      : Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
