import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:learnity/screen/intro.dart';
import 'package:learnity/theme/theme.dart';
import 'package:provider/provider.dart';
import '../../theme/theme_provider.dart';
import 'package:flutter/rendering.dart';
import '../widgets/footer_bar.dart';

class Homepage extends StatefulWidget {
  final void Function(bool)? onFooterVisibilityChanged; // Thông báo ra ngoài
  const Homepage({super.key, this.onFooterVisibilityChanged});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final user = FirebaseAuth.instance.currentUser;
  bool _lastShowFooter = true;

  signOut() async {
    await FirebaseAuth.instance.signOut();
    Get.offAll(() => const IntroScreen());
  }

  void _notifyFooter(bool show) {
    if (_lastShowFooter != show) {
      _lastShowFooter = show;
      widget.onFooterVisibilityChanged?.call(show);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: AppBackgroundStyles.mainBackground(isDarkMode),
      appBar: AppBar(
        title: const Text('Homepage'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: signOut,
            tooltip: 'Đăng xuất',
          ),
        ],
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (scrollNotification) {
          if (scrollNotification is UserScrollNotification) {
            final direction = scrollNotification.direction;
            if (direction == ScrollDirection.forward) {
              _notifyFooter(true); // Lướt lên
            } else if (direction == ScrollDirection.reverse) {
              _notifyFooter(false); // Lướt xuống
            }
          }
          return false;
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Email: ',
                      style: AppTextStyles.label(isDarkMode),
                    ),
                    TextSpan(
                      text: user?.email ?? "Không có email",
                      style: AppTextStyles.body(isDarkMode),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            SwitchListTile(
              title: Text(
                "Chế độ tối",
                style: AppTextStyles.subtitle(isDarkMode),
              ),
              value: isDarkMode,
              onChanged: (value) {
                themeProvider.setDarkMode(value);
              },
              secondary: Icon(
                Icons.dark_mode,
                color: isDarkMode
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 1000),
          ],
        ),
      ),
    );
  }
}
