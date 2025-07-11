// import 'package:chat_app/Authenticate/Methods.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:learnity/models/app_user.dart';
import 'package:learnity/screen/chatPage/ai_chat_room.dart';
import 'package:learnity/screen/chatPage/chat_screen.dart';
import '../../api/user_apis.dart';
import '../../main.dart';
import '../../widgets/chatPage/singleChatPage/medium_profile_image.dart';
import '../../widgets/chatPage/singleChatPage/chat_user_card.dart';
import '../../widgets/chatPage/singleChatPage/profile_image.dart';
import 'chat_search_page.dart';
import '../../widgets/common/time_utils.dart';
import 'groupChat/create_group_chat.dart';
import 'groupChat/group_chat_home_page.dart';

import 'package:provider/provider.dart';
import 'package:learnity/theme/theme.dart';
import 'package:learnity/theme/theme_provider.dart';

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  List<Map<String, dynamic>> userList = [];
  bool isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // for storing all users
  List<AppUser> _horizontalList = [];
  List<AppUser> _list = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  // Hàm sắp xếp người dùng
  List<AppUser> _sortUsers(List<AppUser> users) {
    // Tách online/offline
    final onlineUsers = users.where((u) => u.isOnline).toList();
    final offlineUsers = users.where((u) => !u.isOnline).toList();

    // Sắp xếp theo thời gian hoạt động cuối (mới nhất lên đầu)
    onlineUsers.sort((a, b) => b.lastActive.compareTo(a.lastActive));
    offlineUsers.sort((a, b) => b.lastActive.compareTo(a.lastActive));

    return [...onlineUsers, ...offlineUsers];
  }

  // Hàm load người dùng
  Future<void> _loadUsers() async {
    if (isLoading) return;

    setState(() => isLoading = true);

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Lấy tất cả người dùng trừ bản thân
      final snapshot = await _firestore.collection('users').get();

      final allUsers =
          snapshot.docs
              .where((doc) => doc.id != currentUser.uid)
              .map(
                (doc) => AppUser.fromJson({
                  ...doc.data() as Map<String, dynamic>,
                  'uid': doc.id, // Đảm bảo có uid
                }),
              )
              .toList();

      // Lấy danh sách người dùng đã chat (cho danh sách dọc)
      final myUsersSnapshot =
          await _firestore
              .collection('users')
              .doc(currentUser.uid)
              .collection('my_users')
              .get();

      final myUserIds = myUsersSnapshot.docs.map((doc) => doc.id).toList();

      final myUsers = allUsers.where((u) => myUserIds.contains(u.id)).toList();

      setState(() {
        _horizontalList = _sortUsers(allUsers);
        _list = _sortUsers(myUsers);
      });
    } catch (e) {
      debugPrint('Error loading users: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Stream<List<AppUser>> getAllUsersStream() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .where((doc) => doc.id != _auth.currentUser!.uid)
          .map((doc) => AppUser.fromJson(doc.data()))
          .toList();
    });
  }

  List<AppUser> getSortedUserListHorizontally(List<AppUser> users) {
    List<AppUser> online = [];
    List<AppUser> offline = [];

    for (var user in users) {
      if (user.isOnline) {
        online.add(user);
      } else {
        offline.add(user);
      }
    }

    // Sắp xếp theo thời gian hoạt động cuối (mới nhất lên đầu)
    online.sort((a, b) => b.lastActive.compareTo(a.lastActive));
    offline.sort((a, b) => b.lastActive.compareTo(a.lastActive));

    return [...online, ...offline];
  }

  void _openChatRoom(AppUser user) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => ChatScreen(
              user: user, // Truyền đối tượng AppUser thay vì Map
            ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppBackgroundStyles.mainBackground(isDarkMode),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppBackgroundStyles.secondaryBackground(isDarkMode),
        elevation: 0,
        toolbarHeight: 60,
        title: Stack(
          alignment: Alignment.center,
          children: [
            // Logo ở giữa
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [Image.asset('assets/learnity.png', height: 40)],
            ),

            // Các icon hai bên
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Nút back
                IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: AppIconStyles.iconPrimary(isDarkMode),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),

                // Nút search và add
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.search,
                        color: AppIconStyles.iconPrimary(isDarkMode),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatSearchPage(),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.group,
                        color: AppIconStyles.iconPrimary(isDarkMode),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => GroupChatHomePage(),
                          ),
                        );
                      },
                    ),
                    // IconButton(
                    //   icon: Icon(Icons.add, color: AppIconStyles.iconPrimary(isDarkMode)),
                    //   onPressed: () {
                    //     showDialog(
                    //       context: context,
                    //       barrierDismissible: true,
                    //       builder: (BuildContext context) {
                    //         return Dialog(
                    //           alignment: Alignment.topRight,
                    //           insetPadding: const EdgeInsets.only(
                    //             top: 60,
                    //             right: 12,
                    //           ), // Dịch lên và vào sát phải
                    //           shape: RoundedRectangleBorder(
                    //             borderRadius: BorderRadius.circular(12),
                    //           ),
                    //           child: Container(
                    //             width: 180, // Giảm độ rộng modal
                    //             padding: const EdgeInsets.symmetric(
                    //               vertical: 8,
                    //             ),
                    //             decoration: BoxDecoration(
                    //               color: AppBackgroundStyles.modalBackground(isDarkMode),
                    //               borderRadius: BorderRadius.circular(12),
                    //             ),
                    //             child: Column(
                    //               mainAxisSize: MainAxisSize.min,
                    //               children: [
                    //                 ListTile(
                    //                   dense: true,
                    //                   leading: Icon(Icons.group_add, color: AppIconStyles.iconPrimary(isDarkMode)),
                    //                   title: Text('Tạo nhóm chat',style: TextStyle(color: AppTextStyles.buttonTextColor(isDarkMode))),
                    //                   onTap:
                    //                       () => {
                    //                         // Navigator.pop(context),
                    //                         Navigator.of(context).push(
                    //                           MaterialPageRoute(
                    //                             builder:
                    //                                 (_) => AddMembersInGroup(),
                    //                           ),
                    //                         ),
                    //                       },
                    //                 ),
                    //                 ListTile(
                    //                   dense: true,
                    //                   leading: Icon(Icons.group, color: AppIconStyles.iconPrimary(isDarkMode)),
                    //                   title: Text('Xem nhóm',style: TextStyle(color: AppTextStyles.buttonTextColor(isDarkMode))),
                    //                   onTap:
                    //                       () => {
                    //                         // Navigator.pop(context),
                    //                         Navigator.of(context).push(
                    //                           MaterialPageRoute(
                    //                             builder:
                    //                                 (_) =>
                    //                                     GroupChatHomePage(),
                    //                           ),
                    //                         ),
                    //                       },
                    //                 ),
                    //               ],
                    //             ),
                    //           ),
                    //         );
                    //       },
                    //     );
                    //   },
                    // ),
                  ],
                ),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(color: AppColors.black, height: 1.0),
        ),
      ),

      body:
          isLoading
              ? Center(
                child: Container(
                  height: size.height / 20,
                  width: size.height / 20,
                  child: const CircularProgressIndicator(),
                ),
              )
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // AI Chat Button
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AichatRoom()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue[400]!, Colors.blue[600]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.smart_toy,
                                size: 30,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Learnity AI',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Trợ lý ảo thông minh, sẵn sàng hỗ trợ bạn 24/7',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Hàng ngang hiển thị avatar và tên
                  Container(
                    height: 115,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: APIs.getMyUsersId(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                                ConnectionState.waiting ||
                            snapshot.connectionState == ConnectionState.none) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final docs = snapshot.data?.docs ?? [];
                        if (docs.isEmpty) {
                          return Text(
                            "Không có người dùng nào.",
                            style: TextStyle(
                              color: AppTextStyles.subTextColor(isDarkMode),
                            ),
                          );
                        }

                        final userIds = docs.map((e) => e.id).toList();

                        return StreamBuilder<
                          QuerySnapshot<Map<String, dynamic>>
                        >(
                          stream: APIs.getAllUsers(userIds),
                          builder: (context, userSnapshot) {
                            if (userSnapshot.connectionState ==
                                    ConnectionState.waiting ||
                                userSnapshot.connectionState ==
                                    ConnectionState.none) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            final userDocs = userSnapshot.data?.docs ?? [];
                            final users =
                                userDocs
                                    .map((e) => AppUser.fromJson(e.data()))
                                    .where((user) => user.role != 'admin')
                                    .toList();

                            final sortedUsers = getSortedUserListHorizontally(
                              users,
                            );

                            return ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: sortedUsers.length,
                              itemBuilder: (context, index) {
                                final user = sortedUsers[index];
                                return GestureDetector(
                                  onTap: () => _openChatRoom(user),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        MediumProfileImage(
                                          size: mq.height * .055,
                                          url: user.avatarUrl,
                                          isOnline: user.isOnline,
                                        ),
                                        const SizedBox(height: 6),
                                        SizedBox(
                                          width: 70,
                                          child: Text(
                                            user.name.length > 10
                                                ? '${user.name.substring(0, 7)}...'
                                                : user.name,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color:
                                                  AppTextStyles.normalTextColor(
                                                    isDarkMode,
                                                  ),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // Danh sách người dùng chiều dọc
                  Expanded(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: APIs.getMyUsersId(),
                      builder: (context, snapshot) {
                        switch (snapshot.connectionState) {
                          case ConnectionState.waiting:
                          case ConnectionState.none:
                            return const Center(
                              child: CircularProgressIndicator(),
                            );

                          case ConnectionState.active:
                          case ConnectionState.done:
                            final docs = snapshot.data?.docs ?? [];

                            docs.sort((a, b) {
                              final aTime = a.data()['lastMessageTime'];
                              final bTime = b.data()['lastMessageTime'];

                              final aParsed =
                                  aTime is int
                                      ? aTime
                                      : int.tryParse('$aTime') ?? 0;
                              final bParsed =
                                  bTime is int
                                      ? bTime
                                      : int.tryParse('$bTime') ?? 0;

                              return bParsed.compareTo(aParsed); // DESC
                            });

                            // Lấy danh sách userId sau khi sort
                            final sortedUserIds =
                                docs.map((e) => e.id).toList();

                            return StreamBuilder<
                              QuerySnapshot<Map<String, dynamic>>
                            >(
                              stream: APIs.getAllUsers(sortedUserIds),
                              builder: (context, snapshot) {
                                switch (snapshot.connectionState) {
                                  case ConnectionState.waiting:
                                  case ConnectionState.none:
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );

                                  case ConnectionState.active:
                                  case ConnectionState.done:
                                    final data = snapshot.data?.docs;
                                    _list =
                                        data
                                            ?.map(
                                              (e) => AppUser.fromJson(e.data()),
                                            )
                                            .where((user) => user.role != 'admin')
                                            .toList() ??
                                        [];

                                    // Sort lại _list theo sortedUserIds
                                    _list.sort(
                                      (a, b) => sortedUserIds
                                          .indexOf(a.id)
                                          .compareTo(
                                            sortedUserIds.indexOf(b.id),
                                          ),
                                    );

                                    if (_list.isNotEmpty) {
                                      return ListView.builder(
                                        itemCount: _list.length,
                                        padding: EdgeInsets.only(
                                          top: mq.height * .01,
                                        ),
                                        physics: const BouncingScrollPhysics(),
                                        itemBuilder: (context, index) {
                                          return ChatUserCard(
                                            user: _list[index],
                                          );
                                        },
                                      );
                                    } else {
                                      return Center(
                                        child: Text(
                                          'Bạn chưa có cuộc trò chuyện nào!',
                                          style: TextStyle(
                                            color: AppTextStyles.subTextColor(
                                              isDarkMode,
                                            ),
                                            fontSize: 20,
                                          ),
                                        ),
                                      );
                                    }
                                }
                              },
                            );
                        }
                      },
                    ),
                  ),
                ],
              ),
    );
  }
}
