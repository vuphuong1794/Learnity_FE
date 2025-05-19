
import 'package:flutter/material.dart';
import 'user_info_model.dart';
import 'their_profile_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TheirProfilePage(
        user: UserInfoModel(
          nickname: "Cá Mập",
          fullName: "Tôn Hành Giả",
          followers: 123,
          avatarPath: "assets/avatar.png",
        ),
      ),
    );
  }
}
