import 'package:flutter/material.dart';
import 'package:learnity/theme/theme.dart';
import '../../models/user_model.dart';
import 'user_card.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  late List<UserModel> _users;

  @override
  void initState() {
    super.initState();
    _users = [
      UserModel(
        uid: '1',
        username: 'Vũ Phương',
        fullname: 'Vũ Nguyễn Phương',
        avt: 'https://i.ytimg.com/vi/sbBrkzy_PEU/maxresdefault.jpg',
      ),
      UserModel(
        uid: '2',
        username: 'Tồn',
        fullname: 'Hồng Tồn',
        avt: 'https://tse3.mm.bing.net/th?id=OIP.7h1SGD_vtdqiBLLVKU3F_AHaEJ&pid=Api&P=0&h=180',
      ),
      UserModel(
        uid: '3',
        username: 'Minh',
        fullname: 'Hồng Minh',
        avt: 'https://tse2.mm.bing.net/th?id=OIP.6OKzXzBLKUKlVLIcPq5P0QHaEK&pid=Api&P=0&h=180',
      ),
      UserModel(
        uid: '4',
        username: 'Phúc',
        fullname: 'Phúc Lê',
        avt: 'https://i.pinimg.com/736x/5c/66/c8/5c66c8ad39e0a87038853683d4f38248.jpg',
      ),
      UserModel(
        uid: '5',
        username: 'Vũ',
        fullname: 'Trọng Vũ',
        avt: 'https://i.ytimg.com/vi/H2BjXc1yU7U/maxresdefault.jpg',
      ),
      UserModel(
        uid: '1',
        username: 'Vũ Phương',
        fullname: 'Vũ Nguyễn Phương',
        avt: 'https://i.ytimg.com/vi/sbBrkzy_PEU/maxresdefault.jpg',
      ),
      UserModel(
        uid: '2',
        username: 'Tồn',
        fullname: 'Hồng Tồn',
        avt: 'https://tse3.mm.bing.net/th?id=OIP.7h1SGD_vtdqiBLLVKU3F_AHaEJ&pid=Api&P=0&h=180',
      ),
      UserModel(
        uid: '3',
        username: 'Minh',
        fullname: 'Hồng Minh',
        avt: 'https://tse2.mm.bing.net/th?id=OIP.6OKzXzBLKUKlVLIcPq5P0QHaEK&pid=Api&P=0&h=180',
      ),
      UserModel(
        uid: '4',
        username: 'Phúc',
        fullname: 'Phúc Lê',
        avt: 'https://i.pinimg.com/736x/5c/66/c8/5c66c8ad39e0a87038853683d4f38248.jpg',
      ),
      UserModel(
        uid: '5',
        username: 'Vũ',
        fullname: 'Trọng Vũ',
        avt: 'https://i.ytimg.com/vi/H2BjXc1yU7U/maxresdefault.jpg',
      ),
      UserModel(
        uid: '1',
        username: 'Vũ Phương',
        fullname: 'Vũ Nguyễn Phương',
        avt: 'https://i.ytimg.com/vi/sbBrkzy_PEU/maxresdefault.jpg',
      ),
      UserModel(
        uid: '2',
        username: 'Tồn',
        fullname: 'Hồng Tồn',
        avt: 'https://tse3.mm.bing.net/th?id=OIP.7h1SGD_vtdqiBLLVKU3F_AHaEJ&pid=Api&P=0&h=180',
      ),
      UserModel(
        uid: '3',
        username: 'Minh',
        fullname: 'Hồng Minh',
        avt: 'https://tse2.mm.bing.net/th?id=OIP.6OKzXzBLKUKlVLIcPq5P0QHaEK&pid=Api&P=0&h=180',
      ),
      UserModel(
        uid: '4',
        username: 'Phúc',
        fullname: 'Phúc Lê',
        avt: 'https://i.pinimg.com/736x/5c/66/c8/5c66c8ad39e0a87038853683d4f38248.jpg',
      ),
      UserModel(
        uid: '5',
        username: 'Vũ',
        fullname: 'Trọng Vũ',
        avt: 'https://i.ytimg.com/vi/H2BjXc1yU7U/maxresdefault.jpg',
      ),
    ];
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        automaticallyImplyLeading: false,
        elevation: 0,
        centerTitle: true,
        title: Image.asset('assets/learnity.png', height: 70),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {},
              child: Image.asset('assets/chat.png', width: 28, height: 28),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              'Tìm kiếm',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color:AppColors.black,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white.withOpacity(0.6),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (query) {
              },
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _users.length,
              separatorBuilder: (_, __) => const Divider(color: AppColors.black),
              itemBuilder: (context, index) {
                final user = _users[index];
                return UserCard(
                  user: user,
                  onToggleFollow: () {
                    setState(() => user.isFollowing = !user.isFollowing);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
