import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:learnity/screen/adminPage/adminDashboard.dart';
import 'package:learnity/screen/homePage/home_page.dart';
import 'package:learnity/screen/homePage/social_feed_page.dart';
import 'package:learnity/screen/startPage/intro.dart';
import 'package:learnity/screen/startPage/login.dart';
import 'package:learnity/widgets/chatPage/singleChatPage/call_service.dart';
import 'api/user_apis.dart';
import 'main.dart';
import 'navigation_menu.dart';

class Wrapper extends StatefulWidget {
  const Wrapper({super.key});

  @override
  State<Wrapper> createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  bool _initializedListener = false;

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.sizeOf(context);
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Nếu đã đăng nhập
        if (snapshot.connectionState == ConnectionState.active) {
          if (snapshot.hasData) {
            // Gọi lắng nghe cuộc gọi video 1 lần duy nhất
            if (!_initializedListener) {
              APIs.getSelfInfo().then((_) {
                CallService.listen();
              });
              _initializedListener = true;
            }
            // Kiểm tra quyền admin
            return FutureBuilder<bool>(
              future: _checkAdminRole(),
              builder: (context, adminSnapshot) {
                if (adminSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                if (adminSnapshot.hasError) {
                  return const Scaffold(
                    body: Center(child: Text('Lỗi kiểm tra quyền admin')),
                  );
                }

                final isAdmin = adminSnapshot.data ?? false;

                if (isAdmin) {
                  // Chuyển đến trang admin
                  return const Admindashboard();
                } else {
                  // Chuyển đến trang người dùng bình thường
                  return const NavigationMenu();
                }
              },
            );
          } else {
            return const IntroScreen();
          }
        }
        // Đang loading
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }

  Future<bool> _checkAdminRole() async {
    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        return userData['role'] == 'admin';
      }
    } catch (e) {
      print("Error checking admin role: $e");
    }
    return false;
  }
}
