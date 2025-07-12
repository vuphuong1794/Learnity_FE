import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:learnity/models/user_info_model.dart';
import 'package:learnity/screen/adminPage/common/appbar.dart';
import 'package:learnity/screen/adminPage/common/sidebar.dart';
import 'package:learnity/services/user_service.dart';
import 'package:http/http.dart' as http;

class Accountmanager extends StatefulWidget {
  const Accountmanager({super.key});

  @override
  State<Accountmanager> createState() => _AccountmanagerState();
}

class _AccountmanagerState extends State<Accountmanager> {
  bool _isLoading = false;
  List<UserInfoModel> allUsers = [];
  List<UserInfoModel> filteredUsers = [];
  TextEditingController searchController = TextEditingController();

  DocumentSnapshot? lastDocument;
  bool isLoadingMore = false;
  bool hasMore = true;
  int pageSize = 30;

  @override
  void initState() {
    super.initState();
    _loadAllUsers();
  }

  Future<void> _loadAllUsers() async {
    if (isLoadingMore || !hasMore) return;

    setState(() {
      isLoadingMore = true;
    });

    Query query = FirebaseFirestore.instance
        .collection('users')
        .orderBy('displayName')
        .limit(pageSize);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument!);
    }

    try {
      final snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        lastDocument = snapshot.docs.last;

        List<UserInfoModel> newUsers = [];

        for (var doc in snapshot.docs) {
          final data = doc.data();
          if (data != null && data is Map<String, dynamic>) {
            newUsers.add(
              UserInfoModel(
                uid: doc.id,
                username: data['username'] ?? '',
                displayName: data['displayName'] ?? '',
                avatarUrl: data['avatarUrl'] ?? '',
                email: data['email'] ?? '',
              ),
            );
          }
        }

        setState(() {
          allUsers.addAll(newUsers);
          filteredUsers = List.from(allUsers);
        });

        if (snapshot.docs.length < pageSize) {
          hasMore = false;
        }
      } else {
        hasMore = false;
      }
    } catch (e) {
      debugPrint('Lỗi khi tải danh sách người dùng: $e');
    }

    setState(() {
      isLoadingMore = false;
    });
  }

  void _filterUsers(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredUsers = List.from(allUsers);
      } else {
        filteredUsers =
            allUsers
                .where(
                  (user) =>
                      user.displayName!.toLowerCase().contains(
                        query.toLowerCase(),
                      ) ||
                      user.username!.toLowerCase().contains(
                        query.toLowerCase(),
                      ),
                )
                .toList();
      }
    });
  }

  void _showUserOptions(BuildContext context, UserInfoModel user) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.edit, color: Colors.blue),
                title: Text('Chỉnh sửa tài khoản'),
                onTap: () {
                  Navigator.pop(context);
                  _editUser(user);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Xóa tài khoản'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteUser(user);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _editUser(UserInfoModel user) {
    // Implement edit user functionality
    showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController nameController = TextEditingController(
          text: user.displayName,
        );
        TextEditingController usernameController = TextEditingController(
          text: user.username,
        );

        return AlertDialog(
          title: Text('Chỉnh sửa tài khoản'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Tên hiển thị',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: usernameController,
                decoration: InputDecoration(
                  labelText: 'Tên người dùng',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .update({
                        'displayName': nameController.text,
                        'username': usernameController.text,
                      });
                  Navigator.pop(context);
                  _loadAllUsers();
                  Get.snackbar(
                    "Thành công",
                    "Cập nhật trang cá nhân thành công!",
                    backgroundColor: Colors.blue.withOpacity(0.9),
                    colorText: Colors.white,
                    duration: const Duration(seconds: 4),
                  );
                } catch (e) {
                  Get.snackbar(
                    "Lỗi",
                    "Không thể cập nhật trang cá nhân: $e",
                    backgroundColor: Colors.red.withOpacity(0.9),
                    colorText: Colors.white,
                    duration: const Duration(seconds: 4),
                  );
                }
              },
              child: Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteUser(UserInfoModel user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Xác nhận xóa'),
          content: Text(
            'Bạn có chắc chắn muốn xóa tài khoản "${user.displayName}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                try {
                  const String apiBaseUrl = 'https://learnity-be.onrender.com';

                  final response = await http.delete(
                    Uri.parse('$apiBaseUrl/auth/user/${user.uid}'),
                  );

                  if (response.statusCode == 200) {
                    Navigator.pop(context);
                    _loadAllUsers();
                    Get.snackbar(
                      "Thành công",
                      "Xóa tài khoản thành công!",
                      backgroundColor: Colors.blue.withOpacity(0.9),
                      colorText: Colors.white,
                      duration: const Duration(seconds: 4),
                    );
                  } else {
                    Get.snackbar(
                      "Lỗi",
                      "Không thể xóa tài khoản: ${response.body}",
                      backgroundColor: Colors.red.withOpacity(0.9),
                      colorText: Colors.white,
                      duration: const Duration(seconds: 4),
                    );
                  }
                } catch (e) {
                  Get.snackbar(
                    "Lỗi",
                    "Lỗi khi kết nối đến server: $e",
                    backgroundColor: Colors.red.withOpacity(0.9),
                    colorText: Colors.white,
                    duration: const Duration(seconds: 4),
                  );
                }
              },
              child: Text('Xóa'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE8F5E8),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: CustomAppBar(),
      ),
      drawer: Sidebar(),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // Header với tiêu đề
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Color(0xFF90C695)),
                    child: Text(
                      'Quản lí tài khoản',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Thanh tìm kiếm
                  Container(
                    margin: EdgeInsets.all(16),
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: searchController,
                      onChanged: _filterUsers,
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm...',
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                      ),
                    ),
                  ),

                  // Bảng dữ liệu
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Container(
                        width: 1000,
                        margin: EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Header bảng
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Color(0xFF5A7A5F),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      'ID',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'Tên',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      'Email',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  // Expanded(
                                  //   flex: 2,
                                  //   child: Text(
                                  //     'Số điện thoại',
                                  //     style: TextStyle(
                                  //       color: Colors.white,
                                  //       fontWeight: FontWeight.bold,
                                  //     ),
                                  //   ),
                                  // ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'Ngày tạo',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      'Chức năng',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Danh sách người dùng
                            Expanded(
                              child:
                                  filteredUsers.isEmpty
                                      ? Center(child: Text('Không có dữ liệu'))
                                      : ListView.builder(
                                        itemCount: filteredUsers.length,
                                        itemBuilder: (context, index) {
                                          final user = filteredUsers[index];
                                          final isEven = index % 2 == 0;

                                          return Container(
                                            padding: EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color:
                                                  isEven
                                                      ? Colors.grey[50]
                                                      : Colors.white,
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  flex: 1,
                                                  child: Text('${index + 1}'),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Text(
                                                    user.displayName ??
                                                        'Chưa cá nhân',
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 3,
                                                  child: Text(
                                                    user.email ??
                                                        'Chưa có email',
                                                  ),
                                                ),
                                                // Expanded(
                                                //   flex: 2,
                                                //   child: Text('0783203982'),
                                                // ), // Placeholder số điện thoại
                                                Expanded(
                                                  flex: 2,
                                                  child: Text('2025-01-19'),
                                                ), // Placeholder ngày tạo
                                                Expanded(
                                                  flex: 1,
                                                  child: Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                          vertical: 6,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Color(0xFFB8D4BA),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            15,
                                                          ),
                                                    ),
                                                    child: InkWell(
                                                      onTap:
                                                          () =>
                                                              _showUserOptions(
                                                                context,
                                                                user,
                                                              ),
                                                      child: Text(
                                                        '...',
                                                        style: TextStyle(
                                                          color: Colors.black,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 16,
                                                        ),
                                                        textAlign:
                                                            TextAlign.center,
                                                      ),
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
                    ),
                  ),
                  SizedBox(height: 16),
                ],
              ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
