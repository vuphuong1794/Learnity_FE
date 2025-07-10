import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:learnity/api/user_apis.dart';
import 'package:learnity/screen/menuPage/pomodoro/pomodoro_page.dart';
import 'package:learnity/screen/searchPage/search_user_page.dart';
import 'package:learnity/screen/homePage/social_feed_page.dart';
import 'package:learnity/screen/menuPage/menu_page.dart';
import '../../theme/theme.dart';
import 'package:provider/provider.dart';
import '../../theme/theme_provider.dart';
import 'package:learnity/screen/createPostPage/create_post_page.dart';
import 'screen/notifyPage/notify_page.dart';

class NavigationMenu extends StatefulWidget {
  const NavigationMenu({super.key});

  @override
  State<NavigationMenu> createState() => _NavigationMenuState();
}

class _NavigationMenuState extends State<NavigationMenu>
    with WidgetsBindingObserver {
  final controller = Get.put(NavigationController());
  late Widget currentScreen;

  // 👇 Biến lưu subscription để huỷ sau này
  late Worker _listener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    APIs.updateActiveStatus(true);
    currentScreen = controller.getScreen();
    _listener = ever(controller.selectedIndex, (index) {
      setState(() {
        currentScreen = controller.getScreen();
      });
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // online
      APIs.updateActiveStatus(true);
    } else {
      // offline
      APIs.updateActiveStatus(false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    final iconColor = AppTextStyles.buttonTextColor(isDarkMode);

    return Obx(() {
      final index = controller.selectedIndex.value;
      final isHome = index == 0;

      return Scaffold(
        body: currentScreen,
        bottomNavigationBar: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: isHome && !controller.showFooter.value ? 0 : 70,
          curve: Curves.easeOut,
          child: Material(
            elevation: 10,
            color: AppBackgroundStyles.buttonBackground(isDarkMode),
            clipBehavior: Clip.antiAlias,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildNavItem(
                    isDarkMode,
                    Icons.home,
                    0,
                    controller,
                    iconColor,
                  ),
                  _buildNavItem(
                    isDarkMode,
                    Icons.search,
                    1,
                    controller,
                    iconColor,
                  ),
                  _buildNavItem(
                    isDarkMode,
                    Icons.add_circle_outline,
                    2,
                    controller,
                    iconColor,
                  ),
                  _buildNotificationNavItem(isDarkMode, controller, iconColor),
                  _buildNavItem(
                    isDarkMode,
                    Icons.menu,
                    4,
                    controller,
                    iconColor,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildNavItem(
    bool isDarkMode,
    IconData icon,
    int index,
    NavigationController controller,
    Color iconColor,
  ) {
    final isSelected = controller.selectedIndex.value == index;

    return GestureDetector(
      onTap: () {
        if (index == 2) {
          // 👉 xử lý chuyển trang PomodoroPage tại đây vì cần context
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreatePostPage()),
          );
        } else {
          controller.selectedIndex.value = index;
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppBackgroundStyles.buttonBackgroundSecondary(isDarkMode)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          color:
              isSelected
                  ? AppTextStyles.buttonTextSecondaryColor(isDarkMode)
                  : iconColor,
          size: 26,
        ),
      ),
    );
  }

  Widget _buildNotificationNavItem(
    bool isDarkMode,
    NavigationController controller,
    Color iconColor,
  ) {
    final isSelected = controller.selectedIndex.value == 3;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return GestureDetector(
      onTap: () {
        controller.selectedIndex.value = 3;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppBackgroundStyles.buttonBackgroundSecondary(isDarkMode)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Icon(
              Icons.notifications_outlined,
              color:
                  isSelected
                      ? AppTextStyles.buttonTextSecondaryColor(isDarkMode)
                      : iconColor,
              size: 26,
            ),
            if (currentUserId != null)
              StreamBuilder<int>(
                stream: APIs.getUnreadNotificationCount(currentUserId),
                builder: (context, snapshot) {
                  final unreadCount = snapshot.data ?? 0;

                  if (unreadCount == 0) {
                    return const SizedBox.shrink();
                  }

                  return Positioned(
                    right: 0,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppBackgroundStyles.buttonBackground(
                            isDarkMode,
                          ),
                          width: 1,
                        ),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class NavigationController extends GetxController {
  final Rx<int> selectedIndex = 0.obs;
  final RxBool showFooter = true.obs;

  Widget getScreen() {
    switch (selectedIndex.value) {
      case 0:
        showFooter.value = true;
        return SocialFeedPage(
          onFooterVisibilityChanged: (visible) => showFooter.value = visible,
        );
      case 1:
        return SearchUserPage();
      // case 2:
      //   return const CreatePostPage();
      case 3:
        showFooter.value = true;
        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        print('Current User ID: $currentUserId');
        if (currentUserId == null)
          return const Center(child: Text('Chưa đăng nhập'));
        return NotificationScreen(currentUserId: currentUserId);
      case 4:
        return MenuScreen();
      default:
        return const SizedBox();
    }
  }
}
