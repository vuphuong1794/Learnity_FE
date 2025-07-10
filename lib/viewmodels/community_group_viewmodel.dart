import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_sdk/cloudinary_sdk.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:learnity/api/group_api.dart';
import 'package:learnity/config.dart';
import 'package:learnity/screen/groupPage/create_group_post_page.dart';
import 'package:learnity/screen/groupPage/group_management_page.dart';
import 'package:learnity/screen/groupPage/invite_member.dart';
import 'package:learnity/screen/groupPage/report_group_page.dart';
import 'package:learnity/theme/theme.dart';

import '../widgets/common/confirm_modal.dart';

class CommunityGroup {
  final GroupApi _groupApi = GroupApi();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? groupData;

  List<Map<String, dynamic>> groupMembers = [];

  // Cloudinary configuration
  final Cloudinary cloudinary = Cloudinary.full(
    // apiKey: dotenv.env['CLOUDINARY_API_KEY1']!,
    // apiSecret: dotenv.env['CLOUDINARY_API_SECRET1']!,
    // cloudName: dotenv.env['CLOUDINARY_CLOUD_NAME1']!,
    apiKey: Config.cloudinaryApiKey1,
    apiSecret: Config.cloudinaryApiSecret1,
    cloudName: Config.cloudinaryCloudName1,
  );

  Future<String?> uploadToCloudinary(File imageFile) async {
    try {
      final response = await cloudinary.uploadFile(
        filePath: imageFile.path,
        resourceType: CloudinaryResourceType.image,
        folder:
            'Learnity/CommunityGroups/${FirebaseAuth.instance.currentUser?.uid}', // thư mục lưu trữ trên Cloudinary
        fileName:
            'avatar_${FirebaseAuth.instance.currentUser?.uid}', // tên file
        progressCallback: (count, total) {
          debugPrint('Uploading image: $count/$total');
        },
      );

      if (response.isSuccessful && response.secureUrl != null) {
        return response.secureUrl;
      } else {
        throw Exception('Upload failed: ${response.error}');
      }
    } catch (e) {
      debugPrint('Error uploading to Cloudinary: $e');
      rethrow;
    }
  }

  Future<void> reportGroup(
    BuildContext context, {
    required String groupId,
    required String groupName,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      Get.snackbar(
        'Lỗi',
        'Bạn cần đăng nhập để thực hiện chức năng này',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                ReportGroupPage(groupId: groupId, groupName: groupName),
      ),
    );
  }

  Future<void> navigateToCreatePostPage({
    required String groupId,
    required String groupName,
    required VoidCallback loadGroupData,
    required bool mounted,
  }) async {
    final result = await Get.to(
      () => CreateGroupPostPage(groupId: groupId, groupName: groupName),
    );
    if (result == true && mounted) {
      loadGroupData();
    }
  }

  Future<void> navigateToManagementPage({
    required String groupId,
    required bool mounted,
    required VoidCallback loadGroupData,
  }) async {
    final result = await Get.to(() => GroupManagementPage(groupId: groupId));

    if (result == true && mounted) {
      loadGroupData();
    }
  }

  Future<void> inviteMember({
    required String groupId,
    required String groupName,
    required List<String> userFollowers,
    required bool mounted,
    required VoidCallback loadGroupData,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return;
    }
    try {
      final userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (!userDoc.exists) {
        Get.snackbar('Lỗi', 'Không tìm thấy thông tin user');
        return;
      }
      final userData = userDoc.data()!;

      List<String> followers = [];

      if (userData['followers'] != null) {
        followers = List<String>.from(userData['followers']);

        //kiểm tra followers đó đã vào nhóm hay chưa
        followers.removeWhere(
          (follower) => groupMembers.any((member) => member['uid'] == follower),
        );
      }

      if (followers.isEmpty) {
        Get.snackbar(
          "Thông báo",
          "Không có người theo dõi nào để mời vào nhóm.",
          backgroundColor: Colors.blue.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
        return;
      }
      final result = await Get.to(
        () => InviteMemberPage(
          groupId: groupId,
          groupName: groupName,
          userFollowers: followers,
        ),
      );

      if (result == true && mounted) {
        loadGroupData();
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể tải danh sách followers');
    }
  }

  Future<void> leaveGroup({
    required BuildContext context,
    required String groupId,
    required String groupName,
    required bool mounted,
    required bool isDarkMode,
    required Future<void> Function() loadGroupData,
  }) async {
    final confirmLeave = await showConfirmModal(
      title: 'Rời khỏi nhóm?',
      content: 'Bạn có chắc chắn muốn rời khỏi nhóm "$groupName" không?',
      cancelText: 'Hủy',
      confirmText: 'Rời khỏi',
      context: context,
      isDarkMode: isDarkMode,
    );

    if (confirmLeave != true || !mounted) return;

    final result = await _groupApi.leaveGroup(groupId);

    if (mounted) {
      if (result == "success") {
        Get.snackbar(
          "Thành công",
          "Đã rời khỏi nhóm thành công!",
          backgroundColor: Colors.blue.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
        await loadGroupData();
      } else if (result == "error_last_admin") {
        Get.snackbar(
          "Không thể rời nhóm",
          "Bạn là quản trị viên duy nhất. Vui lòng chỉ định quản trị viên mới hoặc xóa nhóm.",
        );
      } else {
        Get.snackbar(
          "Lỗi",
          "Không thể rời nhóm. Vui lòng thử lại sau.",
          backgroundColor: Colors.red.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      }
    }
  }
}
