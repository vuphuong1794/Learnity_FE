// import 'package:chat_app/Authenticate/Methods.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:learnity/models/app_user.dart';
import 'package:learnity/screen/chatPage/ai_chat_room.dart';
import 'package:learnity/screen/chatPage/chat_screen.dart';
import 'package:provider/provider.dart';
import '../../api/user_apis.dart';
import '../../main.dart';
import '../../theme/theme_provider.dart';
import '../../theme/theme.dart';
import '../../widgets/medium_profile_image.dart';
import '../../widgets/chat_user_card.dart';
import '../../widgets/profile_image.dart';
import 'chat_search_page.dart';
import 'chat_room.dart';
import '../../widgets/time_utils.dart';
import 'groupChat/create_group_chat.dart';
import 'groupChat/group_chat_home_page.dart';

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
    WidgetsBinding.instance!.addObserver(this);
    // onSearch();
    _loadUsers();
  }

  // String chatRoomId(String user1, String user2) {
  //   if (user1.isEmpty || user2.isEmpty) {
  //     throw ArgumentError('Username không được để trống');
  //   }

  //   String u1 = user1.toLowerCase();
  //   String u2 = user2.toLowerCase();

  //   if (u1.compareTo(u2) > 0) {
  //     return "$user2$user1";
  //   } else {
  //     return "$user1$user2";
  //   }
  // }

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
      
      final allUsers = snapshot.docs
          .where((doc) => doc.id != currentUser.uid)
          .map((doc) => AppUser.fromJson({
            ...doc.data() as Map<String, dynamic>,
            'uid': doc.id, // Đảm bảo có uid
          }))
          .toList();

      // Lấy danh sách người dùng đã chat (cho danh sách dọc)
      final myUsersSnapshot = await _firestore
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
      // Có thể thêm thông báo lỗi cho người dùng ở đây
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

  // Future<List<Map<String, dynamic>>> getSortedUserListVertically() async {
  //   List<Map<String, dynamic>> result = [];

  //   for (var user in userList) {
  //     String roomId = chatRoomId(
  //       _auth.currentUser!.displayName!,
  //       user['username'],
  //     );

  //     final snapshot =
  //         await _firestore
  //             .collection('chatroom')
  //             .doc(roomId)
  //             .collection('chats')
  //             .orderBy("time", descending: true)
  //             .limit(1)
  //             .get();

  //     if (snapshot.docs.isNotEmpty) {
  //       final lastMessage = snapshot.docs.first.data();
  //       result.add({
  //         'user': user,
  //         'lastMessage': lastMessage['message'],
  //         'timestamp':
  //             lastMessage['time'], // cần parse thành DateTime nếu là String
  //       });
  //     }
  //   }

  //   // Sắp xếp theo thời gian giảm dần
  //   result.sort((a, b) {
  //     DateTime timeA;
  //     DateTime timeB;

  //     // Nếu dùng Firebase Timestamp
  //     if (a['timestamp'] is Timestamp) {
  //       timeA = (a['timestamp'] as Timestamp).toDate();
  //       timeB = (b['timestamp'] as Timestamp).toDate();
  //     }
  //     // Nếu là String dạng "May 21, 2025 at 11:15:12 AM UTC+7"
  //     else if (a['timestamp'] is String) {
  //       timeA = DateFormat(
  //         "MMM d, y 'at' hh:mm:ss a 'UTC'Z",
  //       ).parse(a['timestamp']);
  //       timeB = DateFormat(
  //         "MMM d, y 'at' hh:mm:ss a 'UTC'Z",
  //       ).parse(b['timestamp']);
  //     } else {
  //       timeA = DateTime.now(); // fallback
  //       timeB = DateTime.now();
  //     }

  //     return timeB.compareTo(timeA); // ✅ b mới hơn thì đứng trước
  //   });

  //   return result;
  // }

  void _openChatRoom(AppUser user) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          user: user, // Truyền đối tượng AppUser thay vì Map
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
                  icon: Icon(Icons.arrow_back, color: AppIconStyles.iconPrimary(isDarkMode)),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),

                // Nút search và add
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.search, color: AppIconStyles.iconPrimary(isDarkMode)),
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
                      icon: Icon(Icons.add, color: AppIconStyles.iconPrimary(isDarkMode)),
                      onPressed: () {
                        showDialog(
                          context: context,
                          barrierDismissible: true,
                          builder: (BuildContext context) {
                            return Dialog(
                              alignment: Alignment.topRight,
                              insetPadding: const EdgeInsets.only(
                                top: 60,
                                right: 12,
                              ), // Dịch lên và vào sát phải
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Container(
                                width: 180, // Giảm độ rộng modal
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppBackgroundStyles.modalBackground(isDarkMode), // ✅ Đổi ở đây theo ý bạn
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      dense: true,
                                      leading: Icon(Icons.group_add, color: AppIconStyles.iconPrimary(isDarkMode)),
                                      title: Text('Tạo nhóm chat',style: TextStyle(color: AppTextStyles.buttonTextColor(isDarkMode))),
                                      onTap:
                                          () => {
                                            // Navigator.pop(context),
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder:
                                                    (_) => AddMembersInGroup(),
                                              ),
                                            ),
                                          },
                                    ),
                                    ListTile(
                                      dense: true,
                                      leading: Icon(Icons.group, color: AppIconStyles.iconPrimary(isDarkMode)),
                                      title: Text('Xem nhóm',style: TextStyle(color: AppTextStyles.buttonTextColor(isDarkMode))),
                                      onTap:
                                          () => {
                                            // Navigator.pop(context),
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder:
                                                    (_) =>
                                                        GroupChatHomePage(),
                                              ),
                                            ),
                                          },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
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
                    height: 120,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: StreamBuilder<List<AppUser>>(
                      stream: getAllUsersStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Text("Không có người dùng nào.", style: TextStyle(color: AppTextStyles.subTextColor(isDarkMode)));
                        }

                        final sortedUserList = getSortedUserListHorizontally(
                          snapshot.data!,
                        );

                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: sortedUserList.length,
                          itemBuilder: (context, index) {
                            final user = sortedUserList[index];
                            return GestureDetector(
                              onTap: () => _openChatRoom(user),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                child: Column(
                                  children: [
                                    MediumProfileImage(size: mq.height * .055, url: user.avatarUrl, isOnline: user.isOnline),
                                    const SizedBox(height: 6),
                                    SizedBox(
                                      width: 70,
                                      child: Text(
                                        user.name.length > 10
                                            ? '${user.name.substring(0, 7)}...'
                                            : user.name,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppTextStyles.normalTextColor(isDarkMode)
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
                    ),
                  ),

                  // Danh sách người dùng chiều dọc
                  Expanded(
                    child: StreamBuilder(
                      stream: APIs.getMyUsersId(),

                      //get id of only known users
                      builder: (context, snapshot) {
                        switch (snapshot.connectionState) {
                          //if data is loading
                          case ConnectionState.waiting:
                          case ConnectionState.none:
                            return const Center(child: CircularProgressIndicator());

                          //if some or all data is loaded then show it
                          case ConnectionState.active:
                          case ConnectionState.done:
                            return StreamBuilder(
                              stream: APIs.getAllUsers(
                                  snapshot.data?.docs.map((e) => e.id).toList() ?? []),

                              //get only those user, who's ids are provided
                              builder: (context, snapshot) {
                                switch (snapshot.connectionState) {
                                  //if data is loading
                                  case ConnectionState.waiting:
                                  case ConnectionState.none:
                                  // return const Center(
                                  //     child: CircularProgressIndicator());

                                  //if some or all data is loaded then show it
                                  case ConnectionState.active:
                                  case ConnectionState.done:
                                    final data = snapshot.data?.docs;
                                    _list = data
                                            ?.map((e) => AppUser.fromJson(e.data()))
                                            .toList() ??
                                        [];

                                    if (_list.isNotEmpty) {
                                      return ListView.builder(
                                          itemCount: _list.length,
                                          padding: EdgeInsets.only(top: mq.height * .01),
                                          physics: const BouncingScrollPhysics(),
                                          itemBuilder: (context, index) {
                                            return ChatUserCard(
                                                user: _list[index]);
                                          });
                                    } else {
                                      return Center(
                                        child: Text('Bạn chưa có cuộc trò chuyện nào!',
                                            style: TextStyle(color: AppTextStyles.subTextColor(isDarkMode), fontSize: 20)),
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
