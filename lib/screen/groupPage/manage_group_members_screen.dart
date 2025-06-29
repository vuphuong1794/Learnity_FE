import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../../api/group_api.dart';

import 'package:provider/provider.dart';
import 'package:learnity/theme/theme.dart';
import 'package:learnity/theme/theme_provider.dart';

class ManageGroupMembersScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const ManageGroupMembersScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<ManageGroupMembersScreen> createState() =>
      _ManageGroupMembersScreenState();
}

class _ManageGroupMembersScreenState extends State<ManageGroupMembersScreen> {
  final GroupApi _groupApi = GroupApi();

  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _filteredMembers = [];
  final Set<String> _processingUids = {};
  String? _currentUserId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    if (!_isLoading) setState(() => _isLoading = true);

    try {
      final members = await _groupApi.getGroupMembers(widget.groupId);
      members.sort(_sortMembers);
      if (mounted) {
        setState(() {
          _members = members;
          _filteredMembers = members;
        });
      }
    } catch (e) {
      Get.snackbar("Lỗi", "Không thể tải danh sách thành viên.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int _sortMembers(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a['isAdmin'] == true && b['isAdmin'] != true) return -1;
    if (a['isAdmin'] != true && b['isAdmin'] == true) return 1;
    return (a['username'] ?? '').compareTo(b['username'] ?? '');
  }

  int _adminCount() => _members.where((m) => m['isAdmin'] == true).length;

  // thay đổi quyền
  Future<void> _toggleAdmin(bool isDarkMode, Map<String, dynamic> member) async {
    final uid = member['uid'];
    final isAdmin = member['isAdmin'] == true;
    final username = member['username'] ?? '';

    if (_processingUids.contains(uid)) return;
    if (uid == _currentUserId && isAdmin && _adminCount() <= 1) {
      Get.snackbar("Lỗi", "Không thể hủy quyền admin cuối cùng.");
      return;
    }
    final confirm = await _showConfirm(
      isDarkMode,
      'Bạn có chắc muốn ${isAdmin ? 'hủy quyền admin của' : 'cấp quyền admin cho'} $username không?',
    );
    if (confirm != true) return;

    setState(() => _processingUids.add(uid));
    final success = await _groupApi.toggleMemberAdminStatus(
      widget.groupId,
      uid,
      isAdmin,
    );
    if (mounted) {
      if (success) {
        await _loadMembers();
        Get.snackbar(
          "Thành công",
          "${isAdmin ? 'Hủy quyền' : 'Cấp quyền'} admin cho $username",
        );
      } else {
        Get.snackbar("Lỗi", "Thao tác thất bại. Vui lòng thử lại.");
      }
      setState(() => _processingUids.remove(uid));
    }
  }

  // xóa thành viên
  Future<void> _removeMember(bool isDarkMode, Map<String, dynamic> member) async {
    final uid = member['uid'];
    final username = member['username'] ?? 'Người dùng';
    if (_processingUids.contains(uid)) return;
    if (member['isAdmin'] == true && _adminCount() <= 1) {
      Get.snackbar("Lỗi", "Không thể xóa admin cuối cùng.");
      return;
    }
    final confirm = await _showConfirm(isDarkMode, 'Xóa $username khỏi nhóm?');
    if (confirm != true) return;

    setState(() => _processingUids.add(uid));

    // Gọi API
    final success = await _groupApi.removeMemberFromGroup(widget.groupId, uid);

    if (mounted) {
      if (success) {
        await _loadMembers();
        Get.snackbar("Thành công", "Đã xóa $username khỏi nhóm.");
      } else {
        Get.snackbar("Lỗi", "Không thể xóa thành viên. Vui lòng thử lại.");
      }
      setState(() => _processingUids.remove(uid));
    }
  }

  Future<bool?> _showConfirm(bool isDarkMode, String message) {
    return Get.dialog<bool>(
      AlertDialog(
        backgroundColor: AppBackgroundStyles.modalBackground(isDarkMode),
        title: Text(
          "Xác nhận",
          style: TextStyle(color: AppTextStyles.normalTextColor(isDarkMode), fontSize: 28, fontWeight: FontWeight.bold),
        ),
        content: Text(message, style: TextStyle(color: AppTextStyles.normalTextColor(isDarkMode))),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text("Hủy", style: TextStyle(color: AppTextStyles.subTextColor(isDarkMode))),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: Text("Xác nhận"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppBackgroundStyles.buttonBackground(isDarkMode),
              foregroundColor: AppTextStyles.buttonTextColor(isDarkMode),
            ),
          ),
        ],
      ),
    );
  }

  void _filterUsers(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      if (lowerQuery.isEmpty) {
        _filteredMembers = _members;
      } else {
        _filteredMembers =
            _members.where((m) {
              final name = (m['username'] ?? '').toLowerCase();
              return name.contains(lowerQuery);
            }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: AppBackgroundStyles.mainBackground(isDarkMode),
      appBar: AppBar(
        title: Text(
          "Thành viên nhóm",
          style: TextStyle(fontSize: 31, fontWeight: FontWeight.bold, color: AppTextStyles.normalTextColor(isDarkMode)),
        ),
        centerTitle: true,
        backgroundColor: AppBackgroundStyles.secondaryBackground(isDarkMode),
        iconTheme: IconThemeData(
          color: AppIconStyles.iconPrimary(isDarkMode), // Đổi màu mũi tên tại đây
        ),
        elevation: 0,
        // leading: IconButton(
        //   onPressed: () => Navigator.pop(context,true),
        //   icon: const Icon(Icons.arrow_back),
        // ),
      ),
      body: Container(
        // color: AppColors.background,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              onChanged: _filterUsers,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                prefixIconColor: AppIconStyles.iconPrimary(isDarkMode),
                hintText: 'Tìm kiếm',
                hintStyle: TextStyle(
                  color: AppTextStyles.normalTextColor(isDarkMode).withOpacity(0.5),
                ),
                filled: true,
                fillColor: AppBackgroundStyles.buttonBackgroundSecondary(isDarkMode),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                        itemCount: _filteredMembers.length,
                        itemBuilder: (context, index) {
                          final m = _filteredMembers[index];
                          final uid = m['uid'];
                          final isSelf = uid == _currentUserId;
                          final isAdmin = m['isAdmin'] == true;
                          final isProcessing = _processingUids.contains(uid);

                          return ListTile(
                            leading: CircleAvatar(
                              radius: 22,
                              backgroundImage:
                                  m['avatarUrl'] != null &&
                                          m['avatarUrl'].toString().isNotEmpty
                                      ? NetworkImage(m['avatarUrl'])
                                      : null,
                              child:
                                  (m['avatarUrl'] == null ||
                                          m['avatarUrl'].toString().isEmpty)
                                      ? const Icon(
                                        Icons.person,
                                        color: Colors.white,
                                      )
                                      : null,
                              backgroundColor: Colors.teal,
                            ),
                            title: Text(m['username'] ?? ' ', style: TextStyle(color: AppTextStyles.normalTextColor(isDarkMode))),
                            subtitle: Text(isAdmin ? 'Admin' : 'Thành viên', style: TextStyle(color: AppTextStyles.normalTextColor(isDarkMode))),
                            trailing:
                                isProcessing
                                    ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : PopupMenuButton<String>(
                                        color: AppBackgroundStyles.modalBackground(isDarkMode),
                                        iconColor: AppIconStyles.iconPrimary(isDarkMode),
                                        onSelected: (value) {
                                          if (value == 'toggle_admin')
                                            _toggleAdmin(isDarkMode, m);
                                          if (value == 'remove') _removeMember(isDarkMode, m);
                                        },
                                        itemBuilder:
                                            (_) => [
                                              if (!isSelf ||
                                                  (isSelf &&
                                                      isAdmin &&
                                                      _adminCount() > 1))
                                                PopupMenuItem(
                                                  value: 'toggle_admin',
                                                  child: Text(
                                                    isAdmin
                                                        ? 'Hủy quyền Admin'
                                                        : 'Cấp quyền Admin',
                                                    style: TextStyle(
                                                      color: AppTextStyles.buttonTextColor(isDarkMode),
                                                    ),
                                                  ),
                                                ),
                                              if (!isSelf &&
                                                  !(isAdmin &&
                                                      _adminCount() <= 1))
                                                const PopupMenuItem(
                                                  value: 'remove',
                                                  child: Text(
                                                    'Xóa khỏi nhóm',
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                    ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
