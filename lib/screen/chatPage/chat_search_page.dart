// import 'package:chat_app/Authenticate/Methods.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/theme_provider.dart';
import '../../theme/theme.dart';
import 'chat_room.dart';

class ChatSearchPage extends StatefulWidget {
  @override
  _ChatSearchPageState createState() => _ChatSearchPageState();
}

class _ChatSearchPageState extends State<ChatSearchPage> with WidgetsBindingObserver {
  List<Map<String, dynamic>> userList = [];
  bool isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  TextEditingController searchController = TextEditingController();
  String searchText = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    onFirstSearch();
  }

  void onFirstSearch() async {
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

      setState(() {
        userList = filteredUsers;
      });
    } catch (e) {
      print('Error fetching users: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // void setStatus(String status) async {
  //   await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
  //     "status": status,
  //   });
  // }

  // @override
  // void didChangeAppLifecycleState(AppLifecycleState state) {
  //   if (state == AppLifecycleState.resumed) {
  //     // online
  //     setStatus("Online");
  //   } else {
  //     // offline
  //     setStatus("Offline");
  //   }
  // }

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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    searchController.dispose();
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
                    // IconButton(
                    //   icon: const Icon(Icons.search, color: Colors.black),
                    //   onPressed: () {
                    //     // TODO: Chức năng tìm kiếm
                    //   },
                    // ),
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
        child: SizedBox(
          height: size.height / 20,
          width: size.height / 20,
          child: const CircularProgressIndicator(),
        ),
      )
    : Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tiêu đề
            const Text(
              'Tìm kiếm',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),

            // Thanh tìm kiếm
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: searchController,
                onChanged: (value) {
                  setState(() {
                    searchText = value.toLowerCase();
                  });
                },
                decoration: const InputDecoration(
                  icon: Icon(Icons.search, color: Colors.black),
                  hintText: 'Tìm kiếm',
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Danh sách người dùng
            Expanded(
              child: Builder(
                builder: (context) {
                  final filteredList = searchText.isEmpty
                      ? userList
                      : userList.where((user) {
                          final username = user['username']?.toLowerCase() ?? '';
                          return username.contains(searchText);
                        }).toList();

                  return ListView.builder(
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final user = filteredList[index];
                      return ListTile(
                        onTap: () {
                          String roomId = chatRoomId(
                                    _auth.currentUser!.displayName!,
                                    user!['username']);
                          print("Current user: ${_auth.currentUser!.displayName}");
                          print("Target user: ${user!['username']}");
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ChatRoom(
                                chatRoomId: roomId,
                                userMap: user!,
                              ),
                            ),
                          );
                        },
                        leading: const Icon(Icons.account_box, color: Colors.black),
                        title: Text(
                          user['username'] ?? '',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(user['email'] ?? ''),
                      );
                    },
                  );
                },
              ),
            ),

          ],
        ),
      ),

    );
  }
}