import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:learnity/screen/groupPage/Create_Group.dart';
import 'package:learnity/screen/groupPage/report_group_page.dart';
import 'package:learnity/screen/groupPage/view_invite_group.dart';
import '../../models/bottom_sheet_option.dart';
import '../../widgets/common/confirm_modal.dart';
import '../../widgets/common/custom_bottom_sheet.dart';
import 'group_content_screen.dart';

import 'package:provider/provider.dart';
import 'package:learnity/theme/theme.dart';
import 'package:learnity/theme/theme_provider.dart';

import 'group_management_page.dart';
import 'manage_group_members_screen.dart';
import 'manage_join_requests_screen.dart';
import 'manage_pending_posts_screen.dart';

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

        final status = data['status'] ?? 'inactive';

        if (isMember && status == 'active') {
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

        final status = data['status'] ?? 'inactive';

        if (!isMember && status == 'active') {
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
        Get.snackbar(
          "Thành công",
          "Yêu cầu tham gia đã được gửi thành công. Vui lòng chờ admin duyệt.",
          backgroundColor: Colors.blue.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      print('Error sending join request: $e');
      if (mounted) {
        Get.snackbar(
          "Lỗi",
          "Không thể gửi yêu cầu tham gia. Vui lòng thử lại sau.",
          backgroundColor: Colors.blue.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
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
            "avatarUrl": userData['avatarUrl'],
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
        Get.snackbar(
          "Thành công",
          "Đã tham gia nhóm thành công!",
          backgroundColor: Colors.blue.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      print('Error joining group: $e');
      if (mounted) {
        Get.snackbar(
          "Lỗi",
          "Không thể tham gia nhóm. Vui lòng thử lại sau.",
          backgroundColor: Colors.red.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
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
            "avatarUrl": userData['avatarUrl'] ?? '',
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
        Get.snackbar(
          "Thành công",
          "Đã rời khỏi nhóm $groupName thành công!",
          backgroundColor: Colors.blue.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      print('Error leaving group: $e');
      if (mounted) {
        Get.snackbar(
          "Lỗi",
          "Không thể rời khỏi nhóm $groupName.",
          backgroundColor: Colors.blue.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
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
        Get.snackbar(
          "Thành công",
          "Hủy yêu cầu tham gia nhóm thành công.",
          backgroundColor: Colors.blue.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
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
        Get.snackbar(
          "Lỗi",
          "Không thể xem trước nhóm",
          backgroundColor: Colors.red.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
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
        Get.snackbar(
          "Lỗi",
          "Không thể xem trước nhóm ",
          backgroundColor: Colors.blue.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      }
    }
  }

  Widget buildJoinedGroupCard(bool isDarkMode, Map<String, dynamic> group) {
    //final isAdmin = group['isAdmin'] ?? false;
    final currentUser = _auth.currentUser;
    final isCreator =
        currentUser != null && group['createdBy'] == currentUser.uid;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppBackgroundStyles.buttonBackground(isDarkMode),
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
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTextStyles.normalTextColor(isDarkMode),
                ),
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
          style: TextStyle(color: AppTextStyles.subTextColor(isDarkMode)),
        ),
        trailing: IconButton(
          icon: Icon(
            isCreator ? Icons.settings : Icons.more_vert,
            color: isCreator
                ? AppIconStyles.iconPrimary(isDarkMode)
                : AppIconStyles.iconPrimary(isDarkMode),
          ),
          onPressed: () async {
            if (isCreator) {
              // Hiển thị bottom sheet tùy chọn quản lý nhóm
              final List<BottomSheetOption> options = [
                BottomSheetOption(
                  icon: Icons.settings,
                  text: 'Quản lý nhóm',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GroupManagementPage(
                          groupId: group['id'],
                        ),
                      ),
                    );
                  },
                ),
                BottomSheetOption(
                  icon: Icons.groups_outlined,
                  text: 'Quản lý thành viên',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ManageGroupMembersScreen(
                          groupId: group['id'],
                          groupName: group['name'],
                        ),
                      ),
                    );
                  },
                ),
                BottomSheetOption(
                  icon: Icons.rate_review_outlined,
                  text: 'Duyệt bài đăng',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ManagePendingPostsScreen(
                          groupId: group['id'],
                          groupName: group['name'],
                        ),
                      ),
                    );
                  },
                ),
                BottomSheetOption(
                  icon: Icons.checklist_rtl_rounded,
                  text: 'Duyệt yêu cầu tham gia',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ManageJoinRequestsScreen(
                          groupId: group['id'],
                          groupName: group['name'],
                        ),
                      ),
                    );
                  },
                ),
                BottomSheetOption(
                  icon: Icons.delete_forever,
                  text: 'Xóa nhóm',
                  onTap: () async {
                    Navigator.pop(context);
                    final confirm = await showConfirmModal(
                      title: 'Xác nhận xóa nhóm',
                      content:
                      'Bạn có chắc chắn muốn xóa vĩnh viễn nhóm "${group['name']}" không?',
                      cancelText: 'Hủy',
                      confirmText: 'Xóa',
                      context: context,
                      isDarkMode: isDarkMode,
                    );
                    if (confirm == true) {
                      await FirebaseFirestore.instance
                          .collection('communityGroups')
                          .doc(group['id'])
                          .delete();

                      Get.snackbar(
                        'Thành công',
                        'Đã xóa nhóm "${group['name']}"',
                        backgroundColor: Colors.blue,
                        colorText: Colors.white,
                        duration: const Duration(seconds: 3),
                      );

                      setState(() {
                        joinedGroups.removeWhere((g) => g['id'] == group['id']);
                        filteredJoinedGroups.removeWhere((g) => g['id'] == group['id']);
                      });
                    }
                  },
                ),
              ];

              showCustomBottomSheet(
                context: context,
                isDarkMode: isDarkMode,
                options: options,
              );
            } else {
              // Không phải creator → Hiển thị bottom sheet: Rời nhóm / Báo cáo nhóm
              final List<BottomSheetOption> options = [
                BottomSheetOption(
                  icon: Icons.flag_outlined,
                  text: 'Báo cáo nhóm',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReportGroupPage(
                          groupId: group['id'],
                          groupName: group['name'],
                        ),
                      ),
                    );
                  },
                ),
                BottomSheetOption(
                  icon: Icons.exit_to_app,
                  text: 'Rời khỏi nhóm',
                  onTap: () async {
                    Navigator.pop(context);
                    final result = await showConfirmModal(
                      title: 'Rời nhóm',
                      content: 'Bạn có chắc muốn rời khỏi nhóm "${group['name']}"?',
                      cancelText: 'Hủy',
                      confirmText: 'Rời nhóm',
                      context: context,
                      isDarkMode: isDarkMode,
                    );
                    if (result == true) {
                      _leaveGroup(group['id'], group['name']);
                    }
                  },
                ),
              ];

              showCustomBottomSheet(
                context: context,
                isDarkMode: isDarkMode,
                options: options,
              );
            }
          },
        ),
        onTap: null,
      ),
    );
  }

  Widget buildAvailableGroupCard(bool isDarkMode, Map<String, dynamic> group) {
    final isPrivate = group['privacy'] == 'Riêng tư';
    final hasPendingRequest = pendingRequests.contains(group['id']);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppBackgroundStyles.secondaryBackground(isDarkMode),
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
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTextStyles.normalTextColor(isDarkMode),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${group['membersCount']} thành viên',
                      style: TextStyle(
                        color: AppTextStyles.subTextColor(isDarkMode),
                      ),
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
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(
                  hasPendingRequest
                      ? AppBackgroundStyles.buttonBackgroundSecondary(
                        isDarkMode,
                      )
                      : (isPrivate
                          ? AppBackgroundStyles.mainBackground(isDarkMode)
                          : AppBackgroundStyles.modalBackground(isDarkMode)),
                ),
                foregroundColor: WidgetStateProperty.all(
                  AppTextStyles.buttonTextColor(isDarkMode),
                ),
                overlayColor: WidgetStateProperty.all(
                  Colors.black.withOpacity(0.1),
                ), // ✅ hiệu ứng bấm
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                elevation: WidgetStateProperty.all(0),
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(vertical: 12),
                ),
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
                  color: AppTextStyles.subTextColor(isDarkMode),
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
                  color: AppTextStyles.subTextColor(isDarkMode),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
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

    _loadAvailableGroups();
    _loadJoinedGroups();
    return Scaffold(
      backgroundColor: AppBackgroundStyles.mainBackground(isDarkMode),
      appBar: AppBar(
        backgroundColor: AppBackgroundStyles.secondaryBackground(isDarkMode),
        elevation: 0,
        leading: BackButton(color: AppIconStyles.iconPrimary(isDarkMode)),
        title: Text(
          'Nhóm',
          style: TextStyle(
            color: AppTextStyles.normalTextColor(isDarkMode),
            fontWeight: FontWeight.bold,
            fontSize: 25,
          ),
        ),
        centerTitle: true,
        actions: [
          // Nút xem lời mời tham gia nhóm
          IconButton(
            icon: Icon(
              Icons.notifications,
              color: AppIconStyles.iconPrimary(isDarkMode),
            ),
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
            icon: Icon(
              Icons.add_circle_outline,
              color: AppIconStyles.iconPrimary(isDarkMode),
            ),
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
          labelColor: AppTextStyles.buttonTextColor(isDarkMode),
          unselectedLabelColor: AppTextStyles.buttonTextColor(isDarkMode),
          indicatorColor: AppTextStyles.buttonTextColor(isDarkMode),
          labelStyle: TextStyle(
            fontSize: 22, // Chữ khi được chọn
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: 20, // Chữ khi KHÔNG được chọn
            fontWeight: FontWeight.normal,
          ),
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
                    style: TextStyle(
                      color: AppTextStyles.normalTextColor(isDarkMode),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm nhóm đã tham gia',
                      hintStyle: TextStyle(
                        color: AppTextStyles.normalTextColor(
                          isDarkMode,
                        ).withOpacity(0.5),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: AppIconStyles.iconPrimary(isDarkMode),
                      ),
                      filled: true,
                      fillColor: AppBackgroundStyles.buttonBackgroundSecondary(
                        isDarkMode,
                      ),
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
                            ? Center(
                              child: Text(
                                'Chưa tham gia nhóm nào',
                                style: TextStyle(
                                  color: AppTextStyles.normalTextColor(
                                    isDarkMode,
                                  ),
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
                                    isDarkMode,
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
                    style: TextStyle(
                      color: AppTextStyles.normalTextColor(isDarkMode),
                    ),
                    controller: _availableSearchController,
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm nhóm để tham gia',
                      hintStyle: TextStyle(
                        color: AppTextStyles.normalTextColor(
                          isDarkMode,
                        ).withOpacity(0.5),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: AppIconStyles.iconPrimary(isDarkMode),
                      ),
                      filled: true,
                      fillColor: AppBackgroundStyles.buttonBackgroundSecondary(
                        isDarkMode,
                      ),
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
                            ? Center(
                              child: Text(
                                'Không có nhóm nào để tham gia',
                                style: TextStyle(
                                  color: AppTextStyles.subTextColor(isDarkMode),
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
                                    isDarkMode,
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
