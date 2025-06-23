// import 'package:chat_app/group_chats/create_group/add_members.dart';
// import 'package:chat_app/group_chats/group_chat_room.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'group_chat_room.dart';
import 'group_chat_screen.dart';

import 'package:provider/provider.dart';
import 'package:learnity/theme/theme.dart';
import 'package:learnity/theme/theme_provider.dart';

class GroupChatHomePage extends StatefulWidget {
  const GroupChatHomePage({Key? key}) : super(key: key);

  @override
  _GroupChatHomePageState createState() => _GroupChatHomePageState();
}

class _GroupChatHomePageState extends State<GroupChatHomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isLoading = true;

  List groupList = [];

  @override
  void initState() {
    super.initState();
    getAvailableGroups();
  }

  void getAvailableGroups() async {
    String uid = _auth.currentUser!.uid;

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('groupChats')
        .get()
        .then((value) {
      setState(() {
        groupList = value.docs;
        isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppBackgroundStyles.mainBackground(isDarkMode),
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: AppIconStyles.iconPrimary(isDarkMode), // Đổi màu mũi tên tại đây
        ),
        backgroundColor: AppBackgroundStyles.secondaryBackground(isDarkMode),
        title: Text("Nhóm",style: TextStyle(color: AppTextStyles.normalTextColor(isDarkMode))),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(color: AppTextStyles.normalTextColor(isDarkMode).withOpacity(0.2), height: 1.0),
        ),
      ),
      body: isLoading
          ? Container(
              height: size.height,
              width: size.width,
              alignment: Alignment.center,
              child: CircularProgressIndicator(),
            )
          : ListView.builder(
              itemCount: groupList.length,
              itemBuilder: (context, index) {
                return ListTile(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      // builder: (_) => GroupChatRoom(
                      //   groupName: groupList[index]['groupChatName'],
                      //   groupChatId: groupList[index]['id'],
                      // ),
                      builder: (_) => GroupChatScreen(
                        groupName: groupList[index]['groupChatName'],
                        groupChatId: groupList[index]['id'],
                      ),
                    ),
                  ),
                  leading: Icon(Icons.group),
                  title: Text(groupList[index]['groupChatName'],style: TextStyle(color: AppTextStyles.normalTextColor(isDarkMode))),
                );
              },
            ),
    );
  }
}