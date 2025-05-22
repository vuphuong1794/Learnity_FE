// import 'package:chat_app/Authenticate/Methods.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../theme/theme_provider.dart';
import '../../theme/theme.dart';
import 'chatSearchPage.dart';
import 'chatRoom.dart';
import '../../widgets/time_utils.dart';

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  List<Map<String, dynamic>> userList = [];
  bool isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addObserver(this);
    setStatus("Online");
    onSearch();
  }

  void setStatus(String status) async {
    await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
      "status": status,
      "updateStatusAt": FieldValue.serverTimestamp(),
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // online
      setStatus("Online");
    } else {
      // offline
      setStatus("Offline");
    }
  }

  String chatRoomId(String user1, String user2) {
    if (user1.isEmpty || user2.isEmpty) {
      throw ArgumentError('Username không được để trống');
    }

    String u1 = user1.toLowerCase();
    String u2 = user2.toLowerCase();

    if (u1.compareTo(u2) > 0) {
      return "$user2$user1";
    } else {
      return "$user1$user2";
    }
  }


  void onSearch() async {
    setState(() {
      isLoading = true;
    });

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      QuerySnapshot snapshot = await _firestore.collection('users').get();

      // Lọc bỏ tài khoản hiện tại
      List<Map<String, dynamic>> filteredUsers = snapshot.docs
          .where((doc) => doc.id != currentUser.uid)
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      // Sắp xếp trước khi setState
      List<Map<String, dynamic>> sortedUsers = getSortedUserListHorizontally(filteredUsers);

      setState(() {
        userList = sortedUsers;
      });
    } catch (e) {
      print('Error fetching users: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> getSortedUserListHorizontally(List<Map<String, dynamic>> users) {
    List<Map<String, dynamic>> online = [];
    List<Map<String, dynamic>> offline = [];

    for (var user in users) {
      if (user['status'] == 'Online') {
        online.add(user);
      } else {
        offline.add(user);
      }
    }

    int compareByUpdateTime(Map<String, dynamic> a, Map<String, dynamic> b) {
      Timestamp? aTime = a['updateStatusAt'] as Timestamp?;
      Timestamp? bTime = b['updateStatusAt'] as Timestamp?;

      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime); // Descending
    }

    online.sort(compareByUpdateTime);
    offline.sort(compareByUpdateTime);

    return [...online, ...offline];
  }

  Stream<List<Map<String, dynamic>>> getUserStream() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .where((doc) => doc.id != _auth.currentUser!.uid)
          .map((doc) => {
                ...doc.data() as Map<String, dynamic>,
                'uid': doc.id, // thêm uid nếu cần
              })
          .toList();
    });
  }


  Future<List<Map<String, dynamic>>> getSortedUserListVertically() async {
    List<Map<String, dynamic>> result = [];

    for (var user in userList) {
      String roomId = chatRoomId(
        _auth.currentUser!.displayName!,
        user['username'],
      );

      final snapshot = await _firestore
          .collection('chatroom')
          .doc(roomId)
          .collection('chats')
          .orderBy("time", descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final lastMessage = snapshot.docs.first.data();
        result.add({
          'user': user,
          'lastMessage': lastMessage['message'],
          'timestamp': lastMessage['time'], // cần parse thành DateTime nếu là String
        });
      }
    }

    // Sắp xếp theo thời gian giảm dần
    result.sort((a, b) {
      DateTime timeA;
      DateTime timeB;

      // Nếu dùng Firebase Timestamp
      if (a['timestamp'] is Timestamp) {
        timeA = (a['timestamp'] as Timestamp).toDate();
        timeB = (b['timestamp'] as Timestamp).toDate();
      }
      // Nếu là String dạng "May 21, 2025 at 11:15:12 AM UTC+7"
      else if (a['timestamp'] is String) {
        timeA = DateFormat("MMM d, y 'at' hh:mm:ss a 'UTC'Z").parse(a['timestamp']);
        timeB = DateFormat("MMM d, y 'at' hh:mm:ss a 'UTC'Z").parse(b['timestamp']);
      } else {
        timeA = DateTime.now(); // fallback
        timeB = DateTime.now();
      }

      return timeB.compareTo(timeA); // ✅ b mới hơn thì đứng trước
    });


    return result;
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
        backgroundColor: AppBackgroundStyles.mainBackground(isDarkMode),
        elevation: 0,
        toolbarHeight: 60,
        title: Stack(
          alignment: Alignment.center,
          children: [
            // Logo ở giữa
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/learnity.png',
                  height: 70,
                ),
              ],
            ),

            // Các icon hai bên
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Nút back
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),

                // Nút search và add
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.search, color: Colors.black),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => ChatSearchPage()));
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, color: Colors.black),
                      onPressed: () {
                        showDialog(
                          context: context,
                          barrierDismissible: true,
                          builder: (BuildContext context) {
                            return Dialog(
                              alignment: Alignment.topRight,
                              insetPadding: const EdgeInsets.only(top: 60, right: 12), // Dịch lên và vào sát phải
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Container(
                                width: 180, // Giảm độ rộng modal
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      dense: true,
                                      leading: const Icon(Icons.group_add),
                                      title: const Text('Tạo nhóm chat'),
                                      onTap: () {
                                        Navigator.pop(context);
                                        // TODO: Xử lý tạo nhóm
                                      },
                                    ),
                                    // ListTile(
                                    //   dense: true,
                                    //   leading: const Icon(Icons.person_add),
                                    //   title: const Text('Thêm bạn mới'),
                                    //   onTap: () {
                                    //     Navigator.pop(context);
                                    //     // TODO: Xử lý thêm bạn
                                    //   },
                                    // ),
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

      body: isLoading
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
          // Hàng ngang hiển thị avatar và tên
          Container(
            height: 110,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: getUserStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text("Không có người dùng nào.");
                }

                final sortedUserList = getSortedUserListHorizontally(snapshot.data!);

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: sortedUserList.length,
                  itemBuilder: (context, index) {
                    final user = sortedUserList[index];
                    return GestureDetector(
                      onTap: () {
                        String roomId = chatRoomId(
                          _auth.currentUser!.displayName!,
                          user['username'],
                        );
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ChatRoom(
                              chatRoomId: roomId,
                              userMap: user,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                const CircleAvatar(
                                  radius: 33,
                                  backgroundColor: Colors.black87,
                                  child: Icon(Icons.person, size: 40, color: Colors.white),
                                ),
                                if (user["status"] == "Online")
                                  Positioned(
                                    bottom: 1,
                                    right: 1,
                                    child: Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              (user['username'] != null && user['username'].length > 10)
                                  ? '${user['username'].substring(0, 7)}...'
                                  : user['username'] ?? '',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            )
          ),

          // Danh sách người dùng chiều dọc (giữ nguyên như bạn viết)
          
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: getSortedUserListVertically(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final sortedUsers = snapshot.data!;

                return ListView.builder(
                  itemCount: sortedUsers.length,
                  itemBuilder: (context, index) {
                    final user = sortedUsers[index]['user'];
                    final message = sortedUsers[index]['lastMessage'];
                    final time = sortedUsers[index]['timestamp'];

                    return ListTile(
                      onTap: () {
                        String roomId = chatRoomId(
                          _auth.currentUser!.displayName!,
                          user['username'],
                        );

                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ChatRoom(
                              chatRoomId: roomId,
                              userMap: user,
                            ),
                          ),
                        );
                      },
                      // leading: const CircleAvatar(
                      //   radius: 25,
                      //   backgroundColor: Colors.black87,
                      //   child: Icon(Icons.person, size: 35, color: Colors.white),
                      // ),
                      leading: Stack(
                          children: [
                            const CircleAvatar(
                              radius: 25,
                              backgroundColor: Colors.black87,
                              child: Icon(Icons.person, size: 35, color: Colors.white),
                            ),
                            if (user!["status"] == "Online")
                              Positioned(
                                bottom: 1,
                                right: 1,
                                child: Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      title: Text(user['username'] ?? '',
                        style: AppTextStyles.label(isDarkMode),
                      ),
                      subtitle: Row(
                        children: [
                          Flexible(
                            child: Text(
                              message ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.body(isDarkMode),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            formatTime((time as Timestamp).toDate()),
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

        ],
      ),

    );
  }
}