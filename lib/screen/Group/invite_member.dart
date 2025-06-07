import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:learnity/api/Notification.dart';

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
  bool _isLoading = true;
  bool _isInviting = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadFollowersData();
    _loadExistingMembers();
  }

  Future<void> _loadFollowersData() async {
    try {
      List<Map<String, dynamic>> followers = [];
      for (String followerId in widget.userFollowers) {
        final userDoc =
            await _firestore.collection('users').doc(followerId).get();

        if (userDoc.exists) {
          final userData = userDoc.data()!;
          // Sử dụng displayName như code gốc của bạn, fallback sang name
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
      // Gửi lời mời cho TẤT CẢ các thành viên vừa chọn
      await Future.wait(
        _selectedMembers.map((memberId) {
          return Notification_API.sendInviteMemberNotification(
            senderName, // <-- ID người gửi
            memberId, // <-- ID người nhận
          );
        }),
      );

      await Future.wait(
        _selectedMembers.map((memberId) async {
          // Lưu thông báo vào Firestore
          await Notification_API.saveInviteMemberNotificationToFirestore(
            receiverId: memberId,
            senderId: currentUid,
            senderName: senderName,
          );
        }),
      );

      Get.snackbar(
        'Thành công',
        'Đã mời ${_selectedMembers.length} thành viên vào group',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Trả về true để báo hiệu đã có thay đổi
      Get.back(result: true);
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể mời thành viên: $e');
    } finally {
      setState(() {
        _isInviting = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredFollowers {
    if (_searchQuery.isEmpty) {
      return _followers
          .where((follower) => !_existingMembers.contains(follower['id']))
          .toList();
    }

    return _followers.where((follower) {
      final name = follower['name'].toString().toLowerCase();
      final email = follower['email'].toString().toLowerCase();
      final query = _searchQuery.toLowerCase();

      return (name.contains(query) || email.contains(query)) &&
          !_existingMembers.contains(follower['id']);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
                        style: const TextStyle(color: Colors.white),
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
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo tên hoặc email...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey[100],
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
              color: Colors.blue[50],
              child: Text(
                'Đã chọn ${_selectedMembers.length} người',
                style: TextStyle(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w500,
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
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'Không tìm thấy kết quả'
                                : 'Không có followers để mời',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
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
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(follower['email']),
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
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child:
                      _isInviting
                          ? const Row(
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
                              Text('Đang mời...'),
                            ],
                          )
                          : Text(
                            'Mời ${_selectedMembers.length} thành viên',
                            style: const TextStyle(
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
