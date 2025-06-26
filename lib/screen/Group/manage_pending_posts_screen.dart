import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:learnity/api/group_api.dart';
import 'package:learnity/models/group_post_model.dart';

import 'package:provider/provider.dart';
import 'package:learnity/theme/theme.dart';
import 'package:learnity/theme/theme_provider.dart';

class ManagePendingPostsScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const ManagePendingPostsScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<ManagePendingPostsScreen> createState() =>
      _ManagePendingPostsScreenState();
}

class _ManagePendingPostsScreenState extends State<ManagePendingPostsScreen> {
  final GroupApi _groupApi = GroupApi();
  List<GroupPostModel> _pendingPosts = [];
  bool _isLoading = true;
  bool _isApprovingAll = false;
  @override
  void initState() {
    super.initState();
    _fetchPendingPosts();
  }

  Future<void> _fetchPendingPosts() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final posts = await _groupApi.getPendingPosts(widget.groupId);
    if (mounted) {
      setState(() {
        _pendingPosts = posts;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleApprove(GroupPostModel post) async {
    final success = await _groupApi.approvePost(
      groupId: widget.groupId,
      postId: post.postId,
      postData: post.toMap(),
    );
    if (success) {
      setState(() {
        _pendingPosts.removeWhere((p) => p.postId == post.postId);
      });
      Get.snackbar('Thành công', 'Đã duyệt bài viết.');
    } else {
      Get.snackbar('Lỗi', 'Có lỗi xảy ra, vui lòng thử lại.');
    }
  }

  Future<void> _handleApproveAll(bool isDarkMode) async {
    if (_pendingPosts.isEmpty) return;

    // Hiển thị dialog xác nhận
    bool? confirm = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: AppBackgroundStyles.modalBackground(isDarkMode),
        title: Text('Xác nhận duyệt tất cả', style: TextStyle(color: AppTextStyles.normalTextColor(isDarkMode))),
        content: Text(
          'Bạn có chắc chắn muốn duyệt tất cả ${_pendingPosts.length} bài viết đang chờ không?',
          style: TextStyle(color: AppTextStyles.normalTextColor(isDarkMode))
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('Hủy', style: TextStyle(color: AppTextStyles.subTextColor(isDarkMode))),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(
              backgroundColor: AppBackgroundStyles.buttonBackground(isDarkMode),
              foregroundColor: AppTextStyles.buttonTextColor(isDarkMode),
            ),
            child: const Text('Duyệt tất cả'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (mounted) setState(() => _isApprovingAll = true);

    final success = await _groupApi.approveAllPosts(
      groupId: widget.groupId,
      postsToApprove: _pendingPosts,
    );

    if (mounted) {
      if (success) {
        setState(() {
          _pendingPosts.clear();
        });
        Get.snackbar('Thành công', 'Đã duyệt tất cả các bài viết.');
      } else {
        Get.snackbar('Lỗi', 'Có lỗi xảy ra, vui lòng thử lại.');
        await _fetchPendingPosts();
      }
      setState(() => _isApprovingAll = false);
    }
  }

  Future<void> _handleReject(GroupPostModel post) async {
    bool? confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Xác nhận từ chối'),
        content: const Text(
          'Bạn có chắc chắn muốn từ chối và xóa vĩnh viễn bài viết này không?',
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
            ),
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await _groupApi.rejectPost(
      groupId: widget.groupId,
      postId: post.postId,
      imageUrl: post.imageUrl,
    );
    if (success) {
      setState(() {
        _pendingPosts.removeWhere((p) => p.postId == post.postId);
      });
      Get.snackbar('Thành công', 'Đã từ chối bài viết.');
    } else {
      Get.snackbar('Lỗi', 'Có lỗi xảy ra, vui lòng thử lại.');
    }
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
        title: Text(
          'Duyệt bài đăng',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context,true);
          },
          icon: Icon(Icons.arrow_back),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchPendingPosts,
        child: Column(
          children: [
            if (!_isLoading && _pendingPosts.isNotEmpty && !_isApprovingAll)
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 16, 8),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _handleApproveAll(isDarkMode);
                    },
                    icon: const Icon(Icons.done_all),
                    label: const Text("Duyệt tất cả"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppBackgroundStyles.buttonBackground(isDarkMode),
                      foregroundColor: AppTextStyles.buttonTextColor(isDarkMode),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _pendingPosts.isEmpty
                      ? Center(
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.3,
                            ),
                            Center(
                              child: Text(
                                'Không có bài viết nào đang chờ duyệt.',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppTextStyles.subTextColor(isDarkMode),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                      : ListView.builder(
                        itemCount: _pendingPosts.length,
                        itemBuilder: (context, index) {
                          final post = _pendingPosts[index];
                          return _buildPendingPostCard(isDarkMode, post);
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingPostCard(bool isDarkMode, GroupPostModel post) {
    return Card(
      color: AppBackgroundStyles.boxBackground(isDarkMode),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(post.authorAvatarUrl ?? ''),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorUsername ?? 'Người dùng',
                        style: TextStyle(color: AppTextStyles.normalTextColor(isDarkMode), fontWeight: FontWeight.bold),
                      ),
                      Text(
                        DateFormat(
                          'd MMM, HH:mm',
                          'vi_VN',
                        ).format(post.createdAt),
                        style: TextStyle(
                          color: AppTextStyles.subTextColor(isDarkMode),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (post.title != null)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 4.0,
              ),
              child: Text(
                post.title!,
                style: TextStyle(
                  color: AppTextStyles.normalTextColor(isDarkMode),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (post.text != null)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 4.0,
              ),
              child: Text(post.text!, style: TextStyle( color: AppTextStyles.normalTextColor(isDarkMode))),
            ),
          if (post.imageUrl != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  post.imageUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
          const Divider(height: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _handleReject(post),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Từ chối'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ),
              const SizedBox(height: 40, child: VerticalDivider(width: 1)),
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _handleApprove(post),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Duyệt'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
