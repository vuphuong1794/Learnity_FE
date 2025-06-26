// report_group_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:learnity/theme/theme.dart';

class ReportGroupPage extends StatefulWidget {
  final String groupId;
  final String groupName;

  const ReportGroupPage({
    Key? key,
    required this.groupId,
    required this.groupName,
  }) : super(key: key);

  @override
  State<ReportGroupPage> createState() => _ReportGroupPageState();
}

class _ReportGroupPageState extends State<ReportGroupPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _selectedReason = '';
  final TextEditingController _detailsController = TextEditingController();
  bool _isLoading = false;

  final List<Map<String, dynamic>> _reportReasons = [
    {
      'title': 'Nội dung không phù hợp',
      'subtitle': 'Nội dung có thể gây tổn hại hoặc không phù hợp',
      'icon': Icons.report_problem,
      'color': Colors.red,
    },
    {
      'title': 'Spam hoặc quảng cáo',
      'subtitle': 'Nhóm chứa nhiều spam hoặc quảng cáo',
      'icon': Icons.block,
      'color': Colors.orange,
    },
    {
      'title': 'Bạo lực hoặc đe dọa',
      'subtitle': 'Nội dung có yếu tố bạo lực hoặc đe dọa',
      'icon': Icons.dangerous,
      'color': Colors.red.shade700,
    },
    {
      'title': 'Thông tin sai lệch',
      'subtitle': 'Chia sẻ thông tin không chính xác',
      'icon': Icons.info_outline,
      'color': Colors.blue,
    },
    {
      'title': 'Quấy rối hoặc bắt nạt',
      'subtitle': 'Hành vi quấy rối các thành viên khác',
      'icon': Icons.person_off,
      'color': Colors.purple,
    },
    {
      'title': 'Vi phạm bản quyền',
      'subtitle': 'Sử dụng nội dung không có bản quyền',
      'icon': Icons.copyright,
      'color': Colors.teal,
    },
    {
      'title': 'Khác',
      'subtitle': 'Lý do khác (vui lòng mô tả chi tiết)',
      'icon': Icons.more_horiz,
      'color': Colors.grey,
    },
  ];

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_selectedReason.isEmpty) {
      Get.snackbar(
        'Lỗi',
        'Vui lòng chọn lý do báo cáo',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
      return;
    }

    if (_selectedReason == 'Khác' && _detailsController.text.trim().isEmpty) {
      Get.snackbar(
        'Lỗi',
        'Vui lòng mô tả chi tiết lý do báo cáo',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
      return;
    }

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

    setState(() {
      _isLoading = true;
    });

    try {
      // Lấy thông tin user hiện tại
      final userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      final userData = userDoc.data();
      final reporterName = userData?['username'] ?? 'Người dùng ẩn danh';
      final reporterEmail = currentUser.email ?? '';

      // Lấy thông tin nhóm bị báo cáo
      final groupDoc =
          await _firestore
              .collection('communityGroups')
              .doc(widget.groupId)
              .get();

      final groupData = groupDoc.data();

      // Tạo document báo cáo
      final reportData = {
        'reportId': _firestore.collection('groupReports').doc().id,
        'reportedGroupId': widget.groupId,
        'reportedGroupName': widget.groupName,
        'reportedGroupData': groupData ?? {},
        'reporterId': currentUser.uid,
        'reporterName': reporterName,
        'reporterEmail': reporterEmail,
        'reason': _selectedReason,
        'details': _detailsController.text.trim(),
        'status': 'pending', // pending, reviewing, resolved, dismissed
        'priority': _getPriorityLevel(_selectedReason),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'reviewedBy': null,
        'reviewedAt': null,
        'reviewNotes': '',
        'actionTaken':
            '', // warning, temporary_ban, permanent_ban, content_removal, etc.
      };

      // Lưu báo cáo vào Firestore
      await _firestore
          .collection('groupReports')
          .doc(reportData['reportId'])
          .set(reportData);

      // Cập nhật số lượng báo cáo cho nhóm
      await _updateGroupReportCount();

      // Kiểm tra xem có cần tự động xử lý không (nếu có quá nhiều báo cáo)
      await _checkAutoModeration();

      if (mounted) {
        Get.snackbar(
          'Thành công',
          'Báo cáo đã được gửi thành công. Chúng tôi sẽ xem xét và xử lý sớm nhất có thể.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withOpacity(0.1),
          colorText: Colors.green,
          duration: Duration(seconds: 3),
        );

        Navigator.pop(context, true);
      }
    } catch (e) {
      print('Error submitting report: $e');
      if (mounted) {
        Get.snackbar(
          'Lỗi',
          'Không thể gửi báo cáo. Vui lòng thử lại sau.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.1),
          colorText: Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getPriorityLevel(String reason) {
    switch (reason) {
      case 'Bạo lực hoặc đe dọa':
      case 'Quấy rối hoặc bắt nạt':
        return 'high';
      case 'Nội dung không phù hợp':
      case 'Thông tin sai lệch':
        return 'medium';
      default:
        return 'low';
    }
  }

  Future<void> _updateGroupReportCount() async {
    try {
      final groupRef = _firestore
          .collection('communityGroups')
          .doc(widget.groupId);

      await _firestore.runTransaction((transaction) async {
        final groupDoc = await transaction.get(groupRef);

        if (groupDoc.exists) {
          final currentReportCount = groupDoc.data()?['reportCount'] ?? 0;
          transaction.update(groupRef, {
            'reportCount': currentReportCount + 1,
            'lastReportedAt': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      print('Error updating group report count: $e');
    }
  }

  Future<void> _checkAutoModeration() async {
    try {
      // Lấy số lượng báo cáo của nhóm trong 24h qua
      final yesterday = DateTime.now().subtract(Duration(hours: 24));

      final recentReports =
          await _firestore
              .collection('groupReports')
              .where('reportedGroupId', isEqualTo: widget.groupId)
              .where('createdAt', isGreaterThan: Timestamp.fromDate(yesterday))
              .get();

      // Nếu có quá 10 báo cáo trong 24h, tự động đánh dấu nhóm để review
      if (recentReports.docs.length >= 10) {
        await _firestore
            .collection('communityGroups')
            .doc(widget.groupId)
            .update({
              'needsReview': true,
              'autoFlaggedAt': FieldValue.serverTimestamp(),
              'autoFlagReason':
                  'Multiple reports in 24h: ${recentReports.docs.length}',
            });
      }
    } catch (e) {
      print('Error in auto moderation check: $e');
    }
  }

  Widget _buildReasonTile(Map<String, dynamic> reason) {
    final isSelected = _selectedReason == reason['title'];

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedReason = reason['title'];
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? reason['color'] : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
              color:
                  isSelected ? reason['color'].withOpacity(0.05) : Colors.white,
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: reason['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(reason['icon'], color: reason['color'], size: 24),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reason['title'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        reason['subtitle'],
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: reason['color'], size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Báo cáo nhóm',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.black),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.black,
        elevation: 0.5,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Group info header
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.group, color: Colors.blue, size: 24),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Báo cáo nhóm',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                widget.groupName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  // Instructions
                  Text(
                    'Vui lòng chọn lý do báo cáo:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Báo cáo của bạn sẽ được xem xét và xử lý một cách nghiêm túc. Vui lòng chọn lý do phù hợp nhất.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),

                  SizedBox(height: 20),

                  // Report reasons
                  ..._reportReasons.map((reason) => _buildReasonTile(reason)),

                  // Details text field (show when "Khác" is selected or any reason is selected)
                  if (_selectedReason.isNotEmpty) ...[
                    SizedBox(height: 16),
                    Text(
                      _selectedReason == 'Khác'
                          ? 'Mô tả chi tiết lý do báo cáo *'
                          : 'Thông tin bổ sung (không bắt buộc)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: _detailsController,
                      maxLines: 4,
                      maxLength: 500,
                      decoration: InputDecoration(
                        hintText:
                            _selectedReason == 'Khác'
                                ? 'Vui lòng mô tả chi tiết lý do báo cáo...'
                                : 'Chia sẻ thêm thông tin nếu cần...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.blue.shade300),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.all(16),
                      ),
                    ),
                  ],

                  SizedBox(height: 24),

                  // Privacy notice
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue, size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Báo cáo của bạn sẽ được giữ bí mật. Chúng tôi có thể liên hệ với bạn nếu cần thêm thông tin.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue.shade700,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Submit button
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child:
                      _isLoading
                          ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : Text(
                            'Gửi báo cáo',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
