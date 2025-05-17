import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:learnity/screen/userpage/homepage.dart';
import 'package:learnity/screen/intro.dart';
import 'package:learnity/screen/login.dart';

class Wrapper extends StatefulWidget {
  const Wrapper({super.key});

  @override
  State<Wrapper> createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Nếu đã đăng nhập
        if (snapshot.connectionState == ConnectionState.active) {
          if (snapshot.hasData) {
            return const Homepage();
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
