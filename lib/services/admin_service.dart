import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Lấy số lượng người dùng hoạt động
  static Future<int> getActiveUsersCount() async {
    try {
      final usersSnapshot =
          await _firestore
              .collection('users')
              .where('is_online', isEqualTo: true)
              .get();
      return usersSnapshot.docs.length;
    } catch (e) {
      print('Error getting active users count: $e');
      return 0;
    }
  }

  // Lấy số lượng nhóm hoạt động
  static Future<int> getActiveGroupsCount() async {
    try {
      final groupsSnapshot =
          await _firestore
              .collection('communityGroups')
              .where('status', isEqualTo: 'active')
              .get();
      return groupsSnapshot.docs.length;
    } catch (e) {
      print('Error getting active groups count: $e');
      return 0;
    }
  }

  /// Gọi mỗi khi mở app hoặc vào trang chính
  static Future<void> logVisitAndSave() async {
    final today = DateTime.now();
    final todayStr =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    final ref = _firestore
        .collection('analytics')
        .doc('visits')
        .collection('daily')
        .doc(todayStr);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (snapshot.exists) {
        final currentCount = snapshot.data()?['count'] ?? 0;
        transaction.update(ref, {'count': currentCount + 1});
      } else {
        transaction.set(ref, {'count': 1, 'date': today});
      }
    });

    // Gửi log lên Firebase Analytics để theo dõi dashboard
    await _analytics.logEvent(
      name: 'visit',
      parameters: {
        'date': todayStr,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  /// Lấy tổng số lượt truy cập trong tháng
  static Future<int> getMonthlyVisits() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    final visitsSnapshot =
        await _firestore
            .collection('analytics')
            .doc('visits')
            .collection('daily')
            .where('date', isGreaterThanOrEqualTo: startOfMonth)
            .get();

    int totalVisits = 0;
    for (var doc in visitsSnapshot.docs) {
      totalVisits += (doc.data()['count'] as int? ?? 0);
    }

    return totalVisits;
  }

  // lấy tổng số lượt truy cập trong tuần
  static Future<int> getWeeklyVisits() async {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(Duration(days: 7));

    final visitsSnapshot =
        await _firestore
            .collection('analytics')
            .doc('visits')
            .collection('daily')
            .where('date', isGreaterThanOrEqualTo: sevenDaysAgo)
            .get();

    int totalVisits = 0;
    for (var doc in visitsSnapshot.docs) {
      totalVisits += (doc.data()['count'] as int? ?? 0);
    }

    return totalVisits;
  }

  static Future<int> getTodayVisits() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    final todayStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final docSnapshot =
        await _firestore
            .collection('analytics')
            .doc('visits')
            .collection('daily')
            .doc(todayStr)
            .get();

    if (docSnapshot.exists) {
      return docSnapshot.data()?['count'] ?? 0;
    } else {
      return 0;
    }
  }

  // Lấy thông báo mới
  static Future<Map<String, int>> getNewNotifications() async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      // Nhóm mới
      final newGroupsSnapshot =
          await _firestore
              .collection('communityGroups')
              .where('createdAt', isGreaterThanOrEqualTo: startOfMonth)
              .get();

      // Tài khoản mới
      final newUsersSnapshot =
          await _firestore
              .collection('users')
              .where('createdAt', isGreaterThanOrEqualTo: startOfMonth)
              .get();

      // Bài viết mới
      final newPostsSnapshot =
          await _firestore
              .collection('posts')
              .where('createdAt', isGreaterThanOrEqualTo: startOfMonth)
              .get();

      // Báo cáo bài viết
      final newPostReportsSnapshot =
          await _firestore
              .collection('post_reports')
              .where('reportedAt', isGreaterThanOrEqualTo: startOfMonth)
              .get();

      // Báo cáo nhóm
      final newGroupReportsSnapshot =
          await _firestore
              .collection('groupReports')
              .where('createdAt', isGreaterThanOrEqualTo: startOfMonth)
              .get();

      return {
        'newGroups': newGroupsSnapshot.docs.length,
        'newUsers': newUsersSnapshot.docs.length,
        'newPosts': newPostsSnapshot.docs.length,
        'newPostReports': newPostReportsSnapshot.docs.length,
        'newGroupReports': newGroupReportsSnapshot.docs.length,
        'newComplaints':
            newPostReportsSnapshot.docs.length +
            newGroupReportsSnapshot.docs.length,
      };
    } catch (e) {
      print('Error getting notifications: $e');
      return {
        'newGroups': 0,
        'newUsers': 0,
        'newPosts': 0,
        'newPostReports': 0,
        'newGroupReports': 0,
        'newComplaints': 0,
      };
    }
  }

  // Lấy thống kê báo cáo
  static Future<Map<String, dynamic>> getReportsAnalytics() async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      // Báo cáo bài viết theo trạng thái
      final postReportsSnapshot =
          await _firestore
              .collection('post_reports')
              .where('reportedAt', isGreaterThanOrEqualTo: startOfMonth)
              .get();

      Map<String, int> postReportsByReason = {};
      for (var doc in postReportsSnapshot.docs) {
        String reason = doc.data()['reason'] ?? 'Unknown';
        postReportsByReason[reason] = (postReportsByReason[reason] ?? 0) + 1;
      }

      // Báo cáo nhóm theo trạng thái
      final groupReportsSnapshot =
          await _firestore
              .collection('groupReports')
              .where('createdAt', isGreaterThanOrEqualTo: startOfMonth)
              .get();

      Map<String, int> groupReportsByStatus = {};
      Map<String, int> groupReportsByReason = {};

      for (var doc in groupReportsSnapshot.docs) {
        String status = doc.data()['status'] ?? 'Unknown';
        String reason = doc.data()['reason'] ?? 'Unknown';

        groupReportsByStatus[status] = (groupReportsByStatus[status] ?? 0) + 1;
        groupReportsByReason[reason] = (groupReportsByReason[reason] ?? 0) + 1;
      }

      return {
        'postReports': {
          'total': postReportsSnapshot.docs.length,
          'byReason': postReportsByReason,
        },
        'groupReports': {
          'total': groupReportsSnapshot.docs.length,
          'byStatus': groupReportsByStatus,
          'byReason': groupReportsByReason,
        },
      };
    } catch (e) {
      print('Error getting reports analytics: $e');
      return {
        'postReports': {'total': 0, 'byReason': {}},
        'groupReports': {'total': 0, 'byStatus': {}, 'byReason': {}},
      };
    }
  }

  // Lấy thống kê người dùng
  static Future<Map<String, dynamic>> getUsersAnalytics() async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      // Tổng số người dùng
      final totalUsersSnapshot = await _firestore.collection('users').get();

      // Người dùng theo role
      Map<String, int> usersByRole = {};
      Map<String, int> usersByStatus = {};

      for (var doc in totalUsersSnapshot.docs) {
        String role = doc.data()['role'] ?? 'user';
        String status = doc.data()['status'] ?? 'Offline';

        usersByRole[role] = (usersByRole[role] ?? 0) + 1;
        usersByStatus[status] = (usersByStatus[status] ?? 0) + 1;
      }

      // Người dùng mới trong tháng
      final newUsersSnapshot =
          await _firestore
              .collection('users')
              .where('createdAt', isGreaterThanOrEqualTo: startOfMonth)
              .get();

      return {
        'total': totalUsersSnapshot.docs.length,
        'newThisMonth': newUsersSnapshot.docs.length,
        'byRole': usersByRole,
        'byStatus': usersByStatus,
      };
    } catch (e) {
      print('Error getting users analytics: $e');
      return {'total': 0, 'newThisMonth': 0, 'byRole': {}, 'byStatus': {}};
    }
  }

  // Lấy thống kê nhóm
  static Future<Map<String, dynamic>> getGroupsAnalytics() async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      // Tổng số nhóm
      final totalGroupsSnapshot =
          await _firestore.collection('communityGroups').get();

      // Nhóm theo trạng thái và quyền riêng tư
      Map<String, int> groupsByStatus = {};
      Map<String, int> groupsByPrivacy = {};

      for (var doc in totalGroupsSnapshot.docs) {
        String status = doc.data()['status'] ?? 'active';
        String privacy = doc.data()['privacy'] ?? 'public';

        groupsByStatus[status] = (groupsByStatus[status] ?? 0) + 1;
        groupsByPrivacy[privacy] = (groupsByPrivacy[privacy] ?? 0) + 1;
      }

      // Nhóm mới trong tháng
      final newGroupsSnapshot =
          await _firestore
              .collection('communityGroups')
              .where('createdAt', isGreaterThanOrEqualTo: startOfMonth)
              .get();

      return {
        'total': totalGroupsSnapshot.docs.length,
        'newThisMonth': newGroupsSnapshot.docs.length,
        'byStatus': groupsByStatus,
        'byPrivacy': groupsByPrivacy,
      };
    } catch (e) {
      print('Error getting groups analytics: $e');
      return {'total': 0, 'newThisMonth': 0, 'byStatus': {}, 'byPrivacy': {}};
    }
  }

  // Lấy thống kê bài viết
  static Future<Map<String, dynamic>> getPostsAnalytics() async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      // Tổng số bài viết
      final totalPostsSnapshot = await _firestore.collection('posts').get();

      // Bài viết mới trong tháng
      final newPostsSnapshot =
          await _firestore
              .collection('posts')
              .where('createdAt', isGreaterThanOrEqualTo: startOfMonth)
              .get();

      // Tổng số lượt like
      final totalLikesSnapshot =
          await _firestore.collection('post_likes').get();

      // Tổng số bình luận
      final totalCommentsSnapshot =
          await _firestore.collection('comments').get();

      return {
        'totalPosts': totalPostsSnapshot.docs.length,
        'newPostsThisMonth': newPostsSnapshot.docs.length,
        'totalLikes': totalLikesSnapshot.docs.length,
        'totalComments': totalCommentsSnapshot.docs.length,
      };
    } catch (e) {
      print('Error getting posts analytics: $e');
      return {
        'totalPosts': 0,
        'newPostsThisMonth': 0,
        'totalLikes': 0,
        'totalComments': 0,
      };
    }
  }

  // Lấy doanh thu
  static Future<Map<String, double>> getRevenueData() async {
    try {
      final now = DateTime.now();
      final currentMonth = DateTime(now.year, now.month, 1);
      final lastMonth = DateTime(now.year, now.month - 1, 1);

      // Doanh thu tháng hiện tại
      final currentMonthSnapshot =
          await _firestore
              .collection('payments')
              .where('createdAt', isGreaterThanOrEqualTo: currentMonth)
              .where('status', isEqualTo: 'completed')
              .get();

      double currentMonthRevenue = 0;
      for (var doc in currentMonthSnapshot.docs) {
        currentMonthRevenue += (doc.data()['amount'] as double? ?? 0);
      }

      // Doanh thu tháng trước
      final lastMonthSnapshot =
          await _firestore
              .collection('payments')
              .where('createdAt', isGreaterThanOrEqualTo: lastMonth)
              .where('createdAt', isLessThan: currentMonth)
              .where('status', isEqualTo: 'completed')
              .get();

      double lastMonthRevenue = 0;
      for (var doc in lastMonthSnapshot.docs) {
        lastMonthRevenue += (doc.data()['amount'] as double? ?? 0);
      }

      return {
        'currentMonth': currentMonthRevenue,
        'lastMonth': lastMonthRevenue,
      };
    } catch (e) {
      print('Error getting revenue data: $e');
      return {'currentMonth': 0, 'lastMonth': 0};
    }
  }

  // Lấy thống kê tổng quan
  static Future<Map<String, dynamic>> getDashboardAnalytics() async {
    try {
      final results = await Future.wait([
        getActiveUsersCount(),
        getActiveGroupsCount(),
        getMonthlyVisits(),
        getNewNotifications(),
        getUsersAnalytics(),
        getGroupsAnalytics(),
        getPostsAnalytics(),
        getReportsAnalytics(),
        getRevenueData(),
      ]);

      return {
        'activeUsers': results[0],
        'activeGroups': results[1],
        'monthlyVisits': results[2],
        'notifications': results[3],
        'users': results[4],
        'groups': results[5],
        'posts': results[6],
        'reports': results[7],
        'revenue': results[8],
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('Error getting dashboard analytics: $e');
      return {};
    }
  }

  // Log custom event
  static Future<void> logEvent(
    String eventName,
    Map<String, dynamic> parameters,
  ) async {
    try {
      await _analytics.logEvent(
        name: eventName,
        parameters: parameters.cast<String, Object>(),
      );
    } catch (e) {
      print('Error logging event: $e');
    }
  }

  // Log page view
  static Future<void> logPageView(String pageName) async {
    try {
      await _analytics.logEvent(
        name: 'page_view',
        parameters: {
          'page_name': pageName,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      print('Error logging page view: $e');
    }
  }

  // Log user action
  static Future<void> logUserAction(
    String action,
    String userId, {
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'user_action',
        parameters: {
          'action': action,
          'user_id': userId,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          ...?additionalData,
        },
      );
    } catch (e) {
      print('Error logging user action: $e');
    }
  }

  // Log group activity
  static Future<void> logGroupActivity(
    String activity,
    String groupId,
    String userId,
  ) async {
    try {
      await _analytics.logEvent(
        name: 'group_activity',
        parameters: {
          'activity': activity,
          'group_id': groupId,
          'user_id': userId,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      print('Error logging group activity: $e');
    }
  }

  // Log report submission
  static Future<void> logReportSubmission(
    String reportType,
    String reportId,
    String reporterId,
  ) async {
    try {
      await _analytics.logEvent(
        name: 'report_submitted',
        parameters: {
          'report_type': reportType,
          'report_id': reportId,
          'reporter_id': reporterId,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      print('Error logging report submission: $e');
    }
  }
}
