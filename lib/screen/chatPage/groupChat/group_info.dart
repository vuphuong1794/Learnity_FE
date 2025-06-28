import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:learnity/main.dart';
import 'package:learnity/widgets/chatPage/singleChatPage/profile_image.dart';
import '../../../api/group_chat_api.dart';
import 'add_members.dart';
import '../chat_page.dart';

import 'package:provider/provider.dart';
import 'package:learnity/theme/theme.dart';
import 'package:learnity/theme/theme_provider.dart';

class GroupInfo extends StatefulWidget {
  final String groupId, groupName;

  const GroupInfo({required this.groupId, required this.groupName, Key? key})
    : super(key: key);

  @override
  _GroupInfoState createState() => _GroupInfoState();
}

class _GroupInfoState extends State<GroupInfo> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> members = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroupData();
  }

  Future<void> _loadGroupData() async {
    try {
      final doc =
          await _firestore.collection('groupChats').doc(widget.groupId).get();
      if (!doc.exists) return;

      final data = doc.data()!;
      members = List<Map<String, dynamic>>.from(data['members'] ?? []);

      // Load additional user info for members
      await _loadMembersInfo();
    } catch (e) {
      print('Error loading group: $e');
      _showError('Failed to load group');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _loadMembersInfo() async {
    try {
      final memberIds = members.map((m) => m['uid'] as String).toSet().toList();
      final users =
          await _firestore
              .collection('users')
              .where(FieldPath.documentId, whereIn: memberIds)
              .get();

      for (var doc in users.docs) {
        final userData = doc.data();
        final index = members.indexWhere((m) => m['uid'] == doc.id);
        if (index != -1) {
          members[index].addAll({
            'username': userData['username'] ?? 'Unknown',
            'email': userData['email'] ?? '',
            'avatarUrl': userData['avatarUrl'] ?? '',
            'is_online': userData['is_online'] ?? false,
          });
        }
      }
    } catch (e) {
      print('Error loading members: $e');
    }
  }

  bool get _isAdmin {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;
    return members.firstWhere(
          (m) => m['uid'] == uid,
          orElse: () => {'isAdmin': false},
        )['isAdmin'] ??
        false;
  }

  Future<void> _removeMember(int index) async {
    if (index < 0 || index >= members.length) return;

    setState(() => isLoading = true);
    try {
      await _firestore.collection('groupChats').doc(widget.groupId).update({
        "members": FieldValue.arrayRemove([members[index]]),
      });

      await _firestore
          .collection('users')
          .doc(members[index]['uid'])
          .collection('groupChats')
          .doc(widget.groupId)
          .delete();

      GroupChatApi.sendGroupNotify(
        widget.groupId,
        "${_auth.currentUser?.displayName} removed ${members[index]['username']}",
      );

      setState(() => members.removeAt(index));
    } catch (e) {
      print('Error removing member: $e');
      _showError('Failed to remove member');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _leaveGroup() async {
    if (_isAdmin) {
      _showError('Transfer admin rights before leaving');
      return;
    }

    setState(() => isLoading = true);
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      await _firestore.collection('groupChats').doc(widget.groupId).update({
        "members": members.where((m) => m['uid'] != uid).toList(),
      });

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('groupChats')
          .doc(widget.groupId)
          .delete();

      GroupChatApi.sendGroupNotify(
        widget.groupId,
        "${_auth.currentUser?.displayName} left the group",
      );

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => ChatPage()),
          (route) => false,
        );
      }
    } catch (e) {
      print('Error leaving group: $e');
      _showError('Failed to leave group');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppBackgroundStyles.mainBackground(isDarkMode),
      appBar: AppBar(
        backgroundColor: AppBackgroundStyles.mainBackground(isDarkMode),
        iconTheme: IconThemeData(
          color: AppIconStyles.iconPrimary(
            isDarkMode,
          ), // Đổi màu mũi tên tại đây
        ),
      ),
      body: isLoading ? _buildLoading() : _buildContent(isDarkMode, size),
    );
  }

  Widget _buildLoading() => Center(child: CircularProgressIndicator());

  Widget _buildContent(bool isDark, Size size) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(isDark, size),
          _buildMemberCount(isDark, size),
          if (_isAdmin) _buildAddMemberButton(isDark, size),
          _buildMemberList(isDark),
          _buildLeaveButton(),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDarkMode, Size size) {
    return Padding(
      padding: const EdgeInsets.only(top: 15),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: size.height / 22,
            backgroundColor: Colors.blue,
            child: Icon(Icons.group, size: size.width / 8, color: Colors.white),
          ),
          SizedBox(height: 8),
          Text(
            widget.groupName,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTextStyles.normalTextColor(isDarkMode),
              fontSize: size.width / 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCount(bool isDarkMode, Size size) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        "${members.length} Members",
        style: TextStyle(
          color: AppTextStyles.subTextColor(isDarkMode),
          fontSize: size.width / 22,
        ),
      ),
    );
  }

  Widget _buildAddMemberButton(bool isDarkMode, Size size) {
    return ListTile(
      leading: Icon(Icons.add, color: Colors.blue),
      title: Text("Add Members", style: TextStyle(color: Colors.blue)),
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => AddMembersINGroup(
                    groupChatId: widget.groupId,
                    name: widget.groupName,
                    membersList: members,
                  ),
            ),
          ),
    );
  }

  Widget _buildMemberList(bool isDarkMode) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: members.length,
      itemBuilder: (ctx, index) {
        final member = members[index];
        final isCurrentUser = member['uid'] == _auth.currentUser?.uid;

        return ListTile(
          leading: ProfileImage(
            size: mq.height * .055,
            url: member['avatarUrl'] ?? '',
            isOnline: member['is_online'] ?? false,
          ),
          title: Text(
            member['username'],
            style: TextStyle(color: AppTextStyles.normalTextColor(isDarkMode)),
          ),
          subtitle: Text(
            member['email'],
            style: TextStyle(color: AppTextStyles.subTextColor(isDarkMode)),
          ),
          trailing:
              _isAdmin && !isCurrentUser
                  ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (member['isAdmin'] == true)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            "Admin",
                            style: TextStyle(
                              color: AppTextStyles.normalTextColor(isDarkMode),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      IconButton(
                        icon: Icon(Icons.person_remove, color: Colors.red),
                        onPressed: () => _showRemoveDialog(isDarkMode, index),
                      ),
                    ],
                  )
                  : (member['isAdmin'] == true
                      ? Text(
                        "Admin",
                        style: TextStyle(
                          color: AppTextStyles.normalTextColor(isDarkMode),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      )
                      : null),
        );
      },
    );
  }

  Widget _buildLeaveButton() {
    return ListTile(
      leading: Icon(Icons.exit_to_app, color: Colors.red),
      title: Text("Leave Group", style: TextStyle(color: Colors.red)),
      onTap: _leaveGroup,
    );
  }

  void _showRemoveDialog(bool isDarkMode, int index) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: AppBackgroundStyles.modalBackground(isDarkMode),
            title: Text(
              "Xóa người dùng",
              style: TextStyle(
                color: AppTextStyles.normalTextColor(isDarkMode),
              ),
            ),
            content: Text(
              "Bạn có chắc chắn muốn xóa ${members[index]['username']} khỏi nhóm?",
              style: TextStyle(
                color: AppTextStyles.normalTextColor(isDarkMode),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  "Hủy",
                  style: TextStyle(
                    color: AppTextStyles.subTextColor(isDarkMode),
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _removeMember(index);
                },
                child: Text("Xóa", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }
}
