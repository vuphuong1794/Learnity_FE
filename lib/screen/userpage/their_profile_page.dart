import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:learnity/screen/userPage/profile_page.dart';
import 'package:learnity/api/Notification.dart';
import '../../models/post_model.dart';
import '../../viewmodels/social_feed_viewmodel.dart';
import '../../widgets/full_screen_image_page.dart';
import '../../widgets/post_item.dart';
import '../../models/user_info_model.dart';
import '../../widgets/homePage/post_widget.dart';
import 'comment_thread.dart';
import '../createPostPage/create_post_page.dart';
import 'shared_post_list.dart';

import 'package:provider/provider.dart';
import 'package:learnity/theme/theme.dart';
import 'package:learnity/theme/theme_provider.dart';

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

      final firestore = FirebaseFirestore.instance;

      // Xóa thông báo theo dõi cũ nếu đã tồn tại
      final notificationQuery =
          await firestore
              .collection('notifications')
              .where('type', isEqualTo: 'follow')
              .where('senderId', isEqualTo: currentUid)
              .where('receiverId', isEqualTo: widget.user.uid!)
              .get();

      for (final doc in notificationQuery.docs) {
        await doc.reference.delete();
      }

      //await _sendFollowNotification(senderName, widget.user.uid!);
      await Notification_API.sendFollowNotification(
        senderName,
        widget.user.uid!,
      );

      await Notification_API.saveFollowNotificationToFirestore(
        receiverId: widget.user.uid!,
        senderId: currentUid,
        senderName: senderName,
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
      backgroundColor: AppBackgroundStyles.mainBackground(isDarkMode),
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
                          // const SizedBox(height: 10),
                          // Image.asset('assets/learnity.png', height: 110),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              icon: Icon(
                                Icons.arrow_back,
                                size: 28,
                                color: AppTextStyles.buttonTextColor(
                                  isDarkMode,
                                ),
                              ),
                              onPressed: () {
                                Navigator.pop(context, true);
                              },
                            ),
                          ),
                          Text(
                            "Trang cá nhân",
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: AppTextStyles.normalTextColor(isDarkMode),
                            ),
                          ),
                          Divider(
                            thickness: 1,
                            color: AppTextStyles.normalTextColor(
                              isDarkMode,
                            ).withOpacity(0.2),
                          ),
                        ],
                      ),
                    ),
                    // Positioned(
                    //   top: 12,
                    //   left: 12,
                    //   child: IconButton(
                    //     icon: Icon(Icons.arrow_back, size: 30, color: AppTextStyles.buttonTextColor(isDarkMode)),
                    //     onPressed: () {
                    //       Navigator.pop(context, true);
                    //     },
                    //   ),
                    // ),
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
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 30,
                                      color: AppTextStyles.normalTextColor(
                                        isDarkMode,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    widget.user.username ?? "Không có tên",
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: AppTextStyles.normalTextColor(
                                        isDarkMode,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    "${widget.user.followers?.length ?? 0} người theo dõi",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: AppTextStyles.normalTextColor(
                                        isDarkMode,
                                      ),
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
                                      backgroundColor:
                                          isFollowing
                                              ? AppBackgroundStyles.buttonBackgroundSecondary(
                                                isDarkMode,
                                              )
                                              : AppBackgroundStyles.buttonBackground(
                                                isDarkMode,
                                              ),
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
                                        color:
                                            isFollowing
                                                ? AppTextStyles.subTextColor(
                                                  isDarkMode,
                                                )
                                                : AppTextStyles.buttonTextColor(
                                                  isDarkMode,
                                                ),
                                        fontSize: 15,
                                      ),

                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                // SizedBox(
                                //   width: 100,
                                //   child: ElevatedButton(
                                //     onPressed: _messageUser,
                                //     style: ElevatedButton.styleFrom(
                                //       backgroundColor:
                                //           AppBackgroundStyles.buttonBackground(
                                //             isDarkMode,
                                //           ),
                                //       shape: RoundedRectangleBorder(
                                //         borderRadius: BorderRadius.circular(20),
                                //       ),
                                //       padding: const EdgeInsets.symmetric(
                                //         horizontal: 16,
                                //         vertical: 4,
                                //       ),
                                //       minimumSize: const Size(0, 30),
                                //     ),
                                //     child: Text(
                                //       "Nhắn tin",
                                //       style: TextStyle(
                                //         color: AppTextStyles.buttonTextColor(
                                //           isDarkMode,
                                //         ),
                                //         fontSize: 15,
                                //       ),
                                //     ),
                                //   ),
                                // ),
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
                    _buildTabButton(isDarkMode, "Bài đăng"),
                    _buildTabButton(isDarkMode, "Bình luận"),
                    _buildTabButton(isDarkMode, "Bài chia sẻ"),
                  ],
                ),
                const SizedBox(height: 10),
                Divider(
                  thickness: 1,
                  color: AppTextStyles.normalTextColor(
                    isDarkMode,
                  ).withOpacity(0.2),
                ),
                // const SizedBox(height: 10),

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
                              color: AppTextStyles.normalTextColor(isDarkMode),
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
                        future: _viewModel.getUserPosts(
                          widget.user.uid!,
                        ), // Lấy bài của người đang xem
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
                          }

                          // Lọc các bài có isHidden != true (hiển thị)
                          final visiblePosts =
                              snapshot.data!
                                  .where((post) => post.isHidden != true)
                                  .toList();

                          if (visiblePosts.isEmpty) {
                            return Center(
                              child: Text(
                                'Không có bài viết nào đang hiển thị',
                                style: AppTextStyles.body(isDarkMode),
                              ),
                            );
                          }

                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: visiblePosts.length + 1,
                            separatorBuilder: (context, index) {
                              if (index == 0) return const SizedBox.shrink();
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
                                          if (value == true && mounted)
                                            setState(() {});
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

                              final post = visiblePosts[index - 1];
                              return PostWidget(
                                post: post,
                                isDarkMode: isDarkMode,
                              );
                            },
                          );
                        },
                      ),
                if (selectedTab == "Bình luận")
                  UserCommentList(userId: widget.user.uid!),
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

  Widget _buildTabButton(bool isDarkMode, String label) {
    final isSelected = selectedTab == label;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          selectedTab = label;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isSelected
                ? AppBackgroundStyles.buttonBackground(isDarkMode)
                : AppBackgroundStyles.buttonBackgroundSecondary(isDarkMode),
        foregroundColor:
            isSelected
                ? AppTextStyles.buttonTextColor(isDarkMode)
                : AppTextStyles.subTextColor(isDarkMode),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        minimumSize: const Size(0, 30),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: isSelected ? 4 : 0,
        shadowColor:
            isSelected ? Colors.black.withOpacity(0.5) : Colors.transparent,
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
