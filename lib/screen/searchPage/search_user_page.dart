import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:learnity/theme/theme.dart';
import '../../models/user_info_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../chatPage/chat_page.dart';
import '../userpage/their_profile_page.dart';

class SearchUserPage extends StatefulWidget {
  const SearchUserPage({super.key});

  @override
  State<SearchUserPage> createState() => _SearchUserPageState();
}

class _SearchUserPageState extends State<SearchUserPage> {
  List<UserInfoModel> displayedUsers = [];
  List<bool> isFollowingList = [];
  bool isLoading = false;
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    fetchUsers();
    // isFollowingList logic remains the same after fetch
  }

  void _filterUsers(String query) {
    final filtered = displayedUsers.where((user) {
      if (user.uid == currentUserId) return false; // Bỏ qua chính mình
      final name = (user.username ?? '').toLowerCase();
      final nick = (user.displayName ?? '').toLowerCase();
      return name.contains(query.toLowerCase()) || nick.contains(query.toLowerCase());
    }).toList();

    setState(() {
      displayedUsers = filtered;
      isFollowingList = List.generate(filtered.length, (index) => false);
    });
  }


  Future<void> fetchUsers() async {
    setState(() => isLoading = true);
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final snapshot = await _firestore.collection('users').get();
    final users = snapshot.docs
        .map((doc) {
      final data = doc.data();
      return UserInfoModel.fromMap(data, doc.id);
    })
        .where((user) => user.uid != currentUserId) // Lọc bỏ user hiện tại
        .toList();

    setState(() {
      isLoading = false;
      displayedUsers = users;
      isFollowingList = List.generate(users.length, (index) => false);
    });
  }
  Future<void> _handleFollow(UserInfoModel user) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final userId = user.uid;

    if (uid != null && userId != null) {
      final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
      final currentUserRef = FirebaseFirestore.instance.collection('users').doc(uid);

      final isNowFollowing = !(user.followers?.contains(uid) ?? false);

      await userRef.update({
        'followers': isNowFollowing
            ? FieldValue.arrayUnion([uid])
            : FieldValue.arrayRemove([uid]),
      });

      await currentUserRef.update({
        'following': isNowFollowing
            ? FieldValue.arrayUnion([userId])
            : FieldValue.arrayRemove([userId]),
      });

      setState(() {
        user.followers ??= []; // đảm bảo không null
        if (isNowFollowing) {
          user.followers!.add(uid);
        } else {
          user.followers!.remove(uid);
        }
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Center(child: Image.asset('assets/learnity.png', height: 110)),
                  Positioned(
                    right: 5,
                    child: IconButton(
                      icon: Icon(Icons.chat_bubble_outline, size: 30),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context)=>ChatPage()));
                      },
                    ),
                  ),
                ],
              ),
              const Text("Tìm kiếm", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              TextField(
                onChanged: _filterUsers,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Tìm kiếm',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator()) // Loading
                    : displayedUsers.isEmpty
                    ? const Center(child: Text('Trống', style: TextStyle(fontSize: 18)))
                    : ListView.builder(
                  itemCount: displayedUsers.length,
                  itemBuilder: (context, index) {
                    final user = displayedUsers[index];
                    final currentUser = FirebaseAuth.instance.currentUser;
                    final isFollowing = user.followers?.contains(currentUser?.uid) ?? false;
                    return InkWell(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => TheirProfilePage(user: user)),
                        );

                        if (result == true) {
                          setState(() {
                            // Gọi lại logic load user hoặc cập nhật trạng thái theo dõi
                            fetchUsers(); // hoặc logic cập nhật tương ứng
                          });
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.black12,
                              backgroundImage: (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                                  ? NetworkImage(user.avatarUrl!)
                                  : null,
                              child: (user.avatarUrl == null || user.avatarUrl!.isEmpty)
                                  ? const Icon(Icons.person)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.displayName ?? 'No name',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                  ),
                                  Text(
                                    user.username ?? '',
                                    style: const TextStyle(color: Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 130,
                              child: ElevatedButton(
                                onPressed: () => _handleFollow(user),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: (user.followers?.contains(FirebaseAuth.instance.currentUser?.uid) ?? false)
                                      ? Colors.grey.shade300
                                      : Colors.black,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                  minimumSize: const Size(0, 36),
                                ),
                                child: Text(
                                  (user.followers?.contains(FirebaseAuth.instance.currentUser?.uid) ?? false)
                                      ? "Đang theo dõi"
                                      : "Theo dõi",
                                  style: TextStyle(
                                    color: (user.followers?.contains(FirebaseAuth.instance.currentUser?.uid) ?? false)
                                        ? Colors.black
                                        : Colors.white,
                                    fontSize: 16,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                          ],
                        ),
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
