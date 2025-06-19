import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:learnity/screen/admin/common/appbar.dart';
import 'package:learnity/screen/admin/common/sidebar.dart';

class Complaint {
  final int id;
  final String user;
  final String content;
  final String postType;
  final String status;
  final DateTime createdAt;

  Complaint(
    this.id,
    this.user,
    this.content,
    this.postType,
    this.status,
    this.createdAt,
  );
}

class Reportmanager extends StatefulWidget {
  const Reportmanager({super.key});

  @override
  State<Reportmanager> createState() => _ReportmanagerState();
}

class _ReportmanagerState extends State<Reportmanager> {
  final ScrollController _scrollController = ScrollController();
  final List<Complaint> _complaints = [];
  bool _isLoading = false;
  int _currentPage = 1;
  final int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _loadMore();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading) {
        _loadMore();
      }
    });
  }

  Future<void> _loadMore() async {
    setState(() => _isLoading = true);
    await Future.delayed(Duration(seconds: 1));
    final newComplaints = List.generate(_pageSize, (i) {
      final id = (_currentPage - 1) * _pageSize + i + 1;
      return Complaint(
        id,
        'Phuong',
        i % 2 == 0 ? 'Support for theme' : 'fake doctor',
        i % 2 == 0 ? 'bài viết' : 'người dùng',
        i % 3 == 0 ? 'Closed' : 'Open',
        DateTime.now().subtract(Duration(days: i)),
      );
    });

    setState(() {
      _complaints.addAll(newComplaints);
      _isLoading = false;
      _currentPage++;
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Open':
        return Colors.green;
      case 'Closed':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  Widget _buildComplaintTile(Complaint c) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              c.id.toString(),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(c.user, overflow: TextOverflow.ellipsis, maxLines: 1),
          ),
          Expanded(
            flex: 3,
            child: Text(
              c.content,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              c.postType,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor(c.status).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                c.status,
                style: TextStyle(color: _statusColor(c.status)),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              DateFormat('yyyy-MM-dd').format(c.createdAt),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          Expanded(
            flex: 1,
            child: PopupMenuButton<String>(
              onSelected: (value) {
                // Xử lý action
              },
              itemBuilder:
                  (context) => [
                    PopupMenuItem(value: 'response', child: Text('Response')),
                    PopupMenuItem(value: 'close', child: Text('Close')),
                  ],
              child: Icon(Icons.more_vert),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String title, int number, Color color) {
    return Card(
      elevation: 2,
      child: Container(
        width: 120,
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Icon(icon, color: color),
            SizedBox(height: 8),
            Text(
              number.toString(),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(title, style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
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
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildInfoCard(
                    Icons.local_offer,
                    "Total Tickets",
                    3847,
                    Colors.purple,
                  ),
                  _buildInfoCard(
                    Icons.pending,
                    "Pending Tickets",
                    624,
                    Colors.orange,
                  ),
                  _buildInfoCard(
                    Icons.check_circle,
                    "Closed Tickets",
                    3195,
                    Colors.green,
                  ),
                ],
              ),
            ),
            // Bảng & Danh sách
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: 1000,
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        color: Colors.teal.shade800,
                        child: Row(
                          children: const [
                            Expanded(
                              flex: 1,
                              child: Text(
                                "ID",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                "Người dùng",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                "Nội dung",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                "Báo cáo về",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                "Trạng thái",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                "Ngày tạo",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                "Chức năng",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ListView phải có chiều cao cố định hoặc Expanded
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: _complaints.length + (_isLoading ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index < _complaints.length) {
                              return _buildComplaintTile(_complaints[index]);
                            } else {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
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
