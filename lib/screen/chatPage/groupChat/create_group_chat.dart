import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../api/group_chat_api.dart';
import '../../../enum/message_type.dart';
import '../chat_page.dart';
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

  void getCurrentUserDetails() async {
    await _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .get()
        .then((map) {
      setState(() {
        membersList.add({
          "username": map['username'],
          "email": map['email'],
          "uid": map['uid'],
          "isAdmin": true,
        });
      });
    });
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
          .set({
            "groupChatName": _groupName.text,
            "id": groupId,
          });
      if (i != membersList.length-1) {
        members += "${membersList[i]['username']},";
      } else {
        members += "${membersList[i]['username']}";
      }
    }

    GroupChatApi.sendGroupNotify(groupId, "${_auth.currentUser!.displayName} đã tạo nhóm");
    GroupChatApi.sendGroupNotify(groupId, "${_auth.currentUser!.displayName} đã thêm $members vào nhóm");

    // await _firestore.collection('groupChats').doc(groupId).collection('messages').add({
    //   "msg": "${_auth.currentUser!.displayName} đã tạo nhóm",
    //   "toGroupId": groupId,
    //   "type": "notify",
    //   "sent": DateTime.now().millisecondsSinceEpoch.toString(),
    // });

    // await _firestore.collection('groupChats').doc(groupId).collection('messages').add({
    //   "msg": "${_auth.currentUser!.displayName} đã thêm $members vào nhóm",
    //   "toGroupId": groupId,
    //   "type": "notify",
    //   "sent": DateTime.now().millisecondsSinceEpoch.toString(),
    // });

    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => GroupChatHomePage()), (route) => false);
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
          color: AppIconStyles.iconPrimary(isDarkMode), // Đổi màu mũi tên tại đây
        ),
      title: Text("Tạo nhóm",style: TextStyle(color: AppTextStyles.normalTextColor(isDarkMode))),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(1.0),
        child: Container(color: AppTextStyles.normalTextColor(isDarkMode).withOpacity(0.2), height: 1.0),
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 👉 Nhập tên nhóm
        Text("Tên nhóm:", style: TextStyle(fontWeight: FontWeight.bold, color: AppTextStyles.normalTextColor(isDarkMode), fontSize: 18)),
        const SizedBox(height: 8),
        TextField(
          controller: _groupName,
          decoration: InputDecoration(
            hintText: "Nhập tên nhóm",
            hintStyle: TextStyle(
                    color: AppTextStyles.normalTextColor(isDarkMode),         // 🎯 đổi màu hint text
                  ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            filled: true,
            fillColor: AppBackgroundStyles.buttonBackgroundSecondary(isDarkMode),
          ),
        ),
        const SizedBox(height: 24),

        // 👉 Danh sách thành viên đã chọn
        if (membersList.isNotEmpty) ...[
          Text("Thành viên đã chọn:",
              style: TextStyle(fontWeight: FontWeight.bold, color: AppTextStyles.normalTextColor(isDarkMode), fontSize: 18)),
          const SizedBox(height: 8),
          ...membersList.map(
            (member) => ListTile(
              onTap: () => onRemoveMembers(membersList.indexOf(member)),
              leading: const Icon(Icons.account_circle, size: 35),
              title: Text(member['username'],style: TextStyle(color: AppTextStyles.normalTextColor(isDarkMode))),
              subtitle: Text(member['email'],style: TextStyle(color: AppTextStyles.normalTextColor(isDarkMode))),
              trailing: Icon(Icons.close, color: AppIconStyles.iconPrimary(isDarkMode)),
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
            style: TextStyle(color: AppTextStyles.normalTextColor(isDarkMode)),
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
              isDense: true, // Làm input gọn lại nhưng bạn tự kiểm soát padding
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              hintText: 'Tìm kiếm người dùng',
              hintStyle: TextStyle(
                color: AppTextStyles.normalTextColor(isDarkMode),
              ),
              border: InputBorder.none,
              filled: true,
              fillColor: AppBackgroundStyles.buttonBackgroundSecondary(isDarkMode),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 👉 Danh sách người dùng
        Text("Danh sách người dùng:",
            style: TextStyle(fontWeight: FontWeight.bold, color: AppTextStyles.normalTextColor(isDarkMode), fontSize: 18)),
        const SizedBox(height: 8),
        ..._filteredUserList().map((user) => ListTile(
              onTap: () => _onUserTap(user),
              leading: const Icon(Icons.account_circle, size: 35),
              title: Text(user['username'] ?? '',style: TextStyle(color: AppTextStyles.normalTextColor(isDarkMode))),
              subtitle: Text(user['email'] ?? '',style: TextStyle(color: AppTextStyles.normalTextColor(isDarkMode))),
            )),
      ],
    ),
    floatingActionButton: membersList.length >= 3
        ? FloatingActionButton(
            backgroundColor: AppBackgroundStyles.buttonBackground(isDarkMode),
            child: Icon(Icons.forward, color: AppIconStyles.iconPrimary(isDarkMode)),
            onPressed: createGroup,
          )
        : const SizedBox(),
  );
}


  List<Map<String, dynamic>> _filteredUserList() {
    if (searchText.isEmpty) return userList;
    return userList
        .where((user) =>
            (user['username'] ?? '').toLowerCase().contains(searchText))
        .toList();
  }

  void _onUserTap(Map<String, dynamic> user) {
    bool isAlreadyExist = false;

    for (int i = 0; i < membersList.length; i++) {
      if (membersList[i]['uid'] == user!['uid']) {
        isAlreadyExist = true;
      }
    }
    // bool isExist = membersList.any((m) => m['uid'] == user['uid']);
    if (!isAlreadyExist) {
      setState(() {
        membersList.add({
          "username": user['username'],
          "email": user['email'],
          "uid": user['uid'],
          "isAdmin": false,
        });
      });
    }
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