import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:learnity/models/user_info_model.dart';
import 'package:learnity/services/user_service.dart';

class CustomAppBar extends StatefulWidget {
  const CustomAppBar({super.key});

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  bool _isLoading = false;
  UserInfoModel currentUser = UserInfoModel(
    uid: '',
    username: '',
    displayName: '',
    avatarUrl: '',
  );

  UserInfoResult? userInfo;

  @override
  void initState() {
    super.initState();
    _refreshUserData();
  }

  Future<void> _refreshUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (doc.exists && mounted) {
        final data = doc.data();
        if (data != null) {
          setState(() {
            // Cập nhật thông tin người dùng hiện tại
            currentUser = UserInfoModel(
              uid: uid,
              username: data['username'] ?? '',
              displayName: data['displayName'] ?? '',
              avatarUrl: data['avatarUrl'] ?? '',
            );
          });
        }
      }
    } catch (e) {
      debugPrint('Lỗi khi tải dữ liệu người dùng: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  final user = FirebaseAuth.instance.currentUser;
  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Builder(
        builder:
            (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.black),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
      ),
      title: Text(
        'Xin chào ${currentUser.displayName}!',
        style: TextStyle(color: Colors.black, fontSize: 16),
      ),
      actions: [
        Icon(Icons.notifications_outlined, color: Colors.grey),
        SizedBox(width: 16),
      ],
    );
  }
}
