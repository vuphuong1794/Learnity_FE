// import 'package:chat_app/Authenticate/Methods.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:learnity/api/user_apis.dart';
import 'package:learnity/main.dart';
import 'package:learnity/models/app_user.dart';
import 'package:learnity/screen/chatPage/chat_screen.dart';
import 'package:learnity/screen/chatPage/groupChat/create_group_chat.dart';
import 'package:learnity/screen/chatPage/groupChat/group_chat_home_page.dart';
import 'package:learnity/widgets/chatPage/singleChatPage/chat_user_card.dart';
import 'package:provider/provider.dart';
import '../../theme/theme_provider.dart';
import '../../theme/theme.dart';

class ChatSearchPage extends StatefulWidget {
  @override
  _ChatSearchPageState createState() => _ChatSearchPageState();
}

class _ChatSearchPageState extends State<ChatSearchPage>
    with WidgetsBindingObserver {
  List<Map<String, dynamic>> userList = [];
  bool isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<AppUser> _list = [];

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
      List<Map<String, dynamic>> filteredUsers =
          snapshot.docs
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
        backgroundColor: AppBackgroundStyles.secondaryBackground(isDarkMode),
        elevation: 0,
        toolbarHeight: 60,
        title: Stack(
          alignment: Alignment.center,
          children: [
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
                        Icons.add,
                        color: AppIconStyles.iconPrimary(isDarkMode),
                      ),
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
                                  color: AppBackgroundStyles.modalBackground(
                                    isDarkMode,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      dense: true,
                                      leading: Icon(
                                        Icons.group_add,
                                        color: AppIconStyles.iconPrimary(
                                          isDarkMode,
                                        ),
                                      ),
                                      title: Text(
                                        'Tạo nhóm chat',
                                        style: TextStyle(
                                          color: AppTextStyles.buttonTextColor(
                                            isDarkMode,
                                          ),
                                        ),
                                      ),
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
                                      leading: Icon(
                                        Icons.group,
                                        color: AppIconStyles.iconPrimary(
                                          isDarkMode,
                                        ),
                                      ),
                                      title: Text(
                                        'Xem nhóm',
                                        style: TextStyle(
                                          color: AppTextStyles.buttonTextColor(
                                            isDarkMode,
                                          ),
                                        ),
                                      ),
                                      onTap:
                                          () => {
                                            // Navigator.pop(context),
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder:
                                                    (_) => GroupChatHomePage(),
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
          child: Container(
            color: AppTextStyles.normalTextColor(isDarkMode).withOpacity(0.2),
            height: 1.0,
          ),
        ),
      ),

      body:
          isLoading
              ? Center(
                child: SizedBox(
                  height: size.height / 20,
                  width: size.height / 20,
                  child: const CircularProgressIndicator(),
                ),
              )
              : Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 0,
                  vertical: 12.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tiêu đề
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color:
                                  AppBackgroundStyles.buttonBackgroundSecondary(
                                    isDarkMode,
                                  ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              style: TextStyle(
                                color: AppTextStyles.normalTextColor(
                                  isDarkMode,
                                ),
                              ),
                              controller: searchController,
                              onChanged: (value) {
                                setState(() {
                                  searchText = value.toLowerCase();
                                });
                              },
                              decoration: InputDecoration(
                                icon: Icon(
                                  Icons.search,
                                  color: AppIconStyles.iconPrimary(isDarkMode),
                                ),
                                hintText: 'Tìm kiếm người dùng',
                                hintStyle: TextStyle(
                                  color: AppTextStyles.normalTextColor(
                                    isDarkMode,
                                  ).withOpacity(0.5),
                                ),
                                border: InputBorder.none,
                                filled: true,
                                fillColor:
                                    AppBackgroundStyles.buttonBackgroundSecondary(
                                      isDarkMode,
                                    ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Danh sách người dùng
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
                                                (e) =>
                                                    AppUser.fromJson(e.data()),
                                              )
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

                                      final filteredList =
                                          searchText.isEmpty
                                              ? _list
                                              : _list
                                                  .where(
                                                    (user) => user.name
                                                        .toLowerCase()
                                                        .contains(searchText),
                                                  )
                                                  .toList();

                                      if (filteredList.isNotEmpty) {
                                        return ListView.builder(
                                          itemCount: filteredList.length,
                                          padding: EdgeInsets.only(
                                            top: mq.height * .01,
                                          ),
                                          physics:
                                              const BouncingScrollPhysics(),
                                          itemBuilder: (context, index) {
                                            return ChatUserCard(
                                              user: filteredList[index],
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
              ),
    );
  }
}
