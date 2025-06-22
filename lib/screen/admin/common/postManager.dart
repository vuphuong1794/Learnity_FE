
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:learnity/screen/admin/common/sidebar.dart';

import '../../../models/post_model.dart';
import '../../../widgets/full_screen_image_page.dart';
import 'appbar.dart';

class PostManagerScreen extends StatefulWidget {
  const PostManagerScreen({Key? key}) : super(key: key);

  @override
  State<PostManagerScreen> createState() => _PostManagerScreenState();
}

class _PostManagerScreenState extends State<PostManagerScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<PostModel> _allPosts = [];
  List<PostModel> _filteredPosts = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterPosts);
  }

  void _filterPosts() {
    final keyword = _searchController.text.toLowerCase();
    setState(() {
      _filteredPosts = _allPosts.where((post) {
        return (post.username?.toLowerCase().contains(keyword) ?? false) ||
            (post.content?.toLowerCase().contains(keyword) ?? false) ||
            (post.postDescription?.toLowerCase().contains(keyword) ?? false);
      }).toList();
    });
  }


  Stream<List<PostModel>> fetchPosts() {
    return FirebaseFirestore.instance
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => PostModel.fromDocument(doc)).toList());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F6F6),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: CustomAppBar(),
        ),
        drawer: Sidebar(),
        body: Column(
          children: [
            // Custom AppBar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(color: Color(0xFF90C695)),
              child: const Text(
                'Quản lý bài viết ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            Container(
              margin: const EdgeInsets.all(16), // padding ngoài container
              padding: const EdgeInsets.symmetric(horizontal: 16), // padding trong cho nội dung
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => _filterPosts(), // gợi ý gọi filter
                decoration: const InputDecoration(
                  hintText: 'Tìm kiếm bài viết...',
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                ),
              ),
            ),

            // Danh sách bài đăng
            Expanded(
              child: StreamBuilder<List<PostModel>>(
                stream: fetchPosts(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("Không có bài viết nào"));
                  }

                  _allPosts = snapshot.data!;
                  _filteredPosts = _searchController.text.isEmpty ? _allPosts : _filteredPosts;

                  return ListView.builder(
                    itemCount: _filteredPosts.length,
                    itemBuilder: (context, index) {
                      return _buildPostCard(_filteredPosts[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(PostModel post) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Avatar + tên + thời gian
            Row(
              children: [
                CircleAvatar(
                  backgroundImage:
                  post.avatarUrl != null ? NetworkImage(post.avatarUrl!) : null,
                  child: post.avatarUrl == null ? const Icon(Icons.person) : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    post.username ?? "Ẩn danh",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  post.createdAt != null
                      ? "${post.createdAt!.day}/${post.createdAt!.month}/${post.createdAt!.year}"
                      : "Không rõ ngày",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (post.content != null)
              Text(post.content!, style: const TextStyle(fontSize: 16)),

            if (post.postDescription != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(post.postDescription!,
                    style: const TextStyle(color: Colors.grey)),
              ),

            if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FullScreenImagePage(imageUrl: post.imageUrl!),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        post.imageUrl!,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                        const Text("Lỗi tải ảnh"),
                      ),
                    ),
                  ),

                ),
              ),

            const SizedBox(height: 8),
            Text("Mã bài viết: ${post.postId ?? 'Không xác định'}",
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}