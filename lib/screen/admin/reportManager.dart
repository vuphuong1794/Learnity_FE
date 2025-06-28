import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:learnity/screen/admin/common/appbar.dart';
import 'package:learnity/screen/admin/common/sidebar.dart';
import 'package:learnity/screen/Group/group_content_screen.dart'; // Import GroupContentScreen

class Complaint {
  final String id;
  final String reporterId;
  final String reporterName;
  final String reporterEmail;
  final String reason;
  final String details;
  final String priority;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? reportedGroupId;
  final String? reportedGroupName;
  final String? postId;

  Complaint({
    required this.id,
    required this.reporterId,
    required this.reporterName,
    required this.reporterEmail,
    required this.reason,
    required this.details,
    required this.priority,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.reportedGroupId,
    this.reportedGroupName,
    this.postId,
  });

  factory Complaint.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Complaint(
      id: doc.id,
      reporterId: data['reporterId'] ?? '',
      reporterName: data['reporterName'] ?? '',
      reporterEmail: data['reporterEmail'] ?? '',
      reason: data['reason'] ?? '',
      details: data['details'] ?? '',
      priority: data['priority'] ?? 'low',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reportedGroupId: data['reportedGroupId'],
      reportedGroupName: data['reportedGroupName'],
      postId: data['postId'],
    );
  }

  String get reportType {
    if (postId != null) return 'Bài viết';
    if (reportedGroupId != null) return 'Nhóm';
    return 'Người dùng';
  }
}

class Reportmanager extends StatefulWidget {
  const Reportmanager({super.key});

  @override
  State<Reportmanager> createState() => _ReportmanagerState();
}

class _ReportmanagerState extends State<Reportmanager> {
  final ScrollController _scrollController = ScrollController();
  final List<Complaint> _complaints = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool _hasMoreData = true;
  DocumentSnapshot? _lastDocument;
  final int _pageSize = 10;

  // Statistics
  int _totalTickets = 0;
  int _pendingTickets = 0;
  int _closedTickets = 0;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
    _loadMore();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _hasMoreData) {
        _loadMore();
      }
    });
  }

  Future<void> _loadStatistics() async {
    try {
      // Load statistics from both collections
      final groupReportsQuery =
          await _firestore.collection('groupReports').get();
      final postReportsQuery =
          await _firestore.collection('post_reports').get();

      final totalDocs = groupReportsQuery.docs + postReportsQuery.docs;
      final pendingDocs =
          totalDocs
              .where((doc) => (doc.data()['status'] ?? 'pending') == 'pending')
              .length;
      final closedDocs =
          totalDocs
              .where((doc) => (doc.data()['status'] ?? 'pending') == 'closed')
              .length;

      setState(() {
        _totalTickets = totalDocs.length;
        _pendingTickets = pendingDocs;
        _closedTickets = closedDocs;
      });
    } catch (e) {
      print('Error loading statistics: $e');
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMoreData) return;

    setState(() => _isLoading = true);

    try {
      // Load from groupReports collection
      Query groupQuery = _firestore
          .collection('groupReports')
          .orderBy('createdAt', descending: true)
          .limit(_pageSize);

      if (_lastDocument != null) {
        groupQuery = groupQuery.startAfterDocument(_lastDocument!);
      }

      final groupQuerySnapshot = await groupQuery.get();

      // Load from post_reports collection
      Query postQuery = _firestore
          .collection('post_reports')
          .orderBy('reportedAt', descending: true)
          .limit(_pageSize);

      final postQuerySnapshot = await postQuery.get();

      List<Complaint> newComplaints = [];

      // Process group reports
      for (var doc in groupQuerySnapshot.docs) {
        newComplaints.add(Complaint.fromFirestore(doc));
      }

      // Process post reports
      for (var doc in postQuerySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        newComplaints.add(
          Complaint(
            id: doc.id,
            reporterId: data['userId'] ?? '',
            reporterName:
                'User', // You might need to fetch this from users collection
            reporterEmail: '',
            reason: data['reason'] ?? '',
            details: '',
            priority: 'medium',
            status: 'pending',
            createdAt:
                (data['reportedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            updatedAt:
                (data['reportedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            postId: data['postId'],
          ),
        );
      }

      // Sort by creation date
      newComplaints.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      setState(() {
        _complaints.addAll(newComplaints);
        _isLoading = false;

        if (groupQuerySnapshot.docs.isNotEmpty) {
          _lastDocument = groupQuerySnapshot.docs.last;
        }

        if (groupQuerySnapshot.docs.length < _pageSize &&
            postQuerySnapshot.docs.length < _pageSize) {
          _hasMoreData = false;
        }
      });
    } catch (e) {
      print('Error loading complaints: $e');
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi tải dữ liệu: $e')));
    }
  }

  Future<void> _updateComplaintStatus(
    String complaintId,
    String newStatus,
  ) async {
    try {
      // Try to update in groupReports first
      final groupDoc =
          await _firestore.collection('groupReports').doc(complaintId).get();

      if (groupDoc.exists) {
        await _firestore.collection('groupReports').doc(complaintId).update({
          'status': newStatus,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Try post_reports collection
        await _firestore.collection('post_reports').doc(complaintId).update({
          'status': newStatus,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Update local state
      setState(() {
        final index = _complaints.indexWhere((c) => c.id == complaintId);
        if (index != -1) {
          final complaint = _complaints[index];
          _complaints[index] = Complaint(
            id: complaint.id,
            reporterId: complaint.reporterId,
            reporterName: complaint.reporterName,
            reporterEmail: complaint.reporterEmail,
            reason: complaint.reason,
            details: complaint.details,
            priority: complaint.priority,
            status: newStatus,
            createdAt: complaint.createdAt,
            updatedAt: DateTime.now(),
            reportedGroupId: complaint.reportedGroupId,
            reportedGroupName: complaint.reportedGroupName,
            postId: complaint.postId,
          );
        }
      });

      _loadStatistics(); // Refresh statistics

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Cập nhật trạng thái thành công')));
    } catch (e) {
      print('Error updating status: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi cập nhật: $e')));
    }
  }

  // Thêm chức năng xem trước nhóm bị báo cáo
  Future<void> _previewReportedGroup(String groupId, String? groupName) async {
    try {
      // Kiểm tra xem nhóm có tồn tại không
      final groupDoc =
          await _firestore.collection('communityGroups').doc(groupId).get();

      if (!groupDoc.exists) {
        if (mounted) {
          Get.snackbar(
            "Thông báo",
            "Nhóm không tồn tại hoặc đã bị xóa",
            backgroundColor: Colors.orange.withOpacity(0.9),
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
        }
        return;
      }

      // Điều hướng đến trang GroupContentScreen với isPreviewMode = true (admin mode)
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => GroupcontentScreen(
                groupId: groupId,
                groupName: groupName ?? 'Nhóm bị báo cáo',
                isPreviewMode: true, // Admin có thể xem nhóm ở chế độ preview
                isAdminView: true, // Flag để phân biệt admin view
              ),
        ),
      );
    } catch (e) {
      print('Error previewing reported group: $e');
      if (mounted) {
        Get.snackbar(
          "Lỗi",
          "Không thể xem trước nhóm: $e",
          backgroundColor: Colors.red.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      }
    }
  }

  // Thêm chức năng xóa bài viết
  Future<void> _deletePost(String postId) async {
    try {
      // Hiển thị dialog xác nhận
      final confirmed = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('Xác nhận xóa bài viết'),
              content: Text(
                'Bạn có chắc chắn muốn xóa bài viết này? Hành động này không thể hoàn tác.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Hủy'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: Text('Xóa'),
                ),
              ],
            ),
      );

      if (confirmed != true) return;

      // Xóa bài viết từ Firestore
      await _firestore.collection('posts').doc(postId).delete();

      // Xóa các báo cáo liên quan đến bài viết này
      final reportsQuery =
          await _firestore
              .collection('post_reports')
              .where('postId', isEqualTo: postId)
              .get();

      final batch = _firestore.batch();
      for (var doc in reportsQuery.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Cập nhật UI
      setState(() {
        _complaints.removeWhere((c) => c.postId == postId);
      });

      _loadStatistics(); // Refresh statistics

      Get.snackbar(
        "Thành công",
        "Đã xóa bài viết và các báo cáo liên quan",
        backgroundColor: Colors.green.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      print('Error deleting post: $e');
      Get.snackbar(
        "Lỗi",
        "Không thể xóa bài viết: $e",
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    }
  }

  // Thêm chức năng xóa nhóm
  Future<void> _deleteGroup(String groupId, String? groupName) async {
    try {
      // Hiển thị dialog xác nhận
      final confirmed = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('Xác nhận xóa nhóm'),
              content: Text(
                'Bạn có chắc chắn muốn xóa nhóm "${groupName ?? 'Unknown'}"? '
                'Tất cả bài viết, thành viên và dữ liệu liên quan sẽ bị xóa. '
                'Hành động này không thể hoàn tác.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Hủy'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: Text('Xóa'),
                ),
              ],
            ),
      );

      if (confirmed != true) return;

      // Xóa nhóm từ Firestore
      await _firestore.collection('communityGroups').doc(groupId).delete();

      // Xóa các báo cáo liên quan đến nhóm này
      final reportsQuery =
          await _firestore
              .collection('groupReports')
              .where('reportedGroupId', isEqualTo: groupId)
              .get();

      final batch = _firestore.batch();
      for (var doc in reportsQuery.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Cập nhật UI
      setState(() {
        _complaints.removeWhere((c) => c.reportedGroupId == groupId);
      });

      _loadStatistics(); // Refresh statistics

      Get.snackbar(
        "Thành công",
        "Đã xóa nhóm và các báo cáo liên quan",
        backgroundColor: Colors.green.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      print('Error deleting group: $e');
      Get.snackbar(
        "Lỗi",
        "Không thể xóa nhóm: $e",
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    }
  }

  // Thêm chức năng khóa/mở khóa nhóm
  Future<void> _toggleGroupLock(String groupId, String? groupName) async {
    try {
      // Lấy thông tin hiện tại của nhóm
      final groupDoc =
          await _firestore.collection('communityGroups').doc(groupId).get();

      if (!groupDoc.exists) {
        Get.snackbar(
          "Thông báo",
          "Nhóm không tồn tại",
          backgroundColor: Colors.orange.withOpacity(0.9),
          colorText: Colors.white,
        );
        return;
      }

      final groupData = groupDoc.data() as Map<String, dynamic>;
      final isCurrentlyLocked = groupData['isLocked'] ?? false;

      // Hiển thị dialog xác nhận
      final confirmed = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text(isCurrentlyLocked ? 'Mở khóa nhóm' : 'Khóa nhóm'),
              content: Text(
                isCurrentlyLocked
                    ? 'Bạn có chắc chắn muốn mở khóa nhóm "${groupName ?? 'Unknown'}"? '
                        'Thành viên sẽ có thể đăng bài và bình luận trở lại.'
                    : 'Bạn có chắc chắn muốn khóa nhóm "${groupName ?? 'Unknown'}"? '
                        'Thành viên sẽ không thể đăng bài mới hoặc bình luận.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Hủy'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(
                    foregroundColor:
                        isCurrentlyLocked ? Colors.green : Colors.orange,
                  ),
                  child: Text(isCurrentlyLocked ? 'Mở khóa' : 'Khóa'),
                ),
              ],
            ),
      );

      if (confirmed != true) return;

      // Cập nhật trạng thái khóa của nhóm
      await _firestore.collection('communityGroups').doc(groupId).update({
        'isLocked': !isCurrentlyLocked,
        'lockedAt': !isCurrentlyLocked ? FieldValue.serverTimestamp() : null,
        'lockedBy':
            !isCurrentlyLocked
                ? 'admin'
                : null, // Có thể thay bằng ID admin thực tế
      });

      Get.snackbar(
        "Thành công",
        isCurrentlyLocked ? "Đã mở khóa nhóm" : "Đã khóa nhóm",
        backgroundColor: Colors.green.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      print('Error toggling group lock: $e');
      Get.snackbar(
        "Lỗi",
        "Không thể ${groupName != null ? 'thay đổi trạng thái khóa nhóm' : 'thực hiện thao tác'}: $e",
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'closed':
      case 'resolved':
        return Colors.green;
      case 'open':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildComplaintCard(Complaint c) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row với ID và thời gian
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ID: ${c.id.substring(0, 8)}...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontFamily: 'monospace',
                  ),
                ),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(c.createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),

            SizedBox(height: 8),

            // Người báo cáo
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.reporterName.isNotEmpty
                            ? c.reporterName
                            : 'Unknown User',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      if (c.reporterEmail.isNotEmpty)
                        Text(
                          c.reporterEmail,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 12),

            // Lý do báo cáo
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.report_problem, size: 16, color: Colors.orange),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lý do:',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        c.reason,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (c.details.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            c.details,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 12),

            // Loại báo cáo và tags
            Row(
              children: [
                Icon(Icons.category, size: 16, color: Colors.purple),
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.purple.withOpacity(0.3)),
                  ),
                  child: Text(
                    c.reportType,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.purple[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                SizedBox(width: 8),

                // Priority tag
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _priorityColor(c.priority).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _priorityColor(c.priority).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    c.priority.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      color: _priorityColor(c.priority),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            // Thêm nút xem thông tin nhóm nếu là báo cáo nhóm
            if (c.reportedGroupId != null) ...[
              SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.group, size: 16, color: Colors.blue[700]),
                        SizedBox(width: 8),
                        Text(
                          'Nhóm bị báo cáo:',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      c.reportedGroupName ?? 'Tên nhóm không xác định',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[800],
                      ),
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed:
                              () => _previewReportedGroup(
                                c.reportedGroupId!,
                                c.reportedGroupName,
                              ),
                          icon: Icon(Icons.visibility, size: 16),
                          label: Text('Xem'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            textStyle: TextStyle(fontSize: 12),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed:
                              () => _toggleGroupLock(
                                c.reportedGroupId!,
                                c.reportedGroupName,
                              ),
                          icon: Icon(Icons.lock, size: 16),
                          label: Text('Khóa/Mở'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            textStyle: TextStyle(fontSize: 12),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed:
                              () => _deleteGroup(
                                c.reportedGroupId!,
                                c.reportedGroupName,
                              ),
                          icon: Icon(Icons.delete_forever, size: 16),
                          label: Text('Xóa'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            textStyle: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            // Thêm nút xóa bài viết nếu là báo cáo bài viết
            if (c.postId != null) ...[
              SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.article, size: 16, color: Colors.green[700]),
                        SizedBox(width: 8),
                        Text(
                          'Bài viết bị báo cáo:',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      'ID: ${c.postId}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[800],
                        fontFamily: 'monospace',
                      ),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => _deletePost(c.postId!),
                      icon: Icon(Icons.delete_forever, size: 16),
                      label: Text('Xóa bài viết'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        textStyle: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: 12),

            // Status và actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _statusColor(c.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _statusColor(c.status).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _statusColor(c.status),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        c.status.toUpperCase(),
                        style: TextStyle(
                          color: _statusColor(c.status),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'resolve':
                        _updateComplaintStatus(c.id, 'resolved');
                        break;
                      case 'close':
                        _updateComplaintStatus(c.id, 'closed');
                        break;
                      case 'reopen':
                        _updateComplaintStatus(c.id, 'pending');
                        break;
                    }
                  },
                  itemBuilder: (context) {
                    List<PopupMenuEntry<String>> items = [];

                    if (c.status.toLowerCase() != 'resolved') {
                      items.add(
                        PopupMenuItem(
                          value: 'resolve',
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 16,
                                color: Colors.green,
                              ),
                              SizedBox(width: 8),
                              Text('Giải quyết'),
                            ],
                          ),
                        ),
                      );
                    }
                    if (c.status.toLowerCase() != 'closed') {
                      items.add(
                        PopupMenuItem(
                          value: 'close',
                          child: Row(
                            children: [
                              Icon(Icons.close, size: 16, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Đóng'),
                            ],
                          ),
                        ),
                      );
                    }
                    if (c.status.toLowerCase() == 'closed' ||
                        c.status.toLowerCase() == 'resolved') {
                      items.add(
                        PopupMenuItem(
                          value: 'reopen',
                          child: Row(
                            children: [
                              Icon(Icons.refresh, size: 16, color: Colors.blue),
                              SizedBox(width: 8),
                              Text('Mở lại'),
                            ],
                          ),
                        ),
                      );
                    }

                    return items;
                  },
                  icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String title, int number, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        margin: EdgeInsets.symmetric(horizontal: 4),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              SizedBox(height: 6),
              Text(
                number.toString(),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                title,
                style: TextStyle(fontSize: 10, color: Colors.grey),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE8F5E8),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: CustomAppBar(),
      ),
      drawer: Sidebar(),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 16),
            Text(
              "Danh sách khiếu nại",
              style: TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                children: [
                  _buildInfoCard(
                    Icons.local_offer,
                    "Tổng báo cáo",
                    _totalTickets,
                    Colors.purple,
                  ),
                  _buildInfoCard(
                    Icons.pending,
                    "Đang chờ",
                    _pendingTickets,
                    Colors.orange,
                  ),
                  _buildInfoCard(
                    Icons.check_circle,
                    "Đã xử lý",
                    _closedTickets,
                    Colors.green,
                  ),
                ],
              ),
            ),
            // Refresh button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _complaints.clear();
                        _lastDocument = null;
                        _hasMoreData = true;
                      });
                      _loadStatistics();
                      _loadMore();
                    },
                    icon: Icon(Icons.refresh),
                    label: Text('Làm mới'),
                  ),
                ],
              ),
            ),
            // Card List - Mobile Friendly
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.only(bottom: 16),
                itemCount: _complaints.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < _complaints.length) {
                    return _buildComplaintCard(_complaints[index]);
                  } else {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 8),
                            Text(
                              'Đang tải thêm...',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
