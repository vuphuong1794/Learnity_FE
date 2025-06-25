import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:learnity/screen/Group/group_content_screen.dart';

import 'package:provider/provider.dart';
import 'package:learnity/theme/theme.dart';
import 'package:learnity/theme/theme_provider.dart';

class ViewInviteGroup extends StatefulWidget {
  const ViewInviteGroup({super.key});

  @override
  State<ViewInviteGroup> createState() => _ViewInviteGroupState();
}

class _ViewInviteGroupState extends State<ViewInviteGroup> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> invitedGroups = [];

  @override
  void initState() {
    super.initState();
    _loadInvitedGroups();
  }

  Future<void> _loadInvitedGroups() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final allInvitedGroupsSnapshot =
          await _firestore.collection('invite_member_notifications').get();

      List<Map<String, dynamic>> groups = [];

      for (var doc in allInvitedGroupsSnapshot.docs) {
        final data = doc.data();

        // Check if invitation is for the current user
        if (data['receiverId'] == currentUser.uid) {
          // Get group information to check if user is already a member
          final groupDoc =
              await _firestore
                  .collection('communityGroups')
                  .doc(data['groupId'])
                  .get();

          if (groupDoc.exists) {
            final groupData = groupDoc.data()!;
            final membersList =
                groupData['membersList'] as List<dynamic>? ?? [];

            // Check if current user is NOT already in the members list
            bool isUserAlreadyMember = membersList.any(
              (member) =>
                  member is Map<String, dynamic> &&
                  member['uid'] == currentUser.uid,
            );

            // Only add invitation if user is NOT already a member
            if (!isUserAlreadyMember) {
              groups.add({
                'id': doc.id,
                'groupId': data['groupId'],
                'groupName': data['groupName'],
                'senderName': data['senderName'],
                'message': data['message'] ?? '',
                'timestamp': data['timestamp'],
              });
            }
          }
        }
      }

      setState(() {
        invitedGroups = groups;
      });
    } catch (e) {
      print('Error loading invited groups: $e');
    }
  }

  Future<void> _declineInvite(String inviteId) async {
    print('Declined invite $inviteId');
    await _firestore
        .collection('invite_member_notifications')
        .doc(inviteId)
        .delete();
    _loadInvitedGroups();
  }

  Future<void> _previewJoinedGroup(String groupId, String groupData) async {
    try {
      // Điều hướng đến trang GroupContentScreen với isPreviewMode = true
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => GroupcontentScreen(
                groupId: groupId,
                groupName: groupData,
                isPreviewMode: false, // Chế độ xem trước
              ),
        ),
      );
    } catch (e) {
      print('Error previewing joined group: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể xem trước nhóm'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> joinGroup(String groupId, String groupData) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      final userData = userDoc.data()!;

      await _firestore.collection('communityGroups').doc(groupId).update({
        'membersList': FieldValue.arrayUnion([
          {
            "username": userData['username'],
            "email": userData['email'],
            "uid": userData['uid'],
            "avatarUrl": userData['avatarUrl'],
            "isAdmin": false,
          },
        ]),
        'membersCount': FieldValue.increment(1),
      });

      // Sau khi tham gia, xóa lời mời và load lại danh sách
      await _firestore
          .collection('invite_member_notifications')
          .where('receiverId', isEqualTo: currentUser.uid)
          .where('groupId', isEqualTo: groupId)
          .get()
          .then((snapshot) {
            for (var doc in snapshot.docs) {
              doc.reference.delete();
            }
          });

      _loadInvitedGroups();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tham gia nhóm thành công!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error joining group: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tham gia nhóm: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildScrollableActionButtons(Map<String, dynamic> group) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Preview Button
          Container(
            margin: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton.icon(
              onPressed: () {
                _previewJoinedGroup(group['groupId'], group['groupName']);
              },
              icon: const Icon(Icons.visibility, size: 18),
              label: const Text("Xem trước"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          // Accept Button
          Container(
            margin: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton.icon(
              onPressed: () => joinGroup(group['groupId'], group['groupName']),
              icon: const Icon(Icons.check, size: 18),
              label: const Text("Chấp nhận"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          // Decline Button
          Container(
            margin: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton.icon(
              onPressed: () => _declineInvite(group['id']),
              icon: const Icon(Icons.close, size: 18),
              label: const Text("Từ chối"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: AppBackgroundStyles.mainBackground(isDarkMode),
      appBar: AppBar(
        backgroundColor: AppBackgroundStyles.secondaryBackground(isDarkMode),
        iconTheme: IconThemeData(
          color: AppIconStyles.iconPrimary(isDarkMode), // Đổi màu mũi tên tại đây
        ),
        title: Text("Lời mời nhóm", style: TextStyle(color: AppTextStyles.normalTextColor(isDarkMode))),
        ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            invitedGroups.isEmpty
                ? Center(child: Text("Không có lời mời nào.", style: TextStyle(color: AppTextStyles.normalTextColor(isDarkMode))))
                : ListView.builder(
                  itemCount: invitedGroups.length,
                  itemBuilder: (context, index) {
                    final group = invitedGroups[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.group,
                                  size: 20,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    group['groupName'] ??
                                        'Tên nhóm không xác định',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.person,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "Người gửi: ${group['senderName']}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            if (group['message'].isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.message,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      "Tin nhắn: ${group['message']}",
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 16),
                            // Scrollable action buttons
                            _buildScrollableActionButtons(group),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
