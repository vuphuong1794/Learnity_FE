import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:learnity/api/notification_api.dart';

import 'package:provider/provider.dart';
import 'package:learnity/theme/theme.dart';
import 'package:learnity/theme/theme_provider.dart';

class InviteMemberPage extends StatefulWidget {
  final String groupId;
  final String groupName;
  final List<String> userFollowers;

  const InviteMemberPage({
    Key? key,
    required this.groupId,
    required this.groupName,
    required this.userFollowers,
  }) : super(key: key);

  @override
  State<InviteMemberPage> createState() => _InviteMemberPageState();
}

class _InviteMemberPageState extends State<InviteMemberPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> _followers = [];
  List<String> _selectedMembers = [];
  List<String> _existingMembers = [];
  List<String> _invitedMembers = []; // Danh sách những người đã được mời
  bool _isLoading = true;
  bool _isInviting = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadFollowersData();
    _loadExistingMembers();
    _loadInvitedMembers(); // Tải danh sách người đã được mời
  }

  Future<void> _loadFollowersData() async {
    try {
      List<Map<String, dynamic>> followers = [];
      for (String followerId in widget.userFollowers) {
        final userDoc =
            await _firestore.collection('users').doc(followerId).get();

        if (userDoc.exists) {
          final userData = userDoc.data()!;
          String name =
              userData['displayName'] ?? userData['name'] ?? 'Unknown User';
          String email = userData['email'] ?? '';
          String avatar =
              userData['avatarUrl'] ??
              userData['avatar'] ??
              userData['photoURL'] ??
              '';

          followers.add({
            'id': followerId,
            'name': name,
            'email': email,
            'avatar': avatar,
          });
        } else {
          print('DEBUG: User không tồn tại: $followerId');
        }
      }

      setState(() {
        _followers = followers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Get.snackbar('Lỗi', 'Không thể tải danh sách followers: $e');
    }
  }

  Future<void> _loadExistingMembers() async {
    try {
      final groupDoc =
          await _firestore.collection('groups').doc(widget.groupId).get();

      if (groupDoc.exists) {
        final groupData = groupDoc.data()!;
        setState(() {
          _existingMembers = List<String>.from(groupData['members'] ?? []);
        });
      }
    } catch (e) {
      print('Error loading existing members: $e');
    }
  }

  // Tải danh sách những người đã được mời vào nhóm này
  Future<void> _loadInvitedMembers() async {
    try {
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      if (currentUid == null) return;

      final inviteQuery =
          await _firestore
              .collection('invite_member_notifications')
              .where('senderId', isEqualTo: currentUid)
              .where('groupId', isEqualTo: widget.groupId)
              .where(
                'isRead',
                isEqualTo: false,
              ) // Chỉ lấy những lời mời chưa được xử lý
              .get();

      setState(() {
        _invitedMembers =
            inviteQuery.docs
                .map((doc) => doc.data()['receiverId'] as String)
                .toList();
      });
    } catch (e) {
      print('Error loading invited members: $e');
    }
  }

  Future<void> _inviteSelectedMembers() async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return;

    final senderSnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUid)
            .get();

    final senderData = senderSnapshot.data();
    final senderName =
        senderData?['displayName'] ?? senderData?['username'] ?? 'Người dùng';

    if (_selectedMembers.isEmpty) {
      Get.snackbar('Thông báo', 'Vui lòng chọn ít nhất một người để mời');
      return;
    }

    setState(() {
      _isInviting = true;
    });

    try {
      // Kiểm tra từng thành viên được chọn
      List<String> membersToInvite = [];
      List<String> alreadyInvitedMembers = [];

      for (String memberId in _selectedMembers) {
        // Kiểm tra xem đã có lời mời cho thành viên này chưa
        final existingInvite =
            await _firestore
                .collection('invite_member_notifications')
                .where('senderId', isEqualTo: currentUid)
                .where('receiverId', isEqualTo: memberId)
                .where('groupId', isEqualTo: widget.groupId)
                .where('isRead', isEqualTo: false)
                .get();

        if (existingInvite.docs.isEmpty) {
          membersToInvite.add(memberId);
        } else {
          // Lấy tên của thành viên đã được mời
          final userDoc =
              await _firestore.collection('users').doc(memberId).get();
          final userName =
              userDoc.data()?['displayName'] ??
              userDoc.data()?['name'] ??
              'Unknown User';
          alreadyInvitedMembers.add(userName);
        }
      }

      // Nếu có thành viên đã được mời, thông báo cho người dùng
      if (alreadyInvitedMembers.isNotEmpty) {
        Get.snackbar(
          'Thông báo',
          'Những người sau đã được mời trước đó: ${alreadyInvitedMembers.join(', ')}',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      }

      // Cập nhật UI ngay lập tức - thêm vào danh sách invited
      setState(() {
        _invitedMembers.addAll(membersToInvite);
        _selectedMembers.clear(); // Clear selection
        _isInviting = false; // Tắt loading ngay
      });

      // Hiển thị thông báo thành công ngay lập tức
      if (membersToInvite.isNotEmpty) {
        Get.snackbar(
          'Thành công',
          'Đã gửi lời mời cho ${membersToInvite.length} thành viên',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Thông báo',
          'Tất cả thành viên đã được mời trước đó',
          backgroundColor: Colors.blue,
          colorText: Colors.white,
        );
      }

      // Gửi notifications trong background (không chờ kết quả)
      _sendNotificationsInBackground(membersToInvite, currentUid, senderName);

      // Trả về true để báo hiệu đã có thay đổi
      Get.back(result: true);
    } catch (e) {
      setState(() {
        _isInviting = false;
      });
      Get.snackbar('Lỗi', 'Đã xảy ra lỗi: $e');
    }
  }

  // Hàm gửi notifications trong background
  Future<void> _sendNotificationsInBackground(
    List<String> membersToInvite,
    String currentUid,
    String senderName,
  ) async {
    List<String> failedMembers = [];

    // Gửi notification cho từng thành viên (không chờ)
    for (String memberId in membersToInvite) {
      _sendSingleNotification(memberId, currentUid, senderName, failedMembers);
    }
  }

  // Hàm gửi một notification đơn lẻ
  Future<void> _sendSingleNotification(
    String memberId,
    String currentUid,
    String senderName,
    List<String> failedMembers,
  ) async {
    try {
      // Gửi thông báo
      await Notification_API.sendInviteMemberNotification(
        senderName,
        memberId,
        widget.groupId,
        widget.groupName,
      );

      // Lưu thông báo vào Firestore
      await Notification_API.saveInviteMemberNotificationToFirestore(
        receiverId: memberId,
        senderId: currentUid,
        senderName: senderName,
        groupId: widget.groupId,
        groupName: widget.groupName,
      );

      print('Successfully sent invitation to $memberId');
    } catch (e) {
      // Nếu gửi thông báo thất bại
      final userDoc = await _firestore.collection('users').doc(memberId).get();
      final userName =
          userDoc.data()?['displayName'] ??
          userDoc.data()?['name'] ??
          'Unknown User';
      failedMembers.add(userName);
      print('Error inviting member $memberId: $e');

      // Có thể hiển thị snackbar lỗi nếu cần (tùy chọn)
      // Get.snackbar(
      //   'Cảnh báo',
      //   'Không thể gửi lời mời cho $userName',
      //   backgroundColor: Colors.orange,
      //   colorText: Colors.white,
      // );
    }
  }

  List<Map<String, dynamic>> get _filteredFollowers {
    if (_searchQuery.isEmpty) {
      return _followers
          .where(
            (follower) =>
                !_existingMembers.contains(follower['id']) &&
                !_invitedMembers.contains(follower['id']),
          ) // Loại bỏ người đã được mời
          .toList();
    }

    return _followers.where((follower) {
      final name = follower['name'].toString().toLowerCase();
      final email = follower['email'].toString().toLowerCase();
      final query = _searchQuery.toLowerCase();

      return (name.contains(query) || email.contains(query)) &&
          !_existingMembers.contains(follower['id']) &&
          !_invitedMembers.contains(
            follower['id'],
          ); // Loại bỏ người đã được mời
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: AppBackgroundStyles.mainBackground(isDarkMode),
      appBar: AppBar(
        backgroundColor: AppBackgroundStyles.secondaryBackground(isDarkMode),
        foregroundColor: AppTextStyles.normalTextColor(isDarkMode),
        title: const Text('Mời thành viên'),
        actions: [
          if (_selectedMembers.isNotEmpty)
            TextButton(
              onPressed: _isInviting ? null : _inviteSelectedMembers,
              child:
                  _isInviting
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : Text(
                        'Mời (${_selectedMembers.length})',
                        style: TextStyle(
                          color: AppTextStyles.normalTextColor(isDarkMode),
                        ),
                      ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              style: TextStyle(
                color: AppTextStyles.normalTextColor(isDarkMode),
              ),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                prefixIconColor: AppIconStyles.iconPrimary(isDarkMode),
                hintText: 'Tìm kiếm theo tên hoặc email...',
                hintStyle: TextStyle(
                  color: AppTextStyles.normalTextColor(
                    isDarkMode,
                  ).withOpacity(0.5),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: AppBackgroundStyles.buttonBackgroundSecondary(
                  isDarkMode,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Selected members count
          if (_selectedMembers.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppBackgroundStyles.boxBackground(isDarkMode),
              child: Text(
                'Đã chọn ${_selectedMembers.length} người',
                style: TextStyle(
                  color: AppTextStyles.normalTextColor(isDarkMode),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          // Followers list
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredFollowers.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: AppTextStyles.subTextColor(isDarkMode),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'Không tìm thấy kết quả'
                                : 'Không có followers để mời',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppTextStyles.subTextColor(isDarkMode),
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      itemCount: _filteredFollowers.length,
                      itemBuilder: (context, index) {
                        final follower = _filteredFollowers[index];
                        final isSelected = _selectedMembers.contains(
                          follower['id'],
                        );

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                                follower['avatar'].isNotEmpty
                                    ? NetworkImage(follower['avatar'])
                                    : null,
                            child:
                                follower['avatar'].isEmpty
                                    ? Text(
                                      follower['name'][0].toUpperCase(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                    : null,
                          ),
                          title: Text(
                            follower['name'],
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: AppTextStyles.normalTextColor(isDarkMode),
                            ),
                          ),
                          subtitle: Text(
                            follower['email'],
                            style: TextStyle(
                              color: AppTextStyles.normalTextColor(isDarkMode),
                            ),
                          ),
                          trailing: Checkbox(
                            value: isSelected,
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  _selectedMembers.add(follower['id']);
                                } else {
                                  _selectedMembers.remove(follower['id']);
                                }
                              });
                            },
                            checkColor: AppTextStyles.buttonTextColor(
                              isDarkMode,
                            ),
                            fillColor: MaterialStateProperty.resolveWith<Color>(
                              (states) {
                                if (states.contains(MaterialState.selected)) {
                                  return AppBackgroundStyles.buttonBackground(
                                    isDarkMode,
                                  ); // nền khi được chọn
                                }
                                return Colors.transparent; // nền khi chưa chọn
                              },
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedMembers.remove(follower['id']);
                              } else {
                                _selectedMembers.add(follower['id']);
                              }
                            });
                          },
                        );
                      },
                    ),
          ),
        ],
      ),

      // Bottom action button
      bottomNavigationBar:
          _selectedMembers.isNotEmpty
              ? Container(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: _isInviting ? null : _inviteSelectedMembers,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppBackgroundStyles.buttonBackground(
                      isDarkMode,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child:
                      _isInviting
                          ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Đang mời...',
                                style: TextStyle(
                                  color: AppTextStyles.subTextColor(isDarkMode),
                                ),
                              ),
                            ],
                          )
                          : Text(
                            'Mời ${_selectedMembers.length} thành viên',
                            style: TextStyle(
                              color: AppTextStyles.buttonTextColor(isDarkMode),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                ),
              )
              : null,
    );
  }
}
