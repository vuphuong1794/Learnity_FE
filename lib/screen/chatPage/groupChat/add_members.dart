import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:learnity/main.dart';
import 'package:learnity/widgets/chatPage/singleChatPage/profile_image.dart';
import 'package:provider/provider.dart';
import '../../../api/group_chat_api.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/theme.dart';
import 'group_chat_home_page.dart';

class AddMembersINGroup extends StatefulWidget {
  final String groupChatId, name;
  final List membersList;
  const AddMembersINGroup({
    required this.name,
    required this.membersList,
    required this.groupChatId,
    Key? key,
  }) : super(key: key);

  @override
  _AddMembersINGroupState createState() => _AddMembersINGroupState();
}

class _AddMembersINGroupState extends State<AddMembersINGroup> {
  final TextEditingController _search = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? userMap;
  bool isLoading = false;
  final TextEditingController searchController = TextEditingController();
  String searchText = '';

  List oldMembersListTemp = [];
  List oldMembersList = [];
  List<Map<String, dynamic>> membersList = [];
  List<Map<String, dynamic>> userList = [];

  @override
  void initState() {
    super.initState();
    onFirstSearch();
    oldMembersListTemp = widget.membersList;
    oldMembersList = widget.membersList;
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

  void addMembers() async {
    // Thêm từng member mới vào danh sách
    for (var newMember in membersList) {
      bool exists = oldMembersList.any((old) => old['uid'] == newMember['uid']);
      if (!exists) {
        oldMembersList.add(newMember);
      } else {
        return;
      }
    }

    // Cập nhật danh sách group trong nhóm
    await _firestore.collection('groupChats').doc(widget.groupChatId).update({
      "members": oldMembersList,
    });

    String groupId = widget.groupChatId;
    String members = "";
    // Thêm group cho từng người mới
    for (int i = 0; i < membersList.length; i++) {
      String uid = membersList[i]['uid'];

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('groupChats')
          .doc(groupId)
          .set({"name": widget.name, "id": widget.groupChatId});
      if (i != membersList.length - 1) {
        members += "${membersList[i]['username']},";
      } else {
        members += "${membersList[i]['username']}";
      }
    }

    // await _firestore.collection('groups').doc(groupId).collection('chats').add({
    //   "message": "${_auth.currentUser!.displayName} đã thêm $members vào nhóm",
    //   "type": "notify",
    //   "time": FieldValue.serverTimestamp(),
    // });
    GroupChatApi.sendGroupNotify(
      groupId,
      "${_auth.currentUser!.displayName} đã thêm $members vào nhóm",
    );

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => GroupChatHomePage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppBackgroundStyles.mainBackground(isDarkMode),
      appBar: AppBar(
        backgroundColor: AppBackgroundStyles.secondaryBackground(isDarkMode),
        foregroundColor: AppTextStyles.buttonTextColor(isDarkMode),
        title: Text("Thêm thành viên"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 👉 Danh sách thành viên đã chọn
          if (membersList.isNotEmpty) ...[
            Text(
              "Thành viên đã chọn:",
              style: TextStyle(
                color: AppTextStyles.normalTextColor(isDarkMode),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...membersList.map(
              (member) => ListTile(
                onTap: () => onRemoveMembers(membersList.indexOf(member)),
                leading: ProfileImage(
                  size: mq.height * .055,
                  url: member['avatarUrl'] ?? '',
                  isOnline: member['is_online'] ?? false,
                ),
                title: Text(
                  member['username'],
                  style: TextStyle(
                    color: AppTextStyles.normalTextColor(isDarkMode),
                  ),
                ),
                subtitle: Text(
                  member['email'],
                  style: TextStyle(
                    color: AppTextStyles.subTextColor(isDarkMode),
                  ),
                ),
                trailing: Icon(
                  Icons.close,
                  color: AppIconStyles.iconPrimary(isDarkMode),
                ),
              ),
            ),
            const Divider(),
          ],

          // 👉 Tìm kiếm
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppBackgroundStyles.buttonBackgroundSecondary(isDarkMode),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black87),
            ),
            child: TextField(
              style: TextStyle(
                color: AppTextStyles.normalTextColor(isDarkMode),
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
                fillColor: AppBackgroundStyles.buttonBackgroundSecondary(
                  isDarkMode,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 👉 Danh sách người dùng
          Text(
            "Danh sách người dùng:",
            style: TextStyle(
              color: AppTextStyles.normalTextColor(isDarkMode),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ..._filteredUserList().map(
            (user) => ListTile(
              onTap: () => _onUserTap(user),
              leading: ProfileImage(
                size: mq.height * .055,
                url: user['avatarUrl'] ?? '',
                isOnline: user['is_online'] ?? false,
              ),
              title: Text(
                user['username'] ?? '',
                style: TextStyle(
                  color: AppTextStyles.normalTextColor(isDarkMode),
                ),
              ),
              subtitle: Text(
                user['email'] ?? '',
                style: TextStyle(color: AppTextStyles.subTextColor(isDarkMode)),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton:
          membersList.length >= 1
              ? FloatingActionButton(
                backgroundColor: AppBackgroundStyles.buttonBackground(
                  isDarkMode,
                ),
                foregroundColor: AppTextStyles.normalTextColor(isDarkMode),
                child: Icon(Icons.forward),
                onPressed: addMembers,
              )
              : const SizedBox(),
    );
  }

  List<Map<String, dynamic>> _filteredUserList() {
    final lowerSearch = searchText.toLowerCase();

    return userList.where((user) {
      final uid = user['uid'];
      final username = (user['username'] ?? '').toLowerCase();

      final isAlreadyAdded = membersList.any((member) => member['uid'] == uid);

      final isMatched = lowerSearch.isEmpty || username.contains(lowerSearch);

      return !isAlreadyAdded && isMatched;
    }).toList();
  }

  void _onUserTap(Map<String, dynamic> user) {
    setState(() {
      membersList.add({
        "username": user['username'],
        "email": user['email'],
        "avatarUrl": user['avatarUrl'],
        "is_online": user['is_online'],
        "uid": user['uid'],
        "isAdmin": false,
      });
    });
  }

  void onRemoveMembers(int index) {
    // setState(() {
    //   membersList.removeAt(index);
    // });
    if (membersList[index]['uid'] != _auth.currentUser!.uid) {
      setState(() {
        membersList.removeAt(index);
      });
    }
  }
}
