import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:learnity/screen/Group/invite_member.dart';
import 'package:learnity/screen/Group/widget/create_post_bar_widget.dart';
import 'package:learnity/screen/Group/widget/group_action_buttons_widget.dart';
import 'package:learnity/screen/Group/widget/group_activity_section_widget.dart';
import 'package:learnity/screen/Group/widget/group_post_card_widget.dart';
import 'package:learnity/theme/theme.dart';
import 'package:learnity/models/group_post_model.dart';
import 'create_group_post_page.dart';

class GroupcontentScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  final bool isPreviewMode;

  const GroupcontentScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    this.isPreviewMode = false,
  });

  @override
  State<GroupcontentScreen> createState() => _GroupcontentScreenState();
}

class _GroupcontentScreenState extends State<GroupcontentScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Map<String, dynamic>? groupData;
  List<GroupPostModel> recentPosts = [];
  List<Map<String, dynamic>> groupMembers = [];
  bool isLoading = true;
  bool isMember = false;

  @override
  void initState() {
    super.initState();
    _loadGroupData();
    Intl.defaultLocale = 'vi_VN';
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Không rõ';
    return DateFormat('d MMM, HH:mm').format(timestamp.toDate());
  }

  Future<void> _loadGroupData() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });
    try {
      final groupDoc =
          await _firestore
              .collection('communityGroups')
              .doc(widget.groupId)
              .get();
      if (groupDoc.exists) {
        groupData = groupDoc.data();
        final membersList = groupData?['membersList'] as List<dynamic>? ?? [];
        groupMembers =
            membersList
                .map((member) => Map<String, dynamic>.from(member))
                .toList();
        final currentUser = _auth.currentUser;
        if (currentUser != null) {
          isMember = groupMembers.any((m) => m['uid'] == currentUser.uid);
        } else {
          isMember = false;
        }
        final postsSnapshot =
            await _firestore
                .collection('communityGroups')
                .doc(widget.groupId)
                .collection('posts')
                .orderBy('createdAt', descending: true)
                .limit(10)
                .get();
        recentPosts =
            postsSnapshot.docs
                .map((doc) => GroupPostModel.fromDocument(doc))
                .toList();
      } else {
        groupData = null;
        isMember = false;
        recentPosts = [];
      }
    } catch (e) {
      print('Error loading group data: $e');
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu nhóm: ${e.toString()}')),
        );
      groupData = null;
      isMember = false;
      recentPosts = [];
    } finally {
      if (mounted)
        setState(() {
          isLoading = false;
        });
    }
  }

  //  xóa bài đăng nhóm
  Future<void> _DeletePostGroup(String postId, String? imageUrl) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    //Lấy thông tin bài đăng để kiểm tra tác giả
    DocumentSnapshot postDoc =
        await _firestore
            .collection('communityGroups')
            .doc(widget.groupId)
            .collection('posts')
            .doc(postId)
            .get();
    if (!postDoc.exists ||
        (postDoc.data() as Map<String, dynamic>)['authorUid'] !=
            currentUser.uid) {
      Get.snackbar("Lỗi", "Bạn không có quyền xóa bài viết này.");
      return;
    }

    bool? confirmDelete = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Xác nhận xóa bài viết'),
        content: const Text('Bạn có chắc chắn muốn xóa bài viết này không?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.buttonBg,
              foregroundColor: AppColors.buttonText,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmDelete != true) return;

    if (!mounted) return;
    try {
      await _firestore
          .collection('communityGroups')
          .doc(widget.groupId)
          .collection('posts')
          .doc(postId)
          .delete();
      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          await FirebaseStorage.instance.refFromURL(imageUrl).delete();
          print('Image deleted from Storage: $imageUrl');
        } catch (storageError) {
          print("Lỗi khi xóa ảnh");
        }
      }
      if (mounted) {
        setState(() {
          recentPosts.removeWhere((p) => p.postId == postId);
        });
        Get.snackbar("Thành công", "Đã xóa bài viết.");
      }
    } catch (e) {
      print("Error deleting post from Firestore: $e");
      if (mounted) {
        Get.snackbar("Lỗi", "Không thể xóa bài viết: ${e.toString()}");
      }
    } finally {}
  }

  Future<void> _handleLikePost(String postId, bool currentLikeStatus) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;
    final postRef = _firestore
        .collection('communityGroups')
        .doc(widget.groupId)
        .collection('posts')
        .doc(postId);
    try {
      if (currentLikeStatus) {
        await postRef.update({
          'likedBy': FieldValue.arrayRemove([currentUser.uid]),
        });
      } else {
        await postRef.update({
          'likedBy': FieldValue.arrayUnion([currentUser.uid]),
        });
      }
      int postIndex = recentPosts.indexWhere((p) => p.postId == postId);
      if (postIndex != -1 && mounted) {
        List<String> updatedLikedBy = List<String>.from(
          recentPosts[postIndex].likedBy,
        );
        if (currentLikeStatus) {
          updatedLikedBy.remove(currentUser.uid);
        } else {
          updatedLikedBy.add(currentUser.uid);
        }
        setState(() {
          recentPosts[postIndex] = recentPosts[postIndex].copyWith(
            likedBy: updatedLikedBy,
            isLikedByCurrentUser: !currentLikeStatus,
          );
        });
      }
    } catch (e) {
      print("Error liking/unliking post: $e");
      Get.snackbar("Lỗi", "Không thể thích/bỏ thích bài viết.");
    }
  }

  Future<void> _joinGroupInternally() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        if (mounted) setState(() => isLoading = false);
        return;
      }
      if (groupData == null) {
        if (mounted) setState(() => isLoading = false);
        return;
      }
      final userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      if (!userDoc.exists || userDoc.data() == null)
        throw Exception("Không thể lấy thông tin người dùng.");
      final userData = userDoc.data()!;
      if (groupData!['privacy'] == 'Riêng tư') {
        await _firestore
            .collection('communityGroups')
            .doc(widget.groupId)
            .collection('join_requests')
            .doc(currentUser.uid)
            .set({});
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã gửi yêu cầu tham gia. Chờ admin duyệt!'),
            ),
          );
        await _loadGroupData();
      } else {
        await _firestore
            .collection('communityGroups')
            .doc(widget.groupId)
            .update({});
        await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('communityGroups')
            .doc(widget.groupId)
            .set({});
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tham gia nhóm thành công!')),
          );
        await _loadGroupData();
      }
    } catch (e) {
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _leaveGroup() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || groupData == null) return;
    bool? confirmLeave = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Rời khỏi nhóm?'),
        content: Text(
          'Bạn có chắc chắn muốn rời khỏi nhóm "${widget.groupName}" không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Rời khỏi', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmLeave != true) return;
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      DocumentSnapshot groupSnapshot =
          await _firestore
              .collection('communityGroups')
              .doc(widget.groupId)
              .get();
      if (groupSnapshot.exists) {
        List<dynamic> currentMembers = List.from(
          (groupSnapshot.data() as Map<String, dynamic>)['membersList'] ?? [],
        );
        final initialLength = currentMembers.length;
        currentMembers.removeWhere(
          (member) => member is Map && member['uid'] == currentUser.uid,
        );
        final finalLength = currentMembers.length;
        await _firestore
            .collection('communityGroups')
            .doc(widget.groupId)
            .update({
              'membersList': currentMembers,
              if (finalLength < initialLength)
                'membersCount': FieldValue.increment(-1),
            });
      }
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('communityGroups')
          .doc(widget.groupId)
          .delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã rời khỏi nhóm "${widget.groupName}"')),
        );
        await _loadGroupData();
      }
    } catch (e) {
      print('Error leaving group: $e');
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi rời nhóm: ${e.toString()}')),
        );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _inviteMember() async {
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

      List<String> userFollowers = [];

      if (userData['followers'] != null) {
        userFollowers = List<String>.from(userData['followers']);

        //kiểm tra followers đó đã vào nhóm hay chưa
        userFollowers.removeWhere(
          (follower) => groupMembers.any((member) => member['uid'] == follower),
        );
      }

      if (userFollowers.isEmpty) {
        Get.snackbar('Thông báo', 'Bạn chưa có followers nào để mời');
        return;
      }
      final result = await Get.to(
        () => InviteMemberPage(
          groupId: widget.groupId,
          groupName: widget.groupName,
          userFollowers: userFollowers,
        ),
      );

      if (result == true && mounted) {
        _loadGroupData();
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể tải danh sách followers');
    }
  }

  Future<void> _deleteGroup() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || groupData == null) return;

    bool? confirmDelete = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Xác nhận xóa nhóm'),
        content: const Text('Bạn có chắc chắn muốn xóa nhóm này không?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.buttonBg,
              foregroundColor: AppColors.buttonText,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmDelete != true) return;

    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      await _firestore
          .collection('communityGroups')
          .doc(widget.groupId)
          .delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã xóa nhóm "${widget.groupName}"')),
        );
        Get.back(result: true);
      }
    } catch (e) {
      print("Error deleting group from Firestore: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi xóa nhóm: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _navigateToCreatePostPage() async {
    final result = await Get.to(
      () => CreateGroupPostPage(
        groupId: widget.groupId,
        groupName: widget.groupName,
      ),
    );
    if (result == true && mounted) {
      _loadGroupData();
    }
  }

  bool _checkIfCurrentUserIsAdmin() {
    final currentUser = _auth.currentUser;
    if (currentUser == null || groupData == null || groupMembers.isEmpty) {
      return false;
    }

    // Kiểm tra xem user hiện tại có isAdmin = true không
    return groupMembers.any(
      (member) => member['uid'] == currentUser.uid && member['isAdmin'] == true,
    );
  }

  Widget _buildGroupHeader() {
    if (groupData == null && isLoading) return const SizedBox.shrink();
    if (groupData == null && !isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "Không tìm thấy thông tin nhóm.",
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return Container(
      color: AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(groupData!['avatarUrl'] as String? ?? ''),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.groupName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (groupData!['privacy'] as String? ?? 'Công khai') ==
                                    'Công khai'
                                ? Colors.grey.shade200
                                : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            (groupData!['privacy'] as String? ?? 'Công khai') ==
                                    'Công khai'
                                ? Icons.public
                                : Icons.lock,
                            size: 16,
                            color: Colors.black54,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            groupData!['privacy'] as String? ?? 'Công khai',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${groupData!['membersCount'] ?? groupMembers.length}',
                      style: const TextStyle(color: Colors.black, fontSize: 14),
                    ),
                    Text(
                      ' thành viên',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 16.0,
            ),
            child: GroupActionButtonsWidget(
              isLoading: isLoading && groupData == null,
              isMember: isMember,
              isAdmin: _checkIfCurrentUserIsAdmin(),
              isPreviewMode: widget.isPreviewMode,
              groupPrivacy: groupData!['privacy'] as String? ?? 'Công khai',
              onJoinGroup:
                  widget.isPreviewMode
                      ? () => Navigator.pop(context, 'join_group')
                      : _joinGroupInternally,
              onLeaveGroup: _leaveGroup,
              onInviteMember: _inviteMember,
              onDeleteGroup: _deleteGroup,
            ),
          ),
          if (isMember && !widget.isPreviewMode && !isLoading) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 8.0),
              child: _buildGroupChatButton(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
              child: CreatePostBarWidget(
                currentUserAvatarUrl: _auth.currentUser?.photoURL,
                onTapTextField: _navigateToCreatePostPage,
                onTapPhoto: () {
                  _navigateToCreatePostPage();
                },
                onTapCamera: () {
                  _navigateToCreatePostPage();
                },
                onTapMic: () {
                  _navigateToCreatePostPage();
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPostsSection() {
    if (isLoading && recentPosts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (recentPosts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20.0),
        alignment: Alignment.center,
        child: Text(
          'Chưa có bài viết nào trong nhóm này.',
          style: TextStyle(fontSize: 16, color: AppColors.black),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recentPosts.length,
      itemBuilder: (context, index) {
        final post = recentPosts[index];
        return GroupPostCardWidget(
          userName: post.authorUsername ?? 'Người dùng',
          userAvatarUrl: post.authorAvatarUrl ?? '',
          postTitle: post.title,
          postText: post.text ?? '',
          postImageUrl: post.imageUrl,
          timestamp: _formatTimestamp(Timestamp.fromDate(post.createdAt)),
          likesCount: post.likesCount,
          commentsCount: post.commentsCount,
          sharesCount: post.sharesCount,
          isLikedByCurrentUser: post.isLikedByCurrentUser,
          onLikePressed:
              () => _handleLikePost(post.postId, post.isLikedByCurrentUser),
          onCommentPressed: () {},
          onSharePressed: () {},
          postAuthorUid: post.authorUid,
          onDeletePost: () => _DeletePostGroup(post.postId, post.imageUrl),
        );
      },
    );
  }

  Widget _buildGroupChatButton() {
    return ElevatedButton.icon(
      icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white),
      label: const Text(
        'Trò chuyện nhóm',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.black,
        minimumSize: const Size(double.infinity, 48),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        elevation: 2,
      ),
    );
  }

  Widget _buildActivitySectionFromData() {
    int postsTodayCount = 0;
    if (recentPosts.isNotEmpty) {
      final now = DateTime.now();
      postsTodayCount =
          recentPosts.where((post) {
            final postDate = post.createdAt;
            return postDate.year == now.year &&
                postDate.month == now.month &&
                postDate.day == now.day;
          }).length;
    }
    String membersInfo =
        groupData != null
            ? 'Tổng số ${groupData!['membersCount'] ?? groupMembers.length} thành viên'
            : 'N/A';
    String creationInfo = 'Ngày tạo: N/A';
    if (groupData != null && groupData!['createdAt'] is Timestamp) {
      DateTime creationDate = (groupData!['createdAt'] as Timestamp).toDate();
      creationInfo = 'Tạo ngày: ${DateFormat.yMd().format(creationDate)}';
    }
    return GroupActivitySectionWidget(
      postsTodayCount: postsTodayCount,
      membersInfo: membersInfo,
      creationInfo: creationInfo,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenBackgroundColor = AppColors.background;
    return Scaffold(
      backgroundColor: screenBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.isPreviewMode && !isMember
              ? 'Xem trước nhóm'
              : widget.groupName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        centerTitle: true,
      ),
      body:
          (isLoading && groupData == null)
              ? const Center(child: CircularProgressIndicator())
              : (groupData == null && !isLoading)
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "Không thể tải thông tin nhóm hoặc nhóm không tồn tại.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ),
              )
              : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildGroupHeader(),
                    _buildPostsSection(),
                    const Divider(
                      height: 1,
                      thickness: 0.5,
                      indent: 16,
                      endIndent: 16,
                    ),
                    const SizedBox(height: 10),
                    _buildActivitySectionFromData(),
                  ],
                ),
              ),
    );
  }
}
