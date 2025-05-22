import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:learnity/screen/searchPage/search_user_page.dart';
import 'package:learnity/screen/homePage/social_feed_page.dart';
import 'package:learnity/screen/menu/menupage.dart';
import '../../theme/theme.dart';
import 'package:provider/provider.dart';
import '../../theme/theme_provider.dart';
import 'package:learnity/screen/userpage/create_post_page.dart';
import 'screen/userpage/notifyPage.dart';

class NavigationMenu extends StatefulWidget {
  const NavigationMenu({super.key});

  @override
  State<NavigationMenu> createState() => _NavigationMenuState();
}

class _NavigationMenuState extends State<NavigationMenu> {
  final controller = Get.put(NavigationController());
  late Widget currentScreen;

// 👇 Biến lưu subscription để huỷ sau này
  late Worker _listener;

  @override
  void initState() {
    super.initState();
    currentScreen = controller.getScreen();
    _listener = ever(controller.selectedIndex, (index) {
      setState(() {
        currentScreen = controller.getScreen();
      });
    });
  }


  @override
  void dispose() {
    // 👇 Huỷ listener khi widget bị huỷ
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    final iconColor = AppIconStyles.footbarIcon(isDarkMode);

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
            color: AppBackgroundStyles.footerBackground(isDarkMode),
            clipBehavior: Clip.antiAlias,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildNavItem(Icons.home, 0, controller, iconColor),
                  _buildNavItem(Icons.search, 1, controller, iconColor),
                  _buildNavItem(
                    Icons.add_circle_outline,
                    2,
                    controller,
                    iconColor,
                  ),
                  _buildNavItem(
                    Icons.notifications_outlined,
                    3,
                    controller,
                    iconColor,
                  ),
                  _buildNavItem(Icons.menu, 4, controller, iconColor),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildNavItem(
    IconData icon,
    int index,
    NavigationController controller,
    Color iconColor,
  ) {
    final isSelected = controller.selectedIndex.value == index;
    return GestureDetector(
      onTap: () => controller.selectedIndex.value = index,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.blue : iconColor,
          size: 26,
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
      case 2:
        return const CreatePostPage();
      case 3:
        showFooter.value = true;
        return NotificationScreen();
      case 4:
        return MenuScreen();
      default:
        return const SizedBox();
    }
  }
}

