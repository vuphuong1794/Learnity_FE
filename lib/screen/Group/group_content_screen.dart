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
import 'package:learnity/screen/Group/group_post_comment_screen.dart';
import 'package:learnity/theme/theme.dart';
import 'package:learnity/models/group_post_model.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../api/group_api.dart';
import '../../theme/theme_provider.dart';
import 'create_group_post_page.dart';
import 'groupManagement_page.dart';
import 'manage_group_members_screen.dart';
import 'manage_join_requests_screen.dart';
import 'manage_pending_posts_screen.dart';

class GroupcontentScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  final bool isPreviewMode;
  final bool isAdminView;

  const GroupcontentScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    this.isPreviewMode = false,
    this.isAdminView = false,
  });

  @override
  State<GroupcontentScreen> createState() => _GroupcontentScreenState();
}

class _GroupcontentScreenState extends State<GroupcontentScreen> {
  final GroupApi _groupApi = GroupApi();
  Map<String, dynamic>? groupData;
  List<GroupPostModel> recentPosts = [];
  List<Map<String, dynamic>> groupMembers = [];
  bool isLoading = true;
  bool isMember = false;
  bool isAdmin = false;
  late String _currentGroupName;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _currentGroupName = widget.groupName;
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
      final result = await _groupApi.loadGroupData(widget.groupId);
      if (result != null && mounted) {
        setState(() {
          groupData = result['groupData'];
          recentPosts = result['recentPosts'];
          groupMembers = result['groupMembers'];
          isMember = result['isMember'];
          isAdmin = result['isAdmin'];
          if (groupData != null && groupData!['name'] != null) {
            _currentGroupName = groupData!['name'];
          }
        });
      } else {
        setState(() {
          groupData = null;
          recentPosts = [];
          groupMembers = [];
          isMember = false;
          isAdmin = false;
        });
      }
    } catch (e) {
      print('Error loading group data in widget: $e');
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu nhóm: ${e.toString()}')),
        );
    } finally {
      if (mounted)
        setState(() {
          isLoading = false;
        });
    }
  }

  //  xóa bài đăng nhóm
  Future<void> _DeletePostGroup(String postId, String? imageUrl) async {
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
      final success = await _groupApi.deletePostGroup(
        widget.groupId,
        postId,
        imageUrl,
      );
      if (success) {
        if (mounted) {
          setState(() {
            recentPosts.removeWhere((p) => p.postId == postId);
          });
          Get.snackbar("Thành công", "Đã xóa bài viết.");
        }
      } else {
        Get.snackbar(
          "Lỗi",
          "Bạn không có quyền hoặc đã có lỗi xảy ra khi xóa.",
        );
      }
    } catch (e) {
      if (mounted)
        Get.snackbar("Lỗi", "Không thể xóa bài viết: ${e.toString()}");
    }
  }

  Future<void> _handleLikePost(String postId, bool currentLikeStatus) async {
    final postIndex = recentPosts.indexWhere((p) => p.postId == postId);
    if (postIndex != -1) {
      final updatedPost = recentPosts[postIndex].copyWith(
        likedBy:
            currentLikeStatus
                ? (List<String>.from(recentPosts[postIndex].likedBy)
                  ..remove('temp_id'))
                : (List<String>.from(recentPosts[postIndex].likedBy)
                  ..add('temp_id')),
        isLikedByCurrentUser: !currentLikeStatus,
      );
      setState(() {
        recentPosts[postIndex] = updatedPost;
      });
    }
    try {
      await _groupApi.handleLikePost(widget.groupId, postId, currentLikeStatus);
      // await _loadGroupData();
    } catch (e) {
      print("Error liking/unliking post: $e");
      Get.snackbar("Lỗi", "Không thể thích/bỏ thích bài viết.");
    }
  }

  Future<void> _joinGroupInternally() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      if (groupData == null) return;
      final result = await _groupApi.joinGroupInternally(
        widget.groupId,
        groupData!,
      );
      if (mounted) {
        if (result == 'request_sent') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã gửi yêu cầu tham gia. Chờ admin duyệt!'),
            ),
          );
        } else if (result == 'joined_successfully') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tham gia nhóm thành công!')),
          );
          await _loadGroupData();
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Có lỗi xảy ra.')));
        }
      }
    } catch (e) {
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _leaveGroup() async {
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
            style: TextButton.styleFrom(
              foregroundColor: AppColors.buttonText,
              backgroundColor: AppColors.buttonBg,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Rời khỏi'),
          ),
        ],
      ),
    );

    if (confirmLeave != true || !mounted) return;

    final result = await _groupApi.leaveGroup(widget.groupId);

    if (mounted) {
      if (result == "success") {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã rời khỏi nhóm "${widget.groupName}"')),
        );
        await _loadGroupData();
      } else if (result == "error_last_admin") {
        Get.snackbar(
          "Không thể rời nhóm",
          "Bạn là quản trị viên duy nhất. Vui lòng chỉ định quản trị viên mới hoặc xóa nhóm.",
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi rời nhóm. Vui lòng thử lại.')),
        );
      }
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

  void _showAdminMenu() {
    if (groupData == null) return;

    List<PopupMenuEntry<String>> menuItems = [];

    // Nhóm là riêng tư thì mới hiện
    if (groupData!['privacy'] == 'Riêng tư') {
      menuItems.add(
        PopupMenuItem(
          value: 'manage_requests',
          child: Row(
            children: [
              Icon(Icons.checklist_rtl_rounded, color: Colors.blueAccent),
              const SizedBox(width: 10),
              Text(
                'Duyệt yêu cầu tham gia',
                style: TextStyle(color: AppColors.black),
              ),
            ],
          ),
        ),
      );
    }

    menuItems.add(
      PopupMenuItem(
        value: 'manage_members',
        child: Row(
          children: [
            Icon(Icons.groups_outlined, color: Colors.teal),
            const SizedBox(width: 10),
            Text(
              'Quản lý thành viên',
              style: TextStyle(color: AppColors.black),
            ),
          ],
        ),
      ),
    );
    menuItems.add(
      PopupMenuItem(
        value: 'manage_posts',
        child: Row(
          children: [
            Icon(Icons.rate_review_outlined, color: Colors.orange.shade700),
            const SizedBox(width: 10),
            Text('Duyệt bài đăng', style: TextStyle(color: AppColors.black)),
          ],
        ),
      ),
    );
    menuItems.add(
      PopupMenuItem(
        value: 'delete_group',
        child: Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.redAccent),
            const SizedBox(width: 10),
            Text('Xóa nhóm', style: TextStyle(color: AppColors.black)),
          ],
        ),
      ),
    );

    if (menuItems.isEmpty) {
      Get.snackbar("Thông báo", "Không có thao tác quản trị nào khả dụng.");
      return;
    }

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width - 100,
        kToolbarHeight + MediaQuery.of(context).padding.top,
        0,
        0,
      ),
      items: menuItems,
    ).then((value) async {
      if (value == 'manage_posts') {
        final shouldReload = await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ManagePendingPostsScreen(
                  groupId: widget.groupId,
                  groupName: widget.groupName,
                ),
          ),
        );

        if (shouldReload == true) {
          setState(() {
            _loadGroupData();
          });
        }
      } else if (value == 'manage_requests') {
        final shouldReload = await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ManageJoinRequestsScreen(
                  groupId: widget.groupId,
                  groupName: widget.groupName,
                ),
          ),
        );

        if (shouldReload == true) {
          setState(() {
            _loadGroupData();
          });
        }
      } else if (value == 'manage_members') {
        final shouldReload = await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ManageGroupMembersScreen(
                  groupId: widget.groupId,
                  groupName: widget.groupName,
                ),
          ),
        );

        if (shouldReload == true) {
          setState(() {
            _loadGroupData();
          });
        }
      } else if (value == 'delete_group') {
        final bool? confirmResult = await showDialog<bool>(
          context: context,
          builder:
              (BuildContext dialogContext) => AlertDialog(
                title: const Text('Xác nhận xóa nhóm'),
                content: const Text(
                  'Bạn có chắc chắn muốn xóa vĩnh viễn nhóm này không ?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text('Hủy'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: const Text('Xóa'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonBg,
                      foregroundColor: AppColors.buttonText,
                    ),
                  ),
                ],
              ),
        );
        if (confirmResult == true) {
          await _deleteGroup();
        }
      }
    });
  }

  Future<void> _shareInternally(GroupPostModel post) async {
    final success = await _groupApi.shareInternally(
      widget.groupId,
      widget.groupName,
      post,
    );

    if (!mounted) return;

    if (success) {
      setState(() {
        final postIndex = recentPosts.indexWhere(
          (p) => p.postId == post.postId,
        );
        if (postIndex != -1) {
          recentPosts[postIndex] = recentPosts[postIndex].copyWith(
            sharesCount: recentPosts[postIndex].sharesCount + 1,
          );
        }
      });
      Get.snackbar("Thành công", "Đã chia sẻ bài viết.");
    } else {
      Get.snackbar("Lỗi", "Không thể chia sẻ bài viết, vui lòng thử lại.");
    }
  }

  //Chia sẻ ra ứng dụng bên ngoài
  Future<void> _shareExternally(GroupPostModel post) async {
    final String title = post.title!;
    final String text = post.text ?? '';
    final String shareContent =
        '$title\n\n$text\n\n(Chia sẻ từ ứng dụng Learnity)';
    await Share.share(shareContent);
  }
  // Thêm hàm này vào class _GroupcontentScreenState

  Future<void> _navigateToManagementPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupManagementPage(groupId: widget.groupId),
      ),
    );

    if (result == true && mounted) {
      _loadGroupData();
    }
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
                  _currentGroupName,
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
              groupId: widget.groupId,
              isLoading: isLoading && groupData == null,
              isMember: isMember,
              isPreviewMode: widget.isPreviewMode,
              groupPrivacy: groupData!['privacy'] as String? ?? 'Công khai',
              onJoinGroup:
                  widget.isPreviewMode
                      ? () => Navigator.pop(context, 'join_group')
                      : _joinGroupInternally,
              onLeaveGroup: _leaveGroup,
              isAdmin: _checkIfCurrentUserIsAdmin(),
              onInviteMember: _inviteMember,
              onManageGroup: _navigateToManagementPage,
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
        final themeProvider = Provider.of<ThemeProvider>(
          context,
          listen: false,
        );
        final bool isDarkMode = themeProvider.isDarkMode;
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
          onCommentPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => GroupPostCommentScreen(
                      groupId: widget.groupId,
                      postId: post.postId,
                    ),
              ),
            );
          },
          onSharePressed: () {
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('Chia sẻ bài viết'),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.repeat),
                        title: const Text('Chia sẻ trong ứng dụng'),
                        onTap: () {
                          Navigator.pop(context);
                          _shareInternally(post);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.share),
                        title: const Text('Chia sẻ ra ngoài'),
                        onTap: () {
                          Navigator.pop(context);
                          _shareExternally(post);
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
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
              : _currentGroupName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        centerTitle: true,
        actions: [
          if (isAdmin && !widget.isPreviewMode && groupData != null)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings_outlined),
              onPressed: _showAdminMenu,
            ),
        ],
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
