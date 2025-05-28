import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:learnity/screen/Group/Create_Group.dart';
import 'package:learnity/theme/theme.dart';

class GroupScreen extends StatefulWidget {
  const GroupScreen({super.key});

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _joinedSearchController = TextEditingController();
  final TextEditingController _availableSearchController =
      TextEditingController();

  List<Map<String, dynamic>> joinedGroups = [];
  List<Map<String, dynamic>> availableGroups = [];
  List<Map<String, dynamic>> filteredJoinedGroups = [];
  List<Map<String, dynamic>> filteredAvailableGroups = [];

  bool isLoadingJoined = true;
  bool isLoadingAvailable = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadJoinedGroups();
    _loadAvailableGroups();

    // Lắng nghe thay đổi trong ô tìm kiếm
    _joinedSearchController.addListener(_filterJoinedGroups);
    _availableSearchController.addListener(_filterAvailableGroups);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _joinedSearchController.dispose();
    _availableSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadJoinedGroups() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final userGroupsSnapshot =
          await _firestore
              .collection('users')
              .doc(currentUser.uid)
              .collection('groups')
              .get();

      final List<Map<String, dynamic>> groups = [];

      for (var doc in userGroupsSnapshot.docs) {
        final groupData = doc.data();

        // Lấy thêm thông tin chi tiết từ collection chính
        final groupDetailSnapshot =
            await _firestore.collection('groups').doc(groupData['id']).get();

        if (groupDetailSnapshot.exists) {
          final detailData = groupDetailSnapshot.data()!;
          groups.add({
            'id': groupData['id'],
            'name': groupData['name'],
            'avatarUrl': groupData['avatarUrl'] ?? '',
            'privacy': groupData['privacy'],
            'memberCount': (detailData['members'] as List).length,
            'lastActivity': detailData['createdAt'] ?? Timestamp.now(),
          });
        }
      }

      setState(() {
        joinedGroups = groups;
        filteredJoinedGroups = groups;
        isLoadingJoined = false;
      });
    } catch (e) {
      print('Error loading joined groups: $e');
      setState(() {
        isLoadingJoined = false;
      });
    }
  }

  // Lấy danh sách nhóm có thể tham gia
  Future<void> _loadAvailableGroups() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Lấy tất cả nhóm công khai
      final allGroupsSnapshot =
          await _firestore
              .collection('groups')
              .where('privacy', isEqualTo: 'Công khai')
              .get();

      // Lấy danh sách ID nhóm đã tham gia
      final userGroupsSnapshot =
          await _firestore
              .collection('users')
              .doc(currentUser.uid)
              .collection('groups')
              .get();

      final joinedGroupIds =
          userGroupsSnapshot.docs.map((doc) => doc.id).toSet();

      List<Map<String, dynamic>> groups = [];

      for (var doc in allGroupsSnapshot.docs) {
        final groupData = doc.data();

        // Chỉ thêm nhóm chưa tham gia
        if (!joinedGroupIds.contains(doc.id)) {
          groups.add({
            'id': doc.id,
            'name': groupData['name'],
            'avatarUrl': groupData['avatarUrl'] ?? '',
            'privacy': groupData['privacy'],
            'memberCount': (groupData['members'] as List).length,
            'createdBy': groupData['createdBy'],
            'createdAt': groupData['createdAt'] ?? Timestamp.now(),
          });
        }
      }

      setState(() {
        availableGroups = groups;
        filteredAvailableGroups = groups;
        isLoadingAvailable = false;
      });
    } catch (e) {
      print('Error loading available groups: $e');
      setState(() {
        isLoadingAvailable = false;
      });
    }
  }

  // Lọc nhóm đã tham gia
  void _filterJoinedGroups() {
    final query = _joinedSearchController.text.toLowerCase();
    setState(() {
      filteredJoinedGroups =
          joinedGroups
              .where((group) => group['name'].toLowerCase().contains(query))
              .toList();
    });
  }

  // Lọc nhóm có thể tham gia
  void _filterAvailableGroups() {
    final query = _availableSearchController.text.toLowerCase();
    setState(() {
      filteredAvailableGroups =
          availableGroups
              .where((group) => group['name'].toLowerCase().contains(query))
              .toList();
    });
  }

  // Tham gia nhóm
  Future<void> _joinGroup(
    String groupId,
    Map<String, dynamic> groupData,
  ) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Lấy thông tin user hiện tại
      final userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      final userData = userDoc.data()!;

      // Thêm user vào danh sách members của nhóm
      await _firestore.collection('groups').doc(groupId).update({
        'members': FieldValue.arrayUnion([
          {
            "username": userData['username'],
            "email": userData['email'],
            "uid": userData['uid'],
            "isAdmin": false,
          },
        ]),
      });

      // Thêm nhóm vào collection groups của user
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('groups')
          .doc(groupId)
          .set({
            "name": groupData['name'],
            "id": groupId,
            "avatarUrl": groupData['avatarUrl'],
            "privacy": groupData['privacy'],
          });

      // Thêm tin nhắn thông báo
      await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('chats')
          .add({
            "message": "${userData['username']} đã tham gia nhóm",
            "type": "notify",
            "time": FieldValue.serverTimestamp(),
          });

      // Reload dữ liệu
      _loadJoinedGroups();
      _loadAvailableGroups();

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

  // Rời nhóm
  Future<void> _leaveGroup(String groupId, String groupName) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Lấy thông tin user hiện tại
      final userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      final userData = userDoc.data()!;

      // Xóa user khỏi danh sách members của nhóm
      await _firestore.collection('groups').doc(groupId).update({
        'members': FieldValue.arrayRemove([
          {
            "username": userData['username'],
            "email": userData['email'],
            "uid": userData['uid'],
            "isAdmin": false,
          },
        ]),
      });

      // Xóa nhóm khỏi collection groups của user
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('groups')
          .doc(groupId)
          .delete();

      // Thêm tin nhắn thông báo
      await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('chats')
          .add({
            "message": "${userData['username']} đã rời khỏi nhóm",
            "type": "notify",
            "time": FieldValue.serverTimestamp(),
          });

      // Reload dữ liệu
      _loadJoinedGroups();
      _loadAvailableGroups();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã rời khỏi nhóm'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error leaving group: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi rời nhóm: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget buildJoinedGroupCard(Map<String, dynamic> group) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          radius: 24,
          backgroundImage:
              group['avatarUrl'].isNotEmpty
                  ? NetworkImage(group['avatarUrl'])
                  : const AssetImage('assets/group_avatar.png')
                      as ImageProvider,
        ),
        title: Text(
          group['name'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${group['memberCount']} thành viên • ${group['privacy']}',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.exit_to_app, color: Colors.red),
          onPressed: () {
            showDialog(
              context: context,
              builder:
                  (context) => AlertDialog(
                    title: const Text('Rời nhóm'),
                    content: Text(
                      'Bạn có chắc muốn rời khỏi nhóm "${group['name']}"?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Hủy'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _leaveGroup(group['id'], group['name']);
                        },
                        child: const Text(
                          'Rời nhóm',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
            );
          },
        ),
      ),
    );
  }

  Widget buildAvailableGroupCard(Map<String, dynamic> group) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage:
                    group['avatarUrl'].isNotEmpty
                        ? NetworkImage(group['avatarUrl'])
                        : const AssetImage('assets/group_avatar.png')
                            as ImageProvider,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${group['memberCount']} thành viên',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      group['privacy'] == 'Công khai'
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  group['privacy'],
                  style: TextStyle(
                    color:
                        group['privacy'] == 'Công khai'
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _joinGroup(group['id'], group),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9EB9A8),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Tham gia',
                style: TextStyle(fontWeight: FontWeight.bold),
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          'Nhóm',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 25,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.black),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateGroup()),
              );
              // Reload dữ liệu nếu tạo nhóm thành công
              if (result == true) {
                _loadJoinedGroups();
                _loadAvailableGroups();
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey.shade400,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          indicatorColor: Colors.black,
          indicatorWeight: 2,
          tabs: const [Tab(text: 'Đã tham gia'), Tab(text: 'Chưa tham gia')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Đã tham gia
          RefreshIndicator(
            onRefresh: _loadJoinedGroups,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _joinedSearchController,
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm nhóm đã tham gia',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child:
                        isLoadingJoined
                            ? const Center(child: CircularProgressIndicator())
                            : filteredJoinedGroups.isEmpty
                            ? const Center(
                              child: Text(
                                'Chưa tham gia nhóm nào',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            )
                            : ListView.builder(
                              itemCount: filteredJoinedGroups.length,
                              itemBuilder: (context, index) {
                                return buildJoinedGroupCard(
                                  filteredJoinedGroups[index],
                                );
                              },
                            ),
                  ),
                ],
              ),
            ),
          ),

          // Tab 2: Chưa tham gia
          RefreshIndicator(
            onRefresh: _loadAvailableGroups,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _availableSearchController,
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm nhóm để tham gia',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child:
                        isLoadingAvailable
                            ? const Center(child: CircularProgressIndicator())
                            : filteredAvailableGroups.isEmpty
                            ? const Center(
                              child: Text(
                                'Không có nhóm nào để tham gia',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            )
                            : ListView.builder(
                              itemCount: filteredAvailableGroups.length,
                              itemBuilder: (context, index) {
                                return buildAvailableGroupCard(
                                  filteredAvailableGroups[index],
                                );
                              },
                            ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
