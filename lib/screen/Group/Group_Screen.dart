import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:learnity/screen/Group/Create_Group.dart';
import 'package:learnity/screen/Group/View_invite_Group.dart';
import 'package:learnity/theme/theme.dart';
import 'group_content_screen.dart';

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

  // Danh sách ID nhóm đã gửi yêu cầu tham gia
  Set<String> pendingRequests = {};

  bool isLoadingJoined = true;
  bool isLoadingAvailable = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadJoinedGroups();
    _loadAvailableGroups();
    _loadPendingRequests();

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

  // Tải danh sách yêu cầu đang chờ duyệt
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

  Future<void> _loadJoinedGroups() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Lấy tất cả nhóm từ communityGroups
      final allGroupsSnapshot =
          await _firestore.collection('communityGroups').get();

      final List<Map<String, dynamic>> groups = [];

      for (var doc in allGroupsSnapshot.docs) {
        final data = doc.data();
        final members = data['membersList'] as List<dynamic>? ?? [];

        // Kiểm tra xem người dùng hiện tại có trong nhóm không
        final isMember = members.any(
          (member) => member['uid'] == currentUser.uid,
        );
        if (isMember) {
          groups.add({
            'id': data['id'],
            'name': data['name'],
            'avatarUrl': data['avatarUrl'] ?? '',
            'createdBy': data['createdBy'],
            'privacy': data['privacy'],
            'membersCount': data['membersCount'] ?? members.length,
            'lastActivity': data['createdAt'] ?? Timestamp.now(),
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

  Future<void> _loadAvailableGroups() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final allGroupsSnapshot =
          await _firestore.collection('communityGroups').get();

      List<Map<String, dynamic>> groups = [];

      for (var doc in allGroupsSnapshot.docs) {
        final data = doc.data();
        final members = data['membersList'] as List<dynamic>? ?? [];

        final isMember = members.any(
          (member) => member['uid'] == currentUser.uid,
        );
        if (!isMember) {
          groups.add({
            'id': data['id'],
            'name': data['name'],
            'avatarUrl': data['avatarUrl'] ?? '',
            'privacy': data['privacy'],
            'membersCount': data['membersCount'] ?? members.length,
            'createdBy': data['createdBy'],
            'createdAt': data['createdAt'] ?? Timestamp.now(),
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

  // Gửi yêu cầu tham gia nhóm riêng tư
  Future<void> _sendJoinRequest(
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

      // Tạo yêu cầu tham gia
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
            'groupName': groupData['name'],
          });

      // Cập nhật trạng thái local
      setState(() {
        pendingRequests.add(groupId);
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi gửi yêu cầu: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Tham gia nhóm công khai hoặc gửi yêu cầu cho nhóm riêng tư
  Future<void> _joinGroup(
    String groupId,
    Map<String, dynamic> groupData,
  ) async {
    if (groupData['privacy'] == 'Riêng tư') {
      // Gửi yêu cầu tham gia cho nhóm riêng tư
      await _sendJoinRequest(groupId, groupData);
    } else {
      // Tham gia ngay lập tức cho nhóm công khai
      await _joinPublicGroup(groupId, groupData);
    }
  }

  // Tham gia nhóm công khai
  Future<void> _joinPublicGroup(
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
      await _firestore.collection('communityGroups').doc(groupId).update({
        'membersList': FieldValue.arrayUnion([
          {
            "username": userData['username'],
            "email": userData['email'],
            "uid": userData['uid'],
            "avatarUrl" :userData['avatarUrl'],
            "isAdmin": false,
          },
        ]),
        'membersCount': FieldValue.increment(1),
      });

      // Thêm nhóm vào collection communityGroups của user
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('communityGroups')
          .doc(groupId)
          .set({
            'name': groupData['name'],
            'id': groupId,
            'avatarUrl': groupData['avatarUrl'],
            'privacy': groupData['privacy'],
          });

      // Reload dữ liệu
      await _loadJoinedGroups();
      await _loadAvailableGroups();

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
      await _firestore.collection('communityGroups').doc(groupId).update({
        'membersList': FieldValue.arrayRemove([
          {
            "username": userData['username'],
            "email": userData['email'],
            "uid": userData['uid'],
            "isAdmin": false,
          },
        ]),
        'membersCount': FieldValue.increment(-1),
      });

      // Xóa nhóm khỏi collection communityGroups của user
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('communityGroups')
          .doc(groupId)
          .delete();

      // Reload dữ liệu
      await _loadJoinedGroups();
      await _loadAvailableGroups();

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

  // Hủy yêu cầu tham gia
  Future<void> _cancelJoinRequest(String groupId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Xóa yêu cầu tham gia
      await _firestore
          .collection('communityGroups')
          .doc(groupId)
          .collection('join_requests')
          .doc(currentUser.uid)
          .delete();

      // Cập nhật trạng thái local
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

  // Xem trước nhóm trước khi tham gia
  Future<void> _previewGroup(
    String groupId,
    Map<String, dynamic> groupData,
  ) async {
    try {
      // Điều hướng đến trang GroupContentScreen với isPreviewMode = true
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => GroupcontentScreen(
                groupId: groupId,
                groupName: groupData['name'],
                isPreviewMode: true, // Chế độ xem trước
              ),
        ),
      );

      // Nếu user quyết định tham gia từ trang preview
      if (result == 'join_group') {
        await _joinGroup(groupId, groupData);
      }
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

  //xem truớc nhóm đã tham gia
  Future<void> _previewJoinedGroup(
    String groupId,
    Map<String, dynamic> groupData,
  ) async {
    try {
      // Điều hướng đến trang GroupContentScreen với isPreviewMode = true
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => GroupcontentScreen(
                groupId: groupId,
                groupName: groupData['name'],
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

  Widget buildJoinedGroupCard(Map<String, dynamic> group) {
    //final isAdmin = group['isAdmin'] ?? false;
    final currentUser = _auth.currentUser;
    final isCreator =
        currentUser != null && group['createdBy'] == currentUser.uid;

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
        title: Row(
          children: [
            Expanded(
              child: Text(
                group['name'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            // Hiển thị badge admin nếu là admin
            if (isCreator)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isCreator ? 'Chủ nhóm' : 'Người dùng',
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(
          '${group['membersCount']} thành viên • ${group['privacy']}',
        ),
        trailing: IconButton(
          icon: Icon(
            isCreator ? Icons.settings : Icons.exit_to_app,
            color: isCreator ? Colors.blue : Colors.red,
          ),
          onPressed: () {
            if (isCreator) {
              // Nếu là admin hoặc chủ nhóm, hiển thị dialog cập nhật thông tin
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Cập nhật thông tin nhóm'),
                      content: Text(
                        'Bạn có muốn cập nhật thông tin nhóm "${group['name']}"?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Hủy'),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            'Cập nhật',
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
              );
            } else {
              // Nếu không phải admin, hiển thị dialog rời nhóm
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
            }
          },
        ),
        onTap: null,
      ),
    );
  }

  Widget buildAvailableGroupCard(Map<String, dynamic> group) {
    final isPrivate = group['privacy'] == 'Riêng tư';
    final hasPendingRequest = pendingRequests.contains(group['id']);

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
                      '${group['membersCount']} thành viên',
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
              onPressed:
                  hasPendingRequest
                      ? () => _cancelJoinRequest(group['id'])
                      : () => _joinGroup(group['id'], group),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    hasPendingRequest
                        ? Colors.orange
                        : (isPrivate ? Colors.blue : const Color(0xFF9EB9A8)),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                hasPendingRequest
                    ? 'Hủy yêu cầu'
                    : (isPrivate ? 'Gửi yêu cầu' : 'Tham gia'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          if (isPrivate && !hasPendingRequest)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Nhóm riêng tư - Cần admin duyệt',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          if (hasPendingRequest)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Yêu cầu đang chờ duyệt',
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    //load lại dữ liệu khi vào trang
    _loadJoinedGroups();
    _loadAvailableGroups();
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
          // Nút xem lời mời tham gia nhóm
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.black),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ViewInviteGroup(),
                ),
              );
            },
          ),
          // Nút tạo nhóm mới
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
                _loadPendingRequests();
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
                                return GestureDetector(
                                  onTap: () {
                                    _previewJoinedGroup(
                                      filteredJoinedGroups[index]['id'],
                                      filteredJoinedGroups[index],
                                    );
                                  },
                                  child: buildJoinedGroupCard(
                                    filteredJoinedGroups[index],
                                  ),
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
            onRefresh: () async {
              await _loadAvailableGroups();
              await _loadPendingRequests();
            },
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
                                return GestureDetector(
                                  onTap: () {
                                    // Xem trước nhóm khi ấn vào
                                    _previewGroup(
                                      filteredAvailableGroups[index]['id'],
                                      filteredAvailableGroups[index],
                                    );
                                  },
                                  child: buildAvailableGroupCard(
                                    filteredAvailableGroups[index],
                                  ),
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
