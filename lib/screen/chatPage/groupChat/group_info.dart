import 'package:learnity/main.dart';
import 'package:learnity/widgets/chatPage/singleChatPage/profile_image.dart';

import '../../../api/group_chat_api.dart';
import '../chat_page.dart';
// import 'package:chat_app/group_chats/add_members.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/theme.dart';
import 'add_members.dart';

class GroupInfo extends StatefulWidget {
  final String groupId, groupName;
  const GroupInfo({required this.groupId, required this.groupName, Key? key})
    : super(key: key);

  @override
  State<GroupInfo> createState() => _GroupInfoState();
}

class _GroupInfoState extends State<GroupInfo> {
  List membersList = [];
  bool isLoading = true;

  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();

    getGroupDetails();
  }

  Future getGroupDetails() async {
    await _firestore.collection('groupChats').doc(widget.groupId).get().then((
      chatMap,
    ) {
      membersList = chatMap['members'];
      print(membersList);
      isLoading = false;
      setState(() {});
    });
  }

  bool checkAdmin() {
    bool isAdmin = false;

    membersList.forEach((element) {
      if (element['uid'] == _auth.currentUser!.uid) {
        isAdmin = element['isAdmin'];
      }
    });
    return isAdmin;
  }

  Future removeMembers(int index) async {
    final member = membersList[index]; // 👈 Lưu lại thông tin trước khi xóa
    final String uid = member['uid'];
    final String username = member['username'];

    setState(() {
      isLoading = true;
      membersList.removeAt(index);
    });

    try {
      await _firestore.collection('groupChats').doc(widget.groupId).update({
        "members": membersList,
      });

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('groupChats')
          .doc(widget.groupId)
          .delete();

      // await _firestore
      //     .collection('groupChats')
      //     .doc(widget.groupId)
      //     .collection('messages')
      //     .add({
      //   "message": "${_auth.currentUser!.displayName} đã xóa $username khỏi nhóm",
      //   "toGroupId": widget.groupId,
      //   "type": "notify",
      //   "sent": DateTime.now().millisecondsSinceEpoch.toString(),
      // });
      GroupChatApi.sendGroupNotify(
        widget.groupId,
        "${_auth.currentUser!.displayName} đã xóa $username khỏi nhóm",
      );
    } catch (e) {
      // Optional: handle errors
      print("Lỗi khi xóa thành viên: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void showDialogBox(int index) {
    if (checkAdmin()) {
      if (_auth.currentUser!.uid != membersList[index]['uid']) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              content: ListTile(
                onTap: () => removeMembers(index),
                title: Text("Remove This Member"),
              ),
            );
          },
        );
      }
    }
  }

  Future onLeaveGroup() async {
    if (!checkAdmin()) {
      setState(() {
        isLoading = true;
      });

      for (int i = 0; i < membersList.length; i++) {
        if (membersList[i]['uid'] == _auth.currentUser!.uid) {
          membersList.removeAt(i);
        }
      }

      await _firestore.collection('groupChats').doc(widget.groupId).update({
        "members": membersList,
      });

      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('groupChats')
          .doc(widget.groupId)
          .delete();

      // await _firestore.collection('groupChats').doc(widget.groupId).collection('messages').add({
      //   "message": "${_auth.currentUser!.displayName} đã rời nhóm",
      //   "toGroupId": widget.groupId,
      //   "type": "notify",
      //   "sent": DateTime.now().millisecondsSinceEpoch.toString(),
      // });
      GroupChatApi.sendGroupNotify(
        widget.groupId,
        "${_auth.currentUser!.displayName} đã rời nhóm",
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => ChatPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final Size size = MediaQuery.of(context).size;

    return SafeArea(
      child: Scaffold(
        backgroundColor: AppBackgroundStyles.mainBackground(isDarkMode),
        body:
            isLoading
                ? Container(
                  height: size.height,
                  width: size.width,
                  alignment: Alignment.center,
                  child: CircularProgressIndicator(),
                )
                : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: BackButton(
                          color: AppTextStyles.normalTextColor(isDarkMode),
                        ),
                      ),
                      Container(
                        height: size.height / 8,
                        width: size.width / 1.1,
                        child: Row(
                          children: [
                            Container(
                              height: size.height / 11,
                              width: size.height / 11,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black87,
                              ),
                              child: Icon(
                                Icons.group,
                                color: Colors.white,
                                size: size.width / 10,
                              ),
                            ),
                            SizedBox(width: size.width / 20),
                            Expanded(
                              child: Container(
                                child: Text(
                                  widget.groupName,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppTextStyles.normalTextColor(
                                      isDarkMode,
                                    ),
                                    fontSize: size.width / 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      //
                      SizedBox(height: size.height / 20),

                      Container(
                        width: size.width / 1.1,
                        child: Text(
                          "${membersList.length} Members",
                          style: TextStyle(
                            color: AppTextStyles.normalTextColor(isDarkMode),
                            fontSize: size.width / 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      SizedBox(height: size.height / 20),

                      // Members Name
                      checkAdmin()
                          ? ListTile(
                            onTap:
                                () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder:
                                        (_) => AddMembersINGroup(
                                          groupChatId: widget.groupId,
                                          name: widget.groupName,
                                          membersList: membersList,
                                        ),
                                  ),
                                ),
                            leading: Icon(
                              Icons.add,
                              color: AppIconStyles.iconPrimary(isDarkMode),
                            ),
                            title: Text(
                              "Add Members",
                              style: TextStyle(
                                color: AppTextStyles.normalTextColor(
                                  isDarkMode,
                                ),
                                fontSize: size.width / 22,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                          : SizedBox(),

                      Flexible(
                        child: ListView.builder(
                          itemCount: membersList.length,
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            return ListTile(
                              onTap: () => showDialogBox(index),
                              leading: ProfileImage(
                                size: mq.height * .055,
                                url: membersList[index]['avatarUrl'] ?? '',
                                isOnline:
                                    membersList[index]['is_online'] ?? false,
                              ),
                              title: Text(
                                membersList[index]['username'],
                                style: TextStyle(
                                  color: AppTextStyles.normalTextColor(
                                    isDarkMode,
                                  ),
                                  fontSize: size.width / 22,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                membersList[index]['email'],
                                style: TextStyle(
                                  color: AppTextStyles.subTextColor(isDarkMode),
                                ),
                              ),
                              trailing: Text(
                                membersList[index]['isAdmin'] ? "Admin" : "",
                                style: TextStyle(
                                  color: AppTextStyles.normalTextColor(
                                    isDarkMode,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      ListTile(
                        onTap: onLeaveGroup,
                        leading: Icon(Icons.logout, color: Colors.redAccent),
                        title: Text(
                          "Leave Group",
                          style: TextStyle(
                            fontSize: size.width / 22,
                            fontWeight: FontWeight.w500,
                            color: Colors.redAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}
