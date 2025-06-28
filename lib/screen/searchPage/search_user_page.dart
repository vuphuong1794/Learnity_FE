import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:learnity/viewmodels/search_user_viewmodel.dart';
import '../../models/user_info_model.dart';
import '../userPage/their_profile_page.dart';
import '../../theme/theme_provider.dart';
import '../../theme/theme.dart';

class SearchUserPage extends StatefulWidget {
  const SearchUserPage({super.key});

  @override
  State<SearchUserPage> createState() => _SearchUserPageState();
}

class _SearchUserPageState extends State<SearchUserPage> {
  late SearchUserViewModel _viewModel;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = SearchUserViewModel();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _viewModel.filterUsers(query);
  }

  Future<void> _handleFollow(UserInfoModel user) async {
    await _viewModel.handleFollow(user);
  }

  Future<void> _refreshUsers() async {
    await _viewModel.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: AppBackgroundStyles.mainBackground(isDarkMode),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header với logo và nút chat (đã comment)
              // _buildHeader(isDarkMode),

              // Tiêu đề
              Text(
                "Tìm kiếm",
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: AppTextStyles.normalTextColor(isDarkMode),
                ),
              ),
              const SizedBox(height: 5),

              // Thanh tìm kiếm
              _buildSearchBar(isDarkMode),
              const SizedBox(height: 20),

              // Danh sách người dùng
              Expanded(
                child: ChangeNotifierProvider.value(
                  value: _viewModel,
                  child: Consumer<SearchUserViewModel>(
                    builder: (context, viewModel, child) {
                      if (viewModel.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (viewModel.displayedUsers.isEmpty) {
                        return Center(
                          child: Text(
                            'Không tìm thấy người dùng nào',
                            style: TextStyle(
                              fontSize: 18,
                              color: AppTextStyles.normalTextColor(isDarkMode),
                            ),
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: _refreshUsers,
                        child: ListView.builder(
                          itemCount: viewModel.displayedUsers.length,
                          itemBuilder: (context, index) {
                            final user = viewModel.displayedUsers[index];
                            return _buildUserListItem(
                              user,
                              isDarkMode,
                              viewModel,
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDarkMode) {
    return TextField(
      controller: _searchController,
      style: TextStyle(color: AppTextStyles.normalTextColor(isDarkMode)),
      onChanged: _onSearchChanged,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        prefixIconColor: AppIconStyles.iconPrimary(isDarkMode),
        hintText: 'Tìm kiếm theo tên hoặc username',
        hintStyle: TextStyle(
          color: AppTextStyles.normalTextColor(isDarkMode).withOpacity(0.5),
        ),
        filled: true,
        fillColor: AppBackgroundStyles.buttonBackgroundSecondary(isDarkMode),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildUserListItem(
    UserInfoModel user,
    bool isDarkMode,
    SearchUserViewModel viewModel,
  ) {
    final isFollowing = viewModel.isFollowing(user);

    return InkWell(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TheirProfilePage(user: user)),
        );

        if (result == true) {
          await _refreshUsers();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            // Avatar
            _buildUserAvatar(user),
            const SizedBox(width: 12),

            // Thông tin user
            Expanded(child: _buildUserInfo(user, isDarkMode)),

            // Nút theo dõi
            _buildFollowButton(user, isFollowing, isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildUserAvatar(UserInfoModel user) {
    return CircleAvatar(
      radius: 26,
      backgroundColor: Colors.grey.shade300,
      backgroundImage:
          (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
              ? NetworkImage(user.avatarUrl!)
              : null,
      child:
          (user.avatarUrl == null || user.avatarUrl!.isEmpty)
              ? const Icon(Icons.person, size: 30)
              : null,
    );
  }

  Widget _buildUserInfo(UserInfoModel user, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          user.displayName ?? 'Không có tên',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppTextStyles.normalTextColor(isDarkMode),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          '@${user.username ?? ''}',
          style: TextStyle(
            color: AppTextStyles.normalTextColor(isDarkMode),
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (user.followers != null && user.followers!.isNotEmpty)
          Text(
            '${user.followers!.length} người theo dõi',
            style: TextStyle(
              color: AppTextStyles.normalTextColor(isDarkMode),
              fontSize: 12,
            ),
          ),
      ],
    );
  }

  Widget _buildFollowButton(
    UserInfoModel user,
    bool isFollowing,
    bool isDarkMode,
  ) {
    return SizedBox(
      width: 120,
      height: 36,
      child: ElevatedButton(
        onPressed: () => _handleFollow(user),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isFollowing
                  ? AppBackgroundStyles.buttonBackgroundSecondary(isDarkMode)
                  : AppBackgroundStyles.buttonBackground(isDarkMode),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        child: Text(
          isFollowing ? "Đang theo dõi" : "Theo dõi",
          style: TextStyle(
            color:
                isFollowing
                    ? Colors.grey[500]
                    : AppTextStyles.buttonTextColor(isDarkMode),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  // Header với logo và nút chat (nếu cần sử dụng)
  Widget _buildHeader(bool isDarkMode) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Center(child: Image.asset('assets/learnity.png', height: 60)),
        Positioned(
          right: 5,
          child: IconButton(
            icon: Icon(
              Icons.chat_bubble_outline,
              size: 30,
              color: AppTextStyles.buttonTextColor(isDarkMode),
            ),
            onPressed: () {
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(builder: (context) => ChatPage()),
              // );
            },
          ),
        ),
      ],
    );
  }
}
