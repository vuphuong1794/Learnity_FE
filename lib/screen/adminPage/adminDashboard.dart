import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:learnity/api/user_apis.dart';
import 'package:learnity/models/user_info_model.dart';
import 'package:learnity/screen/adminPage/accountManager.dart';
import 'package:learnity/screen/adminPage/common/appbar.dart';
import 'package:learnity/screen/adminPage/common/sidebar.dart';
import 'package:learnity/screen/startPage/intro.dart';
import 'package:learnity/services/admin_service.dart';
import 'package:learnity/services/user_service.dart';

class Admindashboard extends StatefulWidget {
  const Admindashboard({super.key});

  @override
  State<Admindashboard> createState() => _AdmindashboardState();
}

class _AdmindashboardState extends State<Admindashboard> {
  bool _isLoading = true;

  // Data variables
  int _activeUsersCount = 0;
  int _activeGroupsCount = 0;
  int _monthlyVisits = 0;
  int _weeklyVisits = 0;
  int _todayVisits = 0;
  Map<String, int> _notifications = {};
  Map<String, double> _revenueData = {};

  String _visitFilter = 'Weekly';
  int _visitCount = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    AnalyticsService.logPageView('admin_dashboard');
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await Future.wait([
        AnalyticsService.getActiveUsersCount(),
        AnalyticsService.getActiveGroupsCount(),
        AnalyticsService.getMonthlyVisits(),
        AnalyticsService.getWeeklyVisits(),
        AnalyticsService.getTodayVisits(),
        AnalyticsService.getNewNotifications(),
        AnalyticsService.getRevenueData(),
      ]);

      setState(() {
        _activeUsersCount = results[0] as int;
        _activeGroupsCount = results[1] as int;
        _monthlyVisits = results[2] as int;
        _weeklyVisits = results[3] as int;
        _todayVisits = results[4] as int;
        _notifications = results[5] as Map<String, int>;
        _revenueData = results[6] as Map<String, double>;

        switch (_visitFilter) {
          case 'Weekly':
            _visitCount = _weeklyVisits;
            break;
          case 'Today':
            _visitCount = _todayVisits;
            break;
          default:
            _visitCount = _monthlyVisits;
        }

        _isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() {
        _isLoading = false;
      });
    }
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
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadDashboardData,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFF90EE90),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dashboard',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Tài khoản, Nhóm đang hoạt động',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Color(0xFFFFEB3B),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          '$_activeUsersCount',
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Người dùng đang hoạt động',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.black87,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    padding: EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Color(0xFF81D4FA),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          '$_activeGroupsCount',
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Nhóm đang hoạt động',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.black87,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),

                      // Số lượng truy cập section
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Số lượng truy cập',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: DropdownButton<String>(
                                    value: _visitFilter,
                                    icon: Icon(
                                      Icons.arrow_drop_down,
                                      color: Colors.black,
                                    ),
                                    underline: SizedBox(),
                                    items:
                                        <String>[
                                          'Monthly',
                                          'Weekly',
                                          'Today',
                                        ].map((String value) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(
                                              value,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.black,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                    onChanged: (String? newValue) {
                                      if (newValue != null) {
                                        setState(() {
                                          _visitFilter = newValue;

                                          // Update dữ liệu ngay
                                          switch (_visitFilter) {
                                            case 'Weekly':
                                              _visitCount = _weeklyVisits;
                                              break;
                                            case 'Today':
                                              _visitCount = _todayVisits;
                                              break;
                                            default:
                                              _visitCount = _monthlyVisits;
                                          }
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Text(
                              '$_visitCount',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              _visitFilter == 'Monthly'
                                  ? 'lượt truy cập tháng này'
                                  : _visitFilter == 'Weekly'
                                  ? 'lượt truy cập 7 ngày qua'
                                  : 'lượt truy cập hôm nay',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 16),
                          ],
                        ),
                      ),

                      SizedBox(height: 16),

                      // Thông báo section
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Thông báo',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildNotificationItem(
                                    Icons.group,
                                    '${_notifications['newGroups'] ?? 0} Nhóm mới',
                                  ),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: _buildNotificationItem(
                                    Icons.person_add,
                                    '${_notifications['newUsers'] ?? 0} Tài khoản mới',
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildNotificationItem(
                                    Icons.edit,
                                    '${_notifications['newPosts'] ?? 0} Bài viết mới',
                                  ),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: _buildNotificationItem(
                                    Icons.report,
                                    '${_notifications['newComplaints'] ?? 0} Khiếu nại mới',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 16),

                      // Báo cáo doanh thu section
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Báo cáo doanh thu',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Lọc: Monthly ▼',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Tháng này',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      Text(
                                        '\$${_revenueData['currentMonth']?.toStringAsFixed(0) ?? '0'}',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            _calculateGrowthRate(),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: _getGrowthColor(),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'So với tháng trước',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Tháng trước',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      Text(
                                        '\$${_revenueData['lastMonth']?.toStringAsFixed(0) ?? '0'}',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
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
    );
  }

  String _calculateGrowthRate() {
    final currentMonth = _revenueData['currentMonth'] ?? 0;
    final lastMonth = _revenueData['lastMonth'] ?? 0;

    if (lastMonth == 0) return '+0%';

    final growthRate = ((currentMonth - lastMonth) / lastMonth) * 100;
    return '${growthRate >= 0 ? '+' : ''}${growthRate.toStringAsFixed(1)}%';
  }

  Color _getGrowthColor() {
    final currentMonth = _revenueData['currentMonth'] ?? 0;
    final lastMonth = _revenueData['lastMonth'] ?? 0;

    if (currentMonth >= lastMonth) {
      return Colors.green;
    } else {
      return Colors.red;
    }
  }

  Widget _buildNotificationItem(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.black54),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(title),
      onTap: onTap,
    );
  }
}
