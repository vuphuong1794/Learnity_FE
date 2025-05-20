import 'package:flutter/material.dart';
import 'package:learnity/theme/theme.dart';
import '../../models/user_info_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SearchUserPage extends StatefulWidget {
  const SearchUserPage({super.key});

  @override
  State<SearchUserPage> createState() => _SearchUserPageState();
}

class _SearchUserPageState extends State<SearchUserPage> {
  List<UserInfoModel> allUsers = [];
  List<UserInfoModel> displayedUsers = [];
  List<bool> isFollowingList = [];

  @override
  void initState() {
    super.initState();
    fetchUsers();
    // isFollowingList logic remains the same after fetch
  }

  void _filterUsers(String query) {
    final filtered = allUsers.where((user) {
      final name = (user.fullName ?? '').toLowerCase();
      final nick = (user.nickname ?? '').toLowerCase();
      return name.contains(query.toLowerCase()) || nick.contains(query.toLowerCase());
    }).toList();

    setState(() {
      displayedUsers = filtered;
      isFollowingList = List.generate(filtered.length, (index) => false);
    });
  }


  Future<void> fetchUsers() async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final snapshot = await _firestore.collection('users').get();
    final users = snapshot.docs.map((doc) {
      final data = doc.data();
      return UserInfoModel(
        nickname: data['nickname'],
        fullName: data['username'],
        avatarUrl: data['avatarUrl'],
      );
    }).toList();

    setState(() {
      allUsers = users;
      displayedUsers = users;
      isFollowingList = List.generate(users.length, (index) => false);
    });
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
                    child: Icon(Icons.chat_bubble_outline, size: 30),
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
                child: displayedUsers.isEmpty
                    ? const Center(child: Text('Trống', style: TextStyle(fontSize: 18)))
                    : ListView.builder(
                  itemCount: displayedUsers.length,
                  itemBuilder: (context, index) {
                    final user = displayedUsers[index];
                    final isFollowing = isFollowingList[index];
                    return Padding(
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
                                    user.nickname ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    )
                                ),
                                Text(
                                    user.fullName ?? '',
                                    style: const TextStyle(
                                        color: Colors.black54
                                    )
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 130,
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  isFollowingList[index] = !isFollowingList[index];
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isFollowing ? Colors.grey.shade300 : Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                minimumSize: const Size(0, 36),
                              ),
                              child: Text(
                                isFollowing ? "Đang theo dõi" : "Theo dõi",
                                style: TextStyle(
                                    color: isFollowing ? Colors.black : Colors.white,
                                    fontSize: 16
                                ),
                                overflow: TextOverflow.ellipsis, // nếu chữ quá dài thì ...
                              ),
                            ),
                          )
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
