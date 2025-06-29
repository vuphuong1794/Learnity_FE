import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:learnity/screen/startPage/intro.dart';
import 'package:provider/provider.dart';
import 'package:learnity/theme/theme_provider.dart';
import 'package:learnity/screen/homePage/social_feed_page.dart';
import 'package:learnity/theme/theme.dart';

import '../../api/user_apis.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> with WidgetsBindingObserver {
  final user = FirebaseAuth.instance.currentUser;
  bool _lastShowFooter = true;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
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
