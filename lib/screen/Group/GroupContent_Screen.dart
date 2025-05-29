import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:learnity/theme/theme.dart';

class GroupcontentScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  final bool isPreviewMode;

  const GroupcontentScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    this.isPreviewMode = false,
  });

  @override
  State<GroupcontentScreen> createState() => _GroupcontentScreenState();
}

class _GroupcontentScreenState extends State<GroupcontentScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Map<String, dynamic>? groupData;
  List<Map<String, dynamic>> recentPosts = [];
  List<Map<String, dynamic>> groupMembers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroupData();
  }

  Future<void> _loadGroupData() async {
    try {
      // Lấy thông tin nhóm
      final groupDoc =
          await _firestore
              .collection('communityGroups')
              .doc(widget.groupId)
              .get();

      if (groupDoc.exists) {
        groupData = groupDoc.data();

        // Lấy danh sách thành viên
        final membersList = groupData?['membersList'] as List<dynamic>? ?? [];
        groupMembers =
            membersList
                .map((member) => Map<String, dynamic>.from(member))
                .toList();

        // Lấy một số bài đăng gần đây (nếu có)
        final postsSnapshot =
            await _firestore
                .collection('communityGroups')
                .doc(widget.groupId)
                .collection('posts')
                .orderBy('createdAt', descending: true)
                .limit(5)
                .get();

        recentPosts =
            postsSnapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList();
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error loading group data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _joinGroup() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Lấy thông tin user hiện tại
      final userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      final userData = userDoc.data()!;

      if (groupData?['privacy'] == 'Riêng tư') {
        // Gửi yêu cầu tham gia cho nhóm riêng tư
        await _firestore
            .collection('communityGroups')
            .doc(widget.groupId)
            .collection('join_requests')
            .doc(currentUser.uid)
            .set({
              'userId': currentUser.uid,
              'username': userData['username'],
              'email': userData['email'],
              'avatarUrl': userData['avatarUrl'] ?? '',
              'status': 'pending',
              'createdAt': FieldValue.serverTimestamp(),
              'groupName': widget.groupName,
            });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã gửi yêu cầu tham gia. Chờ admin duyệt!'),
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.pop(context);
        }
      } else {
        // Tham gia nhóm công khai
        await _firestore
            .collection('communityGroups')
            .doc(widget.groupId)
            .update({
              'membersList': FieldValue.arrayUnion([
                {
                  "username": userData['username'],
                  "email": userData['email'],
                  "uid": userData['uid'],
                  "isAdmin": false,
                },
              ]),
              'membersCount': FieldValue.increment(1),
            });

        await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('communityGroups')
            .doc(widget.groupId)
            .set({
              'name': widget.groupName,
              'id': widget.groupId,
              'avatarUrl': groupData?['avatarUrl'] ?? '',
              'privacy': groupData?['privacy'] ?? 'Công khai',
            });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tham gia nhóm thành công!'),
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.pop(context, 'joined');
        }
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

  Widget _buildGroupHeader() {
    if (groupData == null) return const SizedBox.shrink();

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner image
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                  groupData!['avatarUrl'] ??
                      'https://via.placeholder.com/400x120',
                ),
                fit: BoxFit.fitWidth,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Group info row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.groupName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  groupData!['privacy'] == 'Công khai'
                                      ? Colors.grey.shade200
                                      : Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              groupData!['privacy'] ?? 'Công khai',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${groupData!['membersCount'] ?? groupMembers.length} thành viên',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (widget.isPreviewMode)
                  ElevatedButton(
                    onPressed: _joinGroup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      groupData!['privacy'] == 'Riêng tư'
                          ? 'Yêu cầu tham gia'
                          : 'Tham gia',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSection() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            height: 50,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.blue, width: 2),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Thông tin',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Nhóm liên quan',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: Colors.grey.shade200),
        ],
      ),
    );
  }

  Widget _buildGroupInfo() {
    if (groupData == null) return const SizedBox.shrink();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Giới thiệu',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            groupData!['description'] ??
                'TechConnect Vietnam với sứ mệnh trở thành cộng đồng dành cho sinh viên, du học sinh và những người đam mê công nghệ...',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              // Xem thêm logic
            },
            child: Text(
              'Xem thêm',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitySection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hoạt động trong nhóm',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          _buildActivityItem(
            icon: Icons.article_outlined,
            text: '0 bài viết mới hôm nay',
          ),
          const SizedBox(height: 12),
          _buildActivityItem(
            icon: Icons.people_outline,
            text: 'Tổng số 2,3K thành viên',
            subtitle: '+ 17 trong tuần trước',
          ),
          const SizedBox(height: 12),
          _buildActivityItem(
            icon: Icons.groups_outlined,
            text: 'Tạo khoảng 1 năm trước',
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String text,
    String? subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.grey.shade600, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.isPreviewMode ? 'Xem trước' : widget.groupName),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Column(
                  children: [
                    _buildGroupHeader(),
                    _buildTabSection(),
                    const SizedBox(height: 12),
                    _buildGroupInfo(),
                    const SizedBox(height: 12),
                    _buildActivitySection(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
    );
  }
}
