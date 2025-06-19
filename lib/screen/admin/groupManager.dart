import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:learnity/screen/admin/common/appbar.dart';
import 'package:learnity/screen/admin/common/sidebar.dart';
import 'package:learnity/screen/Group/group_content_screen.dart'; // Import GroupContentScreen

class Groupmanager extends StatefulWidget {
  const Groupmanager({super.key});

  @override
  State<Groupmanager> createState() => _GroupmanagerState();
}

class _GroupmanagerState extends State<Groupmanager> {
  final TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> groups = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedTab = "Tất cả";

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('communityGroups').get();

      final loadedGroups =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': data['id'] ?? doc.id,
              'name': data['name'] ?? 'Không tên',
              'description': 'Nhóm cộng đồng',
              'members': data['membersCount'] ?? 0,
              'status': data['status'] == 'active' ? 'Hoạt động' : 'Đã khóa',
              'avatarUrl': data['avatarUrl'] ?? '',
              'privacy': data['privacy'] ?? 'Công khai',
              'createdBy': data['createdBy'] ?? '',
              'createdAt': data['createdAt'] ?? Timestamp.now(),
            };
          }).toList();

      setState(() {
        groups = loadedGroups;
        _isLoading = false;
      });
    } catch (e) {
      print('Lỗi khi lấy dữ liệu nhóm: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterUsers(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _changeTab(String tab) {
    setState(() {
      _selectedTab = tab;
    });
  }

  List<Map<String, dynamic>> get filteredGroups {
    return groups.where((group) {
      final matchesTab =
          _selectedTab == "Tất cả" || group["status"] == _selectedTab;
      final matchesSearch = group["name"].toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      return matchesTab && matchesSearch;
    }).toList();
  }

  // Thêm chức năng xem trước nhóm cho admin
  Future<void> _previewGroupAsAdmin(
    String groupId,
    Map<String, dynamic> groupData,
  ) async {
    try {
      // Điều hướng đến trang GroupContentScreen với isPreviewMode = true (admin mode)
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => GroupcontentScreen(
                groupId: groupId,
                groupName: groupData['name'],
                isPreviewMode: true, // Admin có thể xem nhóm ở chế độ preview
                isAdminView:
                    true, // Thêm flag để phân biệt admin view (nếu cần)
              ),
        ),
      );
    } catch (e) {
      print('Error previewing group as admin: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E8),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: CustomAppBar(),
      ),
      drawer: Sidebar(),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(color: Color(0xFF90C695)),
                    child: const Text(
                      'Quản lý nhóm ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Search bar
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: searchController,
                      onChanged: _filterUsers,
                      decoration: const InputDecoration(
                        hintText: 'Tìm kiếm...',
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                      ),
                    ),
                  ),

                  // Tabs
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children:
                          ["Tất cả", "Hoạt động", "Đã khóa"].map((tab) {
                            final isSelected = _selectedTab == tab;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => _changeTab(tab),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isSelected
                                            ? Colors.white
                                            : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    tab,
                                    style: TextStyle(
                                      color:
                                          isSelected
                                              ? Colors.black
                                              : Colors.grey,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Danh sách nhóm
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredGroups.length,
                      itemBuilder: (context, index) {
                        final group = filteredGroups[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            // Thêm InkWell để có thể tap vào card để xem trước
                            onTap:
                                () => _previewGroupAsAdmin(group['id'], group),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Avatar và thông tin nhóm
                                  Row(
                                    children: [
                                      // Avatar nhóm
                                      CircleAvatar(
                                        radius: 25,
                                        backgroundImage:
                                            group['avatarUrl'].isNotEmpty
                                                ? NetworkImage(
                                                  group['avatarUrl'],
                                                )
                                                : const AssetImage(
                                                      'assets/group_avatar.png',
                                                    )
                                                    as ImageProvider,
                                      ),
                                      const SizedBox(width: 12),
                                      // Thông tin nhóm
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Tiêu đề và trạng thái
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    group['name'],
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        group["status"] ==
                                                                "Hoạt động"
                                                            ? Colors.green[100]
                                                            : Colors.red[100],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    group['status'],
                                                    style: TextStyle(
                                                      color:
                                                          group["status"] ==
                                                                  "Hoạt động"
                                                              ? Colors.green
                                                              : Colors.red,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              group['description'],
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 14,
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                Text(
                                                  'Thành viên: ${group['members']}',
                                                  style: TextStyle(
                                                    color: Colors.grey[700],
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        group['privacy'] ==
                                                                'Công khai'
                                                            ? Colors.green
                                                                .withOpacity(
                                                                  0.1,
                                                                )
                                                            : Colors.orange
                                                                .withOpacity(
                                                                  0.1,
                                                                ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    group['privacy'],
                                                    style: TextStyle(
                                                      color:
                                                          group['privacy'] ==
                                                                  'Công khai'
                                                              ? Colors
                                                                  .green
                                                                  .shade700
                                                              : Colors
                                                                  .orange
                                                                  .shade700,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),

                                  // Hint cho người dùng biết có thể tap để xem
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.visibility,
                                          size: 16,
                                          color: Colors.blue.shade700,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Nhấn vào để xem trước nội dung nhóm',
                                          style: TextStyle(
                                            color: Colors.blue.shade700,
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  // Buttons row
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () async {
                                          try {
                                            if (group['status'] ==
                                                'Hoạt động') {
                                              // Change status to inactive
                                              await FirebaseFirestore.instance
                                                  .collection('communityGroups')
                                                  .doc(group['id'])
                                                  .update({
                                                    'status': 'inactive',
                                                  });
                                            } else {
                                              // Change status to active
                                              await FirebaseFirestore.instance
                                                  .collection('communityGroups')
                                                  .doc(group['id'])
                                                  .update({'status': 'active'});
                                            }
                                            await _loadGroups();
                                          } catch (e) {
                                            print('Lỗi khi khóa nhóm: $e');
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Không thể khóa nhóm',
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.grey[300],
                                          foregroundColor: Colors.black,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                        ),
                                        child: Text(
                                          group['status'] == 'Hoạt động'
                                              ? "Khóa nhóm"
                                              : "Mở khóa",
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () async {
                                          final confirm = await showDialog<
                                            bool
                                          >(
                                            context: context,
                                            builder:
                                                (context) => AlertDialog(
                                                  title: const Text('Xác nhận'),
                                                  content: const Text(
                                                    'Bạn có chắc muốn xóa nhóm này? Hành động này không thể hoàn tác.',
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed:
                                                          () => Navigator.pop(
                                                            context,
                                                            false,
                                                          ),
                                                      child: const Text('Hủy'),
                                                    ),
                                                    TextButton(
                                                      onPressed:
                                                          () => Navigator.pop(
                                                            context,
                                                            true,
                                                          ),
                                                      child: const Text(
                                                        'Xóa',
                                                        style: TextStyle(
                                                          color: Colors.red,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                          );

                                          if (confirm == true) {
                                            try {
                                              await FirebaseFirestore.instance
                                                  .collection('communityGroups')
                                                  .doc(group['id'])
                                                  .delete();

                                              // Reload danh sách nhóm
                                              await _loadGroups();

                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Nhóm đã được xóa thành công',
                                                  ),
                                                ),
                                              );
                                            } catch (e) {
                                              print('Lỗi khi xóa nhóm: $e');
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Không thể xóa nhóm',
                                                  ),
                                                ),
                                              );
                                            }
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red[300],
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                        ),
                                        child: const Text("Xóa"),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
    );
  }
}
