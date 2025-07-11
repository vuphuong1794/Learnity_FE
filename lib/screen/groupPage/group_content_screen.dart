import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:learnity/screen/createPostPage/post_upload_controller.dart';
import 'package:learnity/screen/groupPage/invite_member.dart';
import 'package:learnity/screen/groupPage/report_group_page.dart';
import 'package:learnity/viewmodels/community_group_viewmodel.dart';
import 'package:learnity/widgets/homePage/upload_progress.dart';
import 'package:learnity/widgets/menuPage/groupPage/create_post_bar_widget.dart';
import 'package:learnity/widgets/menuPage/groupPage/group_action_buttons_widget.dart';
import 'package:learnity/widgets/menuPage/groupPage/group_post_card_widget.dart';
import 'package:learnity/screen/groupPage/group_post_comment_screen.dart';
import 'package:learnity/models/group_post_model.dart';
import 'package:share_plus/share_plus.dart';
import '../../api/group_api.dart';
import '../../models/bottom_sheet_option.dart';
import '../../widgets/common/confirm_modal.dart';
import '../../widgets/common/custom_bottom_sheet.dart';
import '../../widgets/menuPage/groupPage/group_activity_section_widget.dart';
import 'create_group_post_page.dart';
import 'group_info_screen.dart';
import 'group_management_page.dart';
import 'manage_group_members_screen.dart';
import 'manage_join_requests_screen.dart';
import 'manage_pending_posts_screen.dart';

import 'package:provider/provider.dart';
import 'package:learnity/theme/theme.dart';
import 'package:learnity/theme/theme_provider.dart';

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
  late PostUploadController _uploadController;

  @override
  void initState() {
    super.initState();
    _currentGroupName = widget.groupName;
    _loadGroupData();
    Intl.defaultLocale = 'vi_VN';
    _uploadController = Get.put(PostUploadController());

    // Listen to upload success to refresh posts
    ever(_uploadController.uploadSuccess, (success) {
      if (success) {
        _loadGroupData();
      }
    });
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
        Get.snackbar(
          "Lỗi",
          "Không thể tải dữ liệu nhóm. Vui lòng thử lại sau.",
          backgroundColor: Colors.blue.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
    } finally {
      if (mounted)
        setState(() {
          isLoading = false;
        });
    }
  }

  //  xóa bài đăng nhóm
  Future<void> _DeletePostGroup(
    bool isDarkMode,
    String postId,
    List<String>? imageUrls,
  ) async {
    bool? confirmDelete = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: AppBackgroundStyles.modalBackground(isDarkMode),
        title: Text(
          'Xác nhận xóa bài viết',
          style: TextStyle(color: AppTextStyles.normalTextColor(isDarkMode)),
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa bài viết này không?',
          style: TextStyle(color: AppTextStyles.normalTextColor(isDarkMode)),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(
              'Hủy',
              style: TextStyle(color: AppTextStyles.subTextColor(isDarkMode)),
            ),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(
              backgroundColor: AppBackgroundStyles.buttonBackground(isDarkMode),
              foregroundColor: AppTextStyles.buttonTextColor(isDarkMode),
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
        imageUrls,
      );
      if (success) {
        if (mounted) {
          setState(() {
            recentPosts.removeWhere((p) => p.postId == postId);
          });
          Get.snackbar(
            "Thành công",
            "Đã xóa bài viết thành công!",
            backgroundColor: Colors.blue.withOpacity(0.9),
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
          );
        }
      } else {
        Get.snackbar(
          "Lỗi",
          "Không thể xóa bài viết. Vui lòng thử lại sau.",
          backgroundColor: Colors.red.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
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
          Get.snackbar(
            "Thành công",
            "Yêu cầu tham gia đã được gửi. Vui lòng chờ phê duyệt từ quản trị viên.",
            backgroundColor: Colors.blue.withOpacity(0.9),
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
          );
        } else if (result == 'joined_successfully') {
          Get.snackbar(
            "Thành công",
            "Tham gia nhóm thành công!",
            backgroundColor: Colors.blue.withOpacity(0.9),
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
          );
          await _loadGroupData();
        } else {
          Get.snackbar(
            "Lỗi",
            "Không thể tham gia nhóm. Vui lòng thử lại sau.",
            backgroundColor: Colors.red.withOpacity(0.9),
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
          );
        }
      }
    } catch (e) {
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  bool checkIfCurrentUserIsAdmin() {
    final currentUser = _auth.currentUser;
    if (currentUser == null || groupData == null || groupMembers.isEmpty) {
      return false;
    }

    // Kiểm tra xem user hiện tại có isAdmin = true không
    return groupMembers.any(
      (member) => member['uid'] == currentUser.uid && member['isAdmin'] == true,
    );
  }

  Future<void> _deleteGroup(bool isDarkMode) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || groupData == null) return;

    bool? confirmDelete = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: AppBackgroundStyles.modalBackground(isDarkMode),
        title: Text(
          'Xác nhận xóa nhóm',
          style: TextStyle(color: AppTextStyles.normalTextColor(isDarkMode)),
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa nhóm này không?',
          style: TextStyle(color: AppTextStyles.normalTextColor(isDarkMode)),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(
              'Hủy',
              style: TextStyle(color: AppTextStyles.subTextColor(isDarkMode)),
            ),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(
              backgroundColor: AppBackgroundStyles.buttonBackground(isDarkMode),
              foregroundColor: AppTextStyles.normalTextColor(isDarkMode),
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
        Get.snackbar(
          "Thành công",
          "Đã xóa nhóm thành công!",
          backgroundColor: Colors.blue.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
        Get.back(result: true);
      }
    } catch (e) {
      print("Error deleting group from Firestore: $e");
      if (mounted) {
        Get.snackbar(
          "Lỗi",
          "Không thể xóa nhóm. Vui lòng thử lại sau.",
          backgroundColor: Colors.blue.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
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

  Widget _buildGroupHeader(bool isDarkMode) {
    if (groupData == null && isLoading) return const SizedBox.shrink();
    if (groupData == null && !isLoading) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "Không tìm thấy thông tin nhóm.",
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTextStyles.normalTextColor(isDarkMode)),
          ),
        ),
      );
    }
    return Container(
      color: AppBackgroundStyles.secondaryBackground(isDarkMode),
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
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => GroupInfoScreen(
                        groupId: groupData?['id'],
                        groupName: _currentGroupName,
                        groupDescription: groupData!['description'] ?? '',
                        createdAt: groupData!['createdAt'],
                        isDarkMode: isDarkMode,
                        recentPosts: recentPosts,
                        groupMembers: groupMembers,
                        groupData: groupData,
                      ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentGroupName,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTextStyles.normalTextColor(isDarkMode),
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
                                    (groupData!['privacy'] as String? ??
                                                'Công khai') ==
                                            'Công khai'
                                        ? Colors.grey.shade200
                                        : Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    (groupData!['privacy'] as String? ??
                                                'Công khai') ==
                                            'Công khai'
                                        ? Icons.public
                                        : Icons.lock,
                                    size: 16,
                                    color: Colors.grey.shade700,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    groupData!['privacy'] as String? ??
                                        'Công khai',
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
                              style: TextStyle(
                                color: AppTextStyles.normalTextColor(
                                  isDarkMode,
                                ),
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              ' thành viên',
                              style: TextStyle(
                                color: AppTextStyles.subTextColor(isDarkMode),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 16.0,
            ),
            child: GroupActionButtonsWidget(
              groupId: widget.groupId,
              groupName: _currentGroupName,
              isLoading: isLoading && groupData == null,
              isMember: isMember,
              isPreviewMode: widget.isPreviewMode,
              groupPrivacy: groupData!['privacy'] as String? ?? 'Công khai',
              onJoinGroup:
                  widget.isPreviewMode
                      ? () => Navigator.pop(context, 'join_group')
                      : _joinGroupInternally,
              onLeaveGroup: () {
                CommunityGroup communityGroup = CommunityGroup();
                communityGroup.leaveGroup(
                  context: context,
                  groupId: widget.groupId,
                  groupName: _currentGroupName,
                  mounted: mounted,
                  isDarkMode: isDarkMode,
                  loadGroupData: _loadGroupData,
                );
              },
              isAdmin: checkIfCurrentUserIsAdmin(),
              onInviteMember: () {
                CommunityGroup communityGroup = CommunityGroup();
                communityGroup.inviteMember(
                  groupId: widget.groupId,
                  groupName: widget.groupName,
                  userFollowers:
                      groupMembers.map((m) => m['uid'] as String).toList(),
                  mounted: mounted,
                  loadGroupData: _loadGroupData,
                );
              },
              onManageGroup: () {
                CommunityGroup communityGroup = CommunityGroup();
                communityGroup.navigateToManagementPage(
                  groupId: widget.groupId,
                  mounted: mounted,
                  loadGroupData: _loadGroupData,
                );
              },
              onReportGroup: () {
                CommunityGroup communityGroup = CommunityGroup();
                communityGroup.reportGroup(
                  context,
                  groupId: widget.groupId,
                  groupName: _currentGroupName,
                );
              },
              onDeleteGroup: _deleteGroup,
            ),
          ),
          if (isMember && !widget.isPreviewMode && !isLoading) ...[
            // Padding(
            //   padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 8.0),
            //   child: _buildGroupChatButton(isDarkMode),
            // ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
              child: CreatePostBarWidget(
                onTapTextField: () {
                  CommunityGroup communityGroup = CommunityGroup();
                  communityGroup.navigateToCreatePostPage(
                    groupId: widget.groupId,
                    groupName: widget.groupName,
                    loadGroupData: _loadGroupData,
                    mounted: mounted,
                  );
                },
                onTapPhoto: () {
                  CommunityGroup communityGroup = CommunityGroup();
                  communityGroup.navigateToCreatePostPage(
                    groupId: widget.groupId,
                    groupName: widget.groupName,
                    loadGroupData: _loadGroupData,
                    mounted: mounted,
                  );
                },
                onTapCamera: () {
                  CommunityGroup communityGroup = CommunityGroup();
                  communityGroup.navigateToCreatePostPage(
                    groupId: widget.groupId,
                    groupName: widget.groupName,
                    loadGroupData: _loadGroupData,
                    mounted: mounted,
                  );
                },
                onTapMic: () {
                  CommunityGroup communityGroup = CommunityGroup();
                  communityGroup.navigateToCreatePostPage(
                    groupId: widget.groupId,
                    groupName: widget.groupName,
                    loadGroupData: _loadGroupData,
                    mounted: mounted,
                  );
                },
              ),
            ),
          ],
          UploadProgressWidget(),
        ],
      ),
    );
  }

  Widget _buildPostsSection(bool isDarkMode) {
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
          style: TextStyle(
            fontSize: 16,
            color: AppTextStyles.normalTextColor(isDarkMode),
          ),
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
        return GroupPostCardWidget(
          userName: post.authorUsername ?? 'Người dùng',
          userAvatarUrl: post.authorAvatarUrl ?? '',
          postTitle: post.title,
          postText: post.text ?? '',
          postImageUrls: post.imageUrls,
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
          onDeletePost:
              () => _DeletePostGroup(isDarkMode, post.postId, post.imageUrls),
        );
      },
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: AppBackgroundStyles.mainBackground(isDarkMode),
      appBar: AppBar(
        title: Text(
          widget.isPreviewMode && !isMember
              ? 'Xem trước nhóm'
              : _currentGroupName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTextStyles.normalTextColor(isDarkMode),
          ),
        ),
        backgroundColor: AppBackgroundStyles.secondaryBackground(isDarkMode),

        // foregroundColor: Colors.black,
        iconTheme: IconThemeData(
          color: AppIconStyles.iconPrimary(
            isDarkMode,
          ), // Đổi màu mũi tên tại đây
        ),
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
                      color: AppTextStyles.normalTextColor(isDarkMode),
                      fontSize: 16,
                    ),
                  ),
                ),
              )
              : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildGroupHeader(isDarkMode),
                    _buildPostsSection(isDarkMode),
                    const Divider(
                      height: 1,
                      thickness: 0.5,
                      // indent: 16,
                      // endIndent: 16,
                    ),
                    // const SizedBox(height: 10),
                    // _buildActivitySectionFromData(),
                  ],
                ),
              ),
    );
  }
}
