import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:learnity/screen/adminPage/postManager.dart';
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

class AdminViewScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  final bool isPreviewMode;
  final bool isAdminView;

  const AdminViewScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    this.isPreviewMode = false,
    this.isAdminView = false,
  });

  @override
  State<AdminViewScreen> createState() => _AdminViewScreenState();
}

class _AdminViewScreenState extends State<AdminViewScreen> {
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
      final success = await _groupApi.deletePostAdmin(
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
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
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
          isAdmin: true,
          onLikePressed: () => {},
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
          onSharePressed: () {},
          postAuthorUid: post.authorUid,
          onDeletePost: () {
            _DeletePostGroup(isDarkMode, post.postId, post.imageUrls);
          },
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
                    const SizedBox(height: 16),
                    Text(
                      'Bài viết',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTextStyles.normalTextColor(isDarkMode),
                      ),
                      textAlign: TextAlign.center,
                    ),
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
