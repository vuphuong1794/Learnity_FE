import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:learnity/screen/Group/group_content_screen.dart';

class ViewInviteGroup extends StatefulWidget {
  const ViewInviteGroup({super.key});

  @override
  State<ViewInviteGroup> createState() => _ViewInviteGroupState();
}

class _ViewInviteGroupState extends State<ViewInviteGroup> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> invitedGroups = [];
  Set<String> pendingRequests = {};

  @override
  void initState() {
    super.initState();
    _loadInvitedGroups();
    _loadPendingRequests(); // ← THÊM DÒNG NÀY
  }

  Future<void> _loadPendingRequests() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final requestsSnapshot =
          await _firestore
              .collectionGroup('join_requests')
              .where('userId', isEqualTo: currentUser.uid)
              .where('status', isEqualTo: 'pending')
              .get();

      setState(() {
        pendingRequests =
            requestsSnapshot.docs
                .map((doc) => doc.reference.parent.parent!.id)
                .toSet();
      });
    } catch (e) {
      print('Error loading pending requests: $e');
    }
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

        if (data['receiverId'] == currentUser.uid) {
          print("Found invite for current user: ${data['groupId']}");

          final groupDoc =
              await _firestore
                  .collection('communityGroups')
                  .doc(data['groupId'])
                  .get();

          if (groupDoc.exists) {
            final groupData = groupDoc.data()!;
            final membersList =
                groupData['membersList'] as List<dynamic>? ?? [];

            bool isUserAlreadyMember = membersList.any(
              (member) =>
                  member is Map<String, dynamic> &&
                  member['uid'] == currentUser.uid,
            );

            String status = groupData['status'] ?? 'inactive';
            String privacy = groupData['privacy'] ?? 'Công khai';

            print(
              'Group: ${groupData['groupName']}, Privacy: $privacy, Status: $status',
            );

            if (!isUserAlreadyMember && status == 'active') {
              groups.add({
                'id': doc.id,
                'groupId': data['groupId'],
                'groupName': data['groupName'],
                'senderName': data['senderName'],
                'message': data['message'] ?? '',
                'timestamp': data['timestamp'],
                'privacy': privacy, // lấy đúng từ groupData
              });
            }
          }
        }
      }

      print("Tổng số lời mời hợp lệ: ${groups.length}");

      setState(() {
        invitedGroups = groups;
      });
    } catch (e) {
      print('Error loading invited groups: $e');
    }
  }

  Future<void> _declineInvite(String inviteId) async {
    await _firestore
        .collection('invite_member_notifications')
        .doc(inviteId)
        .delete();
    _loadInvitedGroups();
  }

  Future<void> _previewJoinedGroup(String groupId, String groupData) async {
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => GroupcontentScreen(
                groupId: groupId,
                groupName: groupData,
                isPreviewMode: false,
              ),
        ),
      );
    } catch (e) {
      print('Error previewing group: $e');
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

  Future<void> joinGroup(String groupId, Map<String, dynamic> groupData) async {
    if (groupData['privacy'] == 'Riêng tư') {
      await _sendJoinRequest(groupId, groupData);
    } else {
      await joinPublicGroup(groupId, groupData);
    }
  }

  Future<void> _cancelJoinRequest(String groupId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      await _firestore
          .collection('communityGroups')
          .doc(groupId)
          .collection('join_requests')
          .doc(currentUser.uid)
          .delete();

      setState(() {
        pendingRequests.remove(groupId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã hủy yêu cầu tham gia'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error canceling join request: $e');
    }
  }

  Future<void> _sendJoinRequest(
    String groupId,
    Map<String, dynamic> groupData,
  ) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      final userData = userDoc.data()!;

      await _firestore
          .collection('communityGroups')
          .doc(groupId)
          .collection('join_requests')
          .doc(currentUser.uid)
          .set({
            'userId': currentUser.uid,
            'username': userData['username'],
            'email': userData['email'],
            'avatarUrl': userData['avatarUrl'] ?? '',
            'status': 'pending',
            'createdAt': FieldValue.serverTimestamp(),
            'groupName': groupData['groupName'],
          });

      setState(() {
        pendingRequests.add(groupId); // ← CẬP NHẬT NGAY
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã gửi yêu cầu tham gia. Chờ admin duyệt!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error sending join request: $e');
    }
  }

  Future<void> joinPublicGroup(
    String groupId,
    Map<String, dynamic> groupData,
  ) async {
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

      // Delete invite
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
    }
  }

  Widget _buildScrollableActionButtons(Map<String, dynamic> group) {
    final isPrivate = group['privacy'] == 'Riêng tư';
    final groupId = group['groupId'];
    final hasPendingRequest = pendingRequests.contains(groupId);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          if (!isPrivate)
            Container(
              margin: const EdgeInsets.only(right: 8.0),
              child: ElevatedButton.icon(
                onPressed:
                    () => _previewJoinedGroup(groupId, group['groupName']),
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
          Container(
            margin: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton.icon(
              onPressed:
                  hasPendingRequest
                      ? () => _cancelJoinRequest(groupId)
                      : () => joinGroup(groupId, group),
              icon: Icon(
                hasPendingRequest
                    ? Icons.cancel
                    : isPrivate
                    ? Icons.lock_outline
                    : Icons.check,
                size: 18,
              ),
              label: Text(
                hasPendingRequest
                    ? "Hủy yêu cầu"
                    : isPrivate
                    ? "Gửi yêu cầu"
                    : "Tham gia",
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    hasPendingRequest
                        ? Colors.orange
                        : isPrivate
                        ? Colors.blue
                        : Colors.green,
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
    return Scaffold(
      appBar: AppBar(title: const Text("Lời mời nhóm")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            invitedGroups.isEmpty
                ? const Center(child: Text("Không có lời mời nào."))
                : ListView.builder(
                  itemCount: invitedGroups.length,
                  itemBuilder: (context, index) {
                    final group = invitedGroups[index];
                    final isPrivate = group['privacy'] == 'Riêng tư';
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
                                Icon(
                                  isPrivate ? Icons.lock : Icons.group,
                                  size: 20,
                                  color:
                                      isPrivate ? Colors.orange : Colors.blue,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    group['groupName'] ??
                                        'Tên nhóm không xác định',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color:
                                          isPrivate
                                              ? Colors.orange
                                              : Colors.blue,
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
