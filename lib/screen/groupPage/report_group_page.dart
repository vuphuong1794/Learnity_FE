import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import 'package:provider/provider.dart';
import 'package:learnity/theme/theme.dart';
import 'package:learnity/theme/theme_provider.dart';

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

  void _showTopError(String message) {
    Flushbar(
      message: message,
      icon: Icon(Icons.error, color: Colors.white),
      duration: Duration(seconds: 3),
      backgroundColor: Colors.red,
      flushbarPosition: FlushbarPosition.TOP,
      margin: EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(12),
      animationDuration: Duration(milliseconds: 500),
    ).show(context);
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

      // Tạo document báo cáo
      final reportData = {
        'reportId': _firestore.collection('groupReports').doc().id,
        'reportedGroupId': widget.groupId,
        'reportedGroupName': widget.groupName,
        'reporterId': currentUser.uid,
        'reporterName': reporterName,
        'reporterEmail': reporterEmail,
        'reason': _selectedReason,
        'details': _detailsController.text.trim(),
        'status': 'pending',
        'priority': _getPriorityLevel(_selectedReason),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Lưu báo cáo vào Firestore
      await _firestore
          .collection('groupReports')
          .doc(reportData['reportId'])
          .set(reportData);

      // Cập nhật số lượng báo cáo cho nhóm
      await _updateGroupReportCount();

      // Kiểm tra tự động xử lý
      await _checkAutoModeration();

      if (mounted) {
        Get.snackbar(
          "Thành công",
          "Báo cáo đã được gửi thành công. Chúng tôi sẽ xem xét và xử lý sớm nhất có thể.",
          backgroundColor: Colors.blue.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('Error submitting report: $e');
      if (mounted) {
        _showTopError('Không thể gửi báo cáo. Vui lòng thử lại sau.');
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
      final yesterday = DateTime.now().subtract(Duration(hours: 24));
      final recentReports =
          await _firestore
              .collection('groupReports')
              .where('reportedGroupId', isEqualTo: widget.groupId)
              .where('createdAt', isGreaterThan: Timestamp.fromDate(yesterday))
              .get();

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

  Widget _buildReasonTile(bool isDarkMode, Map<String, dynamic> reason) {
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
                color: isSelected ? reason['color'] : AppBackgroundStyles.secondaryBackground(isDarkMode),
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
              color:
                  isSelected ? reason['color'].withOpacity(0.05) : AppBackgroundStyles.buttonBackground(isDarkMode),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08), // 👈 Độ mờ của bóng
                  blurRadius: 8, // 👈 Độ mờ lan ra
                  offset: const Offset(0, 4), // 👈 Đổ bóng xuống dưới
                ),
              ],
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
                          color: AppTextStyles.normalTextColor(isDarkMode),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        reason['subtitle'],
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTextStyles.subTextColor(isDarkMode),
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return WillPopScope(
      onWillPop: () async {
        if (_isLoading) return false; // Ngăn quay lại khi đang loading
        return true;
      },
      child: Scaffold(
        backgroundColor: AppBackgroundStyles.mainBackground(isDarkMode),
        appBar: AppBar(
          title: Text(
            'Báo cáo nhóm',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: AppBackgroundStyles.secondaryBackground(isDarkMode),
          foregroundColor: AppTextStyles.normalTextColor(isDarkMode),
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
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        // color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppBackgroundStyles.buttonBackground(isDarkMode),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1), // 👉 bóng nhẹ
                            blurRadius: 8,
                            offset: const Offset(0, 4), // đổ bóng phía dưới
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.group, color: AppIconStyles.iconPrimary(isDarkMode), size: 24),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Báo cáo nhóm',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTextStyles.normalTextColor(isDarkMode),
                                  ),
                                ),
                                Text(
                                  widget.groupName,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppTextStyles.normalTextColor(isDarkMode),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Vui lòng chọn lý do báo cáo:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTextStyles.normalTextColor(isDarkMode),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Báo cáo của bạn sẽ được xem xét và xử lý một cách nghiêm túc. Vui lòng chọn lý do phù hợp nhất.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTextStyles.subTextColor(isDarkMode),
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 20),
                    ..._reportReasons.map((reason) => _buildReasonTile(isDarkMode, reason)),
                    if (_selectedReason.isNotEmpty) ...[
                      SizedBox(height: 16),
                      Text(
                        _selectedReason == 'Khác'
                            ? 'Mô tả chi tiết lý do báo cáo *'
                            : 'Thông tin bổ sung (không bắt buộc)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTextStyles.normalTextColor(isDarkMode),
                        ),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: _detailsController,
                        style: TextStyle(color: AppTextStyles.normalTextColor(isDarkMode)),
                        maxLines: 4,
                        maxLength: 500,
                        decoration: InputDecoration(
                          hintText:
                              _selectedReason == 'Khác'
                                  ? 'Vui lòng mô tả chi tiết lý do báo cáo...'
                                  : 'Chia sẻ thêm thông tin nếu cần...',
                          hintStyle: TextStyle(
                            color: AppTextStyles.normalTextColor(isDarkMode).withOpacity(0.5),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.blue.shade300),
                          ),
                          filled: true,
                          fillColor: AppBackgroundStyles.buttonBackgroundSecondary(isDarkMode),
                          contentPadding: EdgeInsets.all(16),
                          counter: Builder(
                            builder: (context) {
                              final currentLength = _detailsController.text.length;
                              return Text(
                                '$currentLength/500',
                                style: TextStyle(
                                  color: AppTextStyles.subTextColor(isDarkMode),
                                  fontSize: 12,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: 24),
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
                          Icon(
                            Icons.info_outline,
                            color: AppIconStyles.iconPrimary(isDarkMode),
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Báo cáo của bạn sẽ được giữ bí mật. Chúng tôi có thể liên hệ với bạn nếu cần thêm thông tin.',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTextStyles.normalTextColor(isDarkMode),
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
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppBackgroundStyles.modalBackground(isDarkMode),
                border: Border(top: BorderSide(color: AppTextStyles.normalTextColor(isDarkMode).withOpacity(0.5))),
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppBackgroundStyles.buttonBackground(isDarkMode),
                      foregroundColor: AppTextStyles.buttonTextColor(isDarkMode),
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
      ),
    );
  }
}
