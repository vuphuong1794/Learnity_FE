import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:learnity/main.dart';
import 'package:learnity/widgets/chatPage/singleChatPage/profile_image.dart';
import 'package:learnity/api/group_chat_api.dart';
import 'package:learnity/enum/message_type.dart';
import 'package:learnity/screen/chatPage/chat_page.dart';
import 'package:uuid/uuid.dart';
import 'group_chat_home_page.dart';

import 'package:provider/provider.dart';
import 'package:learnity/theme/theme.dart';
import 'package:learnity/theme/theme_provider.dart';

class AddMembersInGroup extends StatefulWidget {
  const AddMembersInGroup({super.key});

  @override
  State<AddMembersInGroup> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMembersInGroup> {
  bool isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _groupName = TextEditingController();

  final TextEditingController searchController = TextEditingController();
  String searchText = '';

  List<Map<String, dynamic>> membersList = [];
  List<Map<String, dynamic>> userList = [];

  @override
  void initState() {
    super.initState();
    onFirstSearch();
    getCurrentUserDetails();
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

  void getCurrentUserDetails() async {
    await _firestore.collection('users').doc(_auth.currentUser!.uid).get().then(
      (map) {
        setState(() {
          membersList.add({
            "username": map['username'],
            "avatarUrl": map['avatarUrl'],
            "is_online": map['is_online'],
            "email": map['email'],
            "uid": map['uid'],
            "isAdmin": true,
          });
        });
      },
    );
  }

  void createGroup() async {
    setState(() {
      isLoading = true;
    });

    String groupId = Uuid().v1();

    await _firestore.collection('groupChats').doc(groupId).set({
      "id": groupId,
      "name": _groupName.text,
      "members": membersList,
    });

    String members = "";

    for (int i = 0; i < membersList.length; i++) {
      String uid = membersList[i]['uid'];

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('groupChats')
          .doc(groupId)
          .set({"groupChatName": _groupName.text, "id": groupId});
      if (i != membersList.length - 1) {
        members += "${membersList[i]['username']}, ";
      } else {
        members += "${membersList[i]['username']}";
      }
    }

    GroupChatApi.sendGroupNotify(
      groupId,
      "${_auth.currentUser!.displayName} đã tạo nhóm",
    );
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
  void dispose() {
    searchController.dispose();
    super.dispose();
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
        iconTheme: IconThemeData(
          color: AppIconStyles.iconPrimary(
            isDarkMode,
          ), // Đổi màu mũi tên tại đây
        ),
        title: Text(
          "Tạo nhóm",
          style: TextStyle(color: AppTextStyles.normalTextColor(isDarkMode)),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(
            color: AppTextStyles.normalTextColor(isDarkMode).withOpacity(0.2),
            height: 1.0,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 👉 Nhập tên nhóm
          Text(
            "Tên nhóm:",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTextStyles.normalTextColor(isDarkMode),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _groupName,
            decoration: InputDecoration(
              hintText: "Nhập tên nhóm",
              hintStyle: TextStyle(
                color: AppTextStyles.normalTextColor(
                  isDarkMode,
                ), // 🎯 đổi màu hint text
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: AppBackgroundStyles.buttonBackgroundSecondary(
                isDarkMode,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 👉 Danh sách thành viên đã chọn
          if (membersList.isNotEmpty) ...[
            Text(
              "Thành viên đã chọn:",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTextStyles.normalTextColor(isDarkMode),
                fontSize: 18,
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
                    color: AppTextStyles.normalTextColor(isDarkMode),
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
              controller: searchController,
              onChanged: (value) {
                setState(() {
                  searchText = value.toLowerCase();
                });
              },
              style: TextStyle(
                color: AppTextStyles.normalTextColor(isDarkMode),
              ),
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.search,
                  color: AppIconStyles.iconPrimary(isDarkMode),
                  size: 20,
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
                isDense:
                    true, // Làm input gọn lại nhưng bạn tự kiểm soát padding
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                hintText: 'Tìm kiếm người dùng',
                hintStyle: TextStyle(
                  color: AppTextStyles.normalTextColor(isDarkMode),
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
              fontWeight: FontWeight.bold,
              color: AppTextStyles.normalTextColor(isDarkMode),
              fontSize: 18,
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
                style: TextStyle(
                  color: AppTextStyles.normalTextColor(isDarkMode),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton:
          membersList.length >= 3
              ? FloatingActionButton(
                backgroundColor: AppBackgroundStyles.buttonBackground(
                  isDarkMode,
                ),
                onPressed: createGroup,
                child: Icon(
                  Icons.forward,
                  color: AppIconStyles.iconPrimary(isDarkMode),
                ),
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
    if (membersList[index]['uid'] != _auth.currentUser!.uid) {
      setState(() {
        membersList.removeAt(index);
      });
    }
  }
}
