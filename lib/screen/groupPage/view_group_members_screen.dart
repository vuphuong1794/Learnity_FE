import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../../api/group_api.dart';

import 'package:provider/provider.dart';
import 'package:learnity/theme/theme.dart';
import 'package:learnity/theme/theme_provider.dart';

class ViewGroupMembersScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const ViewGroupMembersScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<ViewGroupMembersScreen> createState() =>
      _ViewGroupMembersScreenState();
}

class _ViewGroupMembersScreenState extends State<ViewGroupMembersScreen> {
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
    setState(() => _isLoading = true);
    try {
      final rawMembers = await _groupApi.getGroupMembers(widget.groupId);

      // Lấy thông tin chi tiết từ collection 'users'
      final firestore = FirebaseFirestore.instance;
      final usersCollection = firestore.collection('users');
      final List<Map<String, dynamic>> fullMembersData = [];

      for (final m in rawMembers) {
        final uid = m['uid'];
        if (uid != null) {
          final userDoc = await usersCollection.doc(uid).get();
          final userData = userDoc.data();
          if (userData != null) {
            fullMembersData.add({
              'uid': uid,
              'username': userData['username'] ?? 'Không tên',
              'avatarUrl': userData['avatarUrl'] ?? '',
              'isAdmin': m['isAdmin'] ?? false,
            });
          } else {
            fullMembersData.add({
              'uid': uid,
              'username': 'Không rõ',
              'avatarUrl': '',
              'isAdmin': m['isAdmin'] ?? false,
            });
          }
        }
      }

      fullMembersData.sort(_sortMembers);

      if (mounted) {
        setState(() {
          _members = fullMembersData;
          _filteredMembers = fullMembersData;
          _currentUserId = FirebaseAuth.instance.currentUser?.uid;
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
                      backgroundColor: Colors.teal,
                      child:
                      (m['avatarUrl'] == null ||
                          m['avatarUrl'].toString().isEmpty)
                          ? const Icon(
                        Icons.person,
                        color: Colors.white,
                      )
                          : null,
                    ),
                    title: Text(m['username'] ?? ' ', style: TextStyle(color: AppTextStyles.normalTextColor(isDarkMode))),
                    subtitle: Text(isAdmin ? 'Admin' : 'Thành viên', style: TextStyle(color: AppTextStyles.normalTextColor(isDarkMode))),
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
