import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:learnity/theme/theme.dart';

import '../../api/group_api.dart';

class ManageJoinRequestsScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const ManageJoinRequestsScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<ManageJoinRequestsScreen> createState() =>
      _ManageJoinRequestsScreenState();
}

class _ManageJoinRequestsScreenState extends State<ManageJoinRequestsScreen> {
  final GroupApi _groupApi = GroupApi();
  List<Map<String, dynamic>> _joinRequests = [];
  bool _isLoading = true;
  bool _hasMadeChanges = false;
  Set<String> _processingIds = {};
  bool _isApprovingAll = false;

  @override
  void initState() {
    super.initState();
    _fetchJoinRequests();
  }

  Future<void> _fetchJoinRequests() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final requests = await _groupApi.getJoinRequests(widget.groupId);
      if (mounted) {
        setState(() {
          _joinRequests = requests;
        });
      }
    } catch (e) {
      Get.snackbar("Lỗi", "Không thể tải danh sách yêu cầu: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptRequest(Map<String, dynamic> requestData) async {
    final requestingUserId = requestData['uid']?.toString();
    if (requestingUserId == null) return;

    setState(() => _processingIds.add(requestingUserId));

    final success = await _groupApi.acceptJoinRequest(
      widget.groupId,
      widget.groupName,
      requestData,
    );

    if (mounted) {
      if (success) {
        setState(() {
          _hasMadeChanges = true;
          _joinRequests.removeWhere((req) => req['uid'] == requestingUserId);
        });
        Get.snackbar(
          "Thành công",
          "${requestData['username'] ?? 'Người dùng'} đã được thêm vào nhóm.",
        );
      } else {
        Get.snackbar("Lỗi", "Không thể duyệt yêu cầu. Vui lòng thử lại.");
      }
      setState(() => _processingIds.remove(requestingUserId));
    }
  }

  // Từ chôí
  Future<void> _denyJoinRequest(String requestingUserId) async {
    setState(() => _processingIds.add(requestingUserId));

    final success = await _groupApi.denyJoinRequest(
      widget.groupId,
      requestingUserId,
    );

    if (mounted) {
      if (success) {
        setState(() {
          _hasMadeChanges = true;
          _joinRequests.removeWhere((req) => req['uid'] == requestingUserId);
        });
        Get.snackbar("Thông báo", "Đã từ chối yêu cầu tham gia.");
      } else {
        Get.snackbar("Lỗi", "Không thể từ chối yêu cầu. Vui lòng thử lại.");
      }
      setState(() => _processingIds.remove(requestingUserId));
    }
  }

  Future<void> _confirmAcceptAllRequests() async {
    if (_joinRequests.isEmpty || _isApprovingAll) return;

    final bool? confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Duyệt tất cả yêu cầu?'),
        content: Text(
          'Bạn có chắc chắn muốn duyệt tất cả ${_joinRequests.length} yêu cầu tham gia đang chờ không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Duyệt tất cả'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _accptAllRequests();
    }
  }

  Future<void> _accptAllRequests() async {
    if (!mounted) return;
    setState(() => _isApprovingAll = true);

    final List<Map<String, dynamic>> requestsToProcess = List.from(
      _joinRequests,
    );
    for (var request in requestsToProcess) {
      final uid = request['uid']?.toString();
      if (uid == null || _processingIds.contains(uid)) continue;
      await _acceptRequest(request);
    }

    if (mounted) {
      await _fetchJoinRequests();
      setState(() => _isApprovingAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Yêu cầu tham gia nhóm',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
        ),
        centerTitle: true,
        backgroundColor: AppColors.background,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context,true);
          },
          icon: Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: Container(
        color: AppColors.background,
        child: RefreshIndicator(
          onRefresh: _fetchJoinRequests,
          child: Column(
            children: [
              if (_joinRequests.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 12, 16, 8),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _confirmAcceptAllRequests,
                      icon: const Icon(Icons.done_all),
                      label: const Text("Duyệt tất cả"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonBg,
                        foregroundColor: AppColors.buttonText,
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
                    _isLoading && _joinRequests.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : _joinRequests.isEmpty
                        ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Text(
                              'Không có yêu cầu tham gia nào đang chờ duyệt.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        )
                        : ListView.separated(
                          itemCount: _joinRequests.length,
                          separatorBuilder:
                              (context, index) => const Divider(
                                height: 1,
                                indent: 16,
                                endIndent: 16,
                              ),
                          itemBuilder: (context, index) {
                            final request = _joinRequests[index];
                            final uid = request['uid']?.toString();
                            if (uid == null) return const SizedBox.shrink();

                            final userName =
                                request['username']?.toString() ?? '';
                            final userAvatarUrl =
                                request['avatarUrl']?.toString() ?? '';
                            final email = request['email']?.toString() ?? '';

                            final isProcessing = _processingIds.contains(uid);

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage:
                                    userAvatarUrl.isNotEmpty
                                        ? NetworkImage(userAvatarUrl)
                                        : null,
                                child:
                                    userAvatarUrl.isEmpty
                                        ? const Icon(Icons.person)
                                        : null,
                              ),
                              title: Text(
                                userName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                email,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey,
                                ),
                              ),
                              trailing:
                                  isProcessing
                                      ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              Icons.check_circle_outline,
                                              color: Colors.green.shade600,
                                            ),
                                            onPressed:
                                                () => _acceptRequest(request),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.highlight_off_rounded,
                                              color: Colors.red.shade600,
                                            ),
                                            onPressed:
                                                () => _denyJoinRequest(uid),
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
    );
  }
}
