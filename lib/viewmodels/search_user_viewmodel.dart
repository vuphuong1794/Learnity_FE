import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:learnity/api/notification_api.dart';
import 'package:learnity/api/user_apis.dart';
import 'package:learnity/models/user_info_model.dart';

class SearchUserViewModel extends ChangeNotifier {
  // State variables
  List<UserInfoModel> _displayedUsers = [];
  List<UserInfoModel> _allUsers = [];
  List<bool> _isFollowingList = [];
  bool _isLoading = false;

  // Getters
  List<UserInfoModel> get displayedUsers => _displayedUsers;

  List<bool> get isFollowingList => _isFollowingList;

  bool get isLoading => _isLoading;

  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  // Constructor
  SearchUserViewModel() {
    fetchUsers();
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Filter users based on search query
  void filterUsers(String query) {
    if (query.isEmpty) {
      _displayedUsers = List.from(_allUsers);
    } else {
      _displayedUsers =
          _allUsers.where((user) {
            if (user.uid == currentUserId) return false; // Bỏ qua chính mình
            final username = (user.username ?? '').toLowerCase();
            final displayName = (user.displayName ?? '').toLowerCase();
            return username.contains(query.toLowerCase()) ||
                displayName.contains(query.toLowerCase());
          }).toList();
    }

    _isFollowingList = List.generate(_displayedUsers.length, (index) => false);
    notifyListeners();
  }

  // Fetch all users from Firestore
  Future<void> fetchUsers() async {
    _setLoading(true);

    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final snapshot = await firestore.collection('users').get();

      final users =
          snapshot.docs
              .map((doc) {
                final data = doc.data();
                return UserInfoModel.fromMap(data, doc.id);
              })
              .where(
                (user) =>
                    user.uid != currentUserId &&
                    (user.role == null || user.role == 'user'),
              ) // Lọc bỏ user hiện tại
              .toList();

      _allUsers = users;
      _displayedUsers = List.from(users);
      _isFollowingList = List.generate(users.length, (index) => false);

      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _showErrorSnackbar("Không thể tải người dùng. Vui lòng thử lại sau.");
    }
  }

  // Handle follow/unfollow action
  Future<void> handleFollow(UserInfoModel user) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return;

    try {
      final isNowFollowing = !(user.followers?.contains(currentUid) ?? false);

      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      final currentUserRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUid);

      // Cập nhật UI trước
      if (isNowFollowing) {
        user.followers ??= [];
        user.followers!.add(currentUid);
      } else {
        user.followers?.remove(currentUid);
      }
      notifyListeners();

      // Cập nhật followers và following trong Firestore
      await userRef.update({
        'followers':
            isNowFollowing
                ? FieldValue.arrayUnion([currentUid])
                : FieldValue.arrayRemove([currentUid]),
      });

      await currentUserRef.update({
        'following':
            isNowFollowing
                ? FieldValue.arrayUnion([user.uid])
                : FieldValue.arrayRemove([user.uid]),
      });

      // Xử lý notification và chat nếu follow
      if (isNowFollowing) {
        await _handleFollowNotifications(currentUserRef, user, currentUid);
      }

      // Hiển thị thông báo thành công
      _showSuccessSnackbar(
        isNowFollowing
            ? "Đã theo dõi ${user.displayName ?? user.username ?? 'người dùng'}"
            : "Đã hủy theo dõi ${user.displayName ?? user.username ?? 'người dùng'}",
      );
    } catch (e) {
      _showErrorSnackbar("Không thể cập nhật theo dõi. Vui lòng thử lại.");
    }
  }

  // Handle notifications when following a user
  Future<void> _handleFollowNotifications(
    DocumentReference currentUserRef,
    UserInfoModel user,
    String currentUid,
  ) async {
    try {
      final senderSnapshot = await currentUserRef.get();
      final senderData = senderSnapshot.data() as Map<String, dynamic>?;
      final senderName =
          senderData?['displayName'] ?? senderData?['username'] ?? 'Người dùng';

      final firestore = FirebaseFirestore.instance;

      // Xóa thông báo theo dõi cũ nếu đã tồn tại
      final notificationQuery =
          await firestore
              .collection('notifications')
              .where('type', isEqualTo: 'follow')
              .where('senderId', isEqualTo: currentUid)
              .where('receiverId', isEqualTo: user.uid)
              .get();

      for (final doc in notificationQuery.docs) {
        await doc.reference.delete();
      }

      // Gửi notification push
      await Notification_API.sendFollowNotification(senderName, user.uid!);

      // Lưu notification vào Firestore
      await Notification_API.saveFollowNotificationToFirestore(
        receiverId: user.uid!,
        senderId: currentUid,
        senderName: senderName,
      );

      // Thêm user vào chat
      if (user.email != null && user.email!.isNotEmpty) {
        await APIs.addChatUser(user.email!);
      }
    } catch (e) {
      // Log error but don't show to user as follow was successful
      print('Error handling follow notifications: $e');
    }
  }

  // Check if current user is following a specific user
  bool isFollowing(UserInfoModel user) {
    return user.followers?.contains(currentUserId) ?? false;
  }

  // Show success snackbar
  void _showSuccessSnackbar(String message) {
    Get.snackbar(
      "Thành công",
      message,
      backgroundColor: Colors.blue.withOpacity(0.9),
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
    );
  }

  // Show error snackbar
  void _showErrorSnackbar(String message) {
    Get.snackbar(
      "Lỗi",
      message,
      backgroundColor: Colors.red.withOpacity(0.9),
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
    );
  }

  // Refresh data
  Future<void> refresh() async {
    await fetchUsers();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
