import 'package:flutter/material.dart';
import 'package:learnity/theme/theme.dart';
import '../../models/user_info_model.dart';

class SearchUserPage extends StatefulWidget {
  const SearchUserPage({super.key});

  @override
  State<SearchUserPage> createState() => _SearchUserPageState();
}

class _SearchUserPageState extends State<SearchUserPage> {
  final List<UserInfoModel> allUsers = [
    UserInfoModel(
      displayName: 'pink_everlasting',
      username: 'Nguyễn Hồng Tôn',
      avatarPath: 'assets/avatar.png',
    ),
    UserInfoModel(
      displayName: 'blue_sky',
      username: 'Vũ Nguyễn Phương',
      avatarPath: null,
    ),
    UserInfoModel(
      displayName: 'green_leaf',
      username: 'Bùi Trọng Vũ',
      avatarPath: null,
    ),
    UserInfoModel(
      displayName: 'sunshine',
      username: 'Lê Nguyễn Minh Phúc',
      avatarPath: null,
    ),
  ];

  List<UserInfoModel> displayedUsers = [];
  List<bool> isFollowingList = [];

  @override
  void initState() {
    super.initState();
    displayedUsers = List.from(allUsers);
    isFollowingList = List.generate(displayedUsers.length, (index) => false);
  }

  void _filterUsers(String query) {
    final filtered =
        allUsers.where((user) {
          final name = (user.username ?? '').toLowerCase();
          final nick = (user.displayName ?? '').toLowerCase();
          return name.contains(query.toLowerCase()) ||
              nick.contains(query.toLowerCase());
        }).toList();

    setState(() {
      displayedUsers = filtered;
      isFollowingList = List.generate(filtered.length, (index) => false);
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
                  Center(
                    child: Image.asset('assets/learnity.png', height: 110),
                  ),
                  Positioned(
                    right: 5,
                    child: Icon(Icons.chat_bubble_outline, size: 30),
                  ),
                ],
              ),
              const Text(
                "Tìm kiếm",
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
              ),
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
                child:
                    displayedUsers.isEmpty
                        ? const Center(
                          child: Text('Trống', style: TextStyle(fontSize: 18)),
                        )
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
                                    backgroundImage:
                                        user.avatarPath != null
                                            ? AssetImage(user.avatarPath!)
                                            : null,
                                    child:
                                        user.avatarPath == null
                                            ? const Icon(Icons.person)
                                            : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user.displayName ?? '',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                        Text(
                                          user.username ?? '',
                                          style: const TextStyle(
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    width: 130,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          isFollowingList[index] =
                                              !isFollowingList[index];
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            isFollowing
                                                ? Colors.grey.shade300
                                                : Colors.black,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 6,
                                        ),
                                        minimumSize: const Size(0, 36),
                                      ),
                                      child: Text(
                                        isFollowing
                                            ? "Đang theo dõi"
                                            : "Theo dõi",
                                        style: TextStyle(
                                          color:
                                              isFollowing
                                                  ? Colors.black
                                                  : Colors.white,
                                          fontSize: 16,
                                        ),
                                        overflow:
                                            TextOverflow
                                                .ellipsis, // nếu chữ quá dài thì ...
                                      ),
                                    ),
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
