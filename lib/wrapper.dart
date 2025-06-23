import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:learnity/screen/homePage/home_page.dart';
import 'package:learnity/screen/homePage/social_feed_page.dart';
import 'package:learnity/screen/startScreen/intro.dart';
import 'package:learnity/screen/startScreen/login.dart';
import 'main.dart';
import 'navigation_menu.dart';

class Wrapper extends StatefulWidget {
  const Wrapper({super.key});

  @override
  State<Wrapper> createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.sizeOf(context);
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Nếu đã đăng nhập
        if (snapshot.connectionState == ConnectionState.active) {
          if (snapshot.hasData) {
            return const NavigationMenu();
          } else {
            return const IntroScreen();
          }
        }
        // Đang loading
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
