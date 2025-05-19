import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:learnity/screen/startScreen/intro.dart';
import 'package:provider/provider.dart';
import 'package:learnity/theme/theme_provider.dart';
import 'package:learnity/screen/userpage/social_feed_page.dart';
import 'package:learnity/theme/theme.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final user = FirebaseAuth.instance.currentUser;
  bool _lastShowFooter = true;

  signOut() async {
    await FirebaseAuth.instance.signOut();
    // Đăng xuất Google nếu có đăng nhập bằng Google
    await GoogleSignIn().signOut();
    Get.offAll(() => const IntroScreen());
  }

  bool _showHeader = true;

  void _updateHeaderVisibility(bool show) {
    setState(() {
      _showHeader = show;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: AppBackgroundStyles.mainBackground(isDarkMode),
      body: SocialFeedPage(onFooterVisibilityChanged: _updateHeaderVisibility),
    );
  }
}
