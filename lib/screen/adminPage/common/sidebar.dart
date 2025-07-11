import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:learnity/api/user_apis.dart';
import 'package:learnity/screen/adminPage/accountManager.dart';
import 'package:learnity/screen/adminPage/adminDashboard.dart';
import 'package:learnity/screen/adminPage/postManager.dart';
import 'package:learnity/screen/adminPage/groupManager.dart';
import 'package:learnity/screen/adminPage/postTagManager.dart';
import 'package:learnity/screen/adminPage/reportManager.dart';
import 'package:learnity/screen/startPage/intro.dart';

class Sidebar extends StatefulWidget {
  const Sidebar({super.key});

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final user = FirebaseAuth.instance.currentUser;
  void setStatus(String status) async {
    await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
      "status": status,
      "updateStatusAt": FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeFcmTokenFromFirestore(String uid) async {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken != null) {
      final usersRef = FirebaseFirestore.instance.collection('users');
      await usersRef.doc(uid).update({
        'fcmTokens': FieldValue.arrayRemove([fcmToken]),
      });
    }
  }

  signOut() async {
    setStatus("Offline");
    await FirebaseAuth.instance.signOut();
    await removeFcmTokenFromFirestore(user!.uid);
    // Đăng xuất Google nếu có đăng nhập bằng Google
    Get.offAll(() => const IntroScreen());
    await GoogleSignIn().signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(0),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.grey.shade100],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 40),
          children: [
            Text(
              'Learnity Admin',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            _buildDrawerItem(Icons.dashboard, 'Dashboard', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Admindashboard()),
              );
            }),
            _buildDrawerItem(Icons.person, 'Quản lý tài khoản', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Accountmanager()),
              );
            }),
            _buildDrawerItem(Icons.report_problem, 'Quản lý khiếu nại', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Reportmanager()),
              );
            }),
            _buildDrawerItem(Icons.groups, 'Quản lý nhóm', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Groupmanager()),
              );
            }),
            _buildDrawerItem(Icons.edit_note, 'Quản lý bài viết', () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PostManagerScreen(),
                ),
              );
            }),
            _buildDrawerItem(Icons.info, "Quản lý Tags Bài Viết", () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminPostTagPage(),
                ),
              );
            }),

            const Divider(),
            _buildDrawerItem(Icons.logout, 'Đăng xuất', () {
              signOut();
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(title),
      onTap: onTap,
    );
  }
}
