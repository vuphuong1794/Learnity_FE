import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:learnity/screen/Group/Create_Group.dart';
import 'package:learnity/screen/Group/Group_Screen.dart';
import 'package:learnity/screen/menu/pomodoro/PomodoroPage.dart';
import 'package:learnity/screen/menu/privacy_settings_screen.dart';
import 'package:learnity/screen/userpage/helpCenter.dart';
import '../../api/user_apis.dart';
import 'privacy_settings_screen.dart';

import '../../../theme/theme.dart';
import '../../models/user_info_model.dart';
import '../startScreen/intro.dart';
import '../userpage/profile_page.dart';
import 'notes/nodepage.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final List<String> users = [
    'Thu Hà',
    'Thu Hà...',
    'Thúy Vân',
    'Thu Hà',
    'Thu Hà',
    'Thu Hà',
    'Thu Hà',
    'Thu Hà...',
    'Thúy Vân',
    'Thu Hà',
    'Thu Hà',
    'Thu Hà',
  ];
  final user = FirebaseAuth.instance.currentUser;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? firebaseUser;
  String displayName = "Đang tải...";
  String email = "";
  String avatarUrl = "";
  bool isGoogleSignIn = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }
  

  Future<void> _loadUserInfo() async {
    firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) return;

    // Lấy dữ liệu từ Firestore trước
    final snapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser!.uid)
            .get();

    // Kiểm tra nếu user đăng nhập bằng Google
    bool isGoogleUser = false;
    for (var info in firebaseUser!.providerData) {
      if (info.providerId == 'google.com') {
        isGoogleUser = true;
        break;
      }
    }

    setState(() {
      isGoogleSignIn = isGoogleUser;

      if (snapshot.exists) {
        final data = snapshot.data();
        // Ưu tiên dữ liệu từ Firestore
        displayName =
            data?['displayName'] ?? firebaseUser?.displayName ?? "Không có tên";
        avatarUrl = data?['avatarUrl'] ?? firebaseUser?.photoURL ?? "";
        email = data?['email'] ?? firebaseUser?.email ?? "";
      } else {
        // Fallback về dữ liệu từ FirebaseAuth
        displayName = firebaseUser?.displayName ?? "Không có tên";
        avatarUrl = firebaseUser?.photoURL ?? "";
        email = firebaseUser?.email ?? "";
      }
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
    APIs.updateActiveStatus(false);
    await FirebaseAuth.instance.signOut();
    await removeFcmTokenFromFirestore(user!.uid);
    // Đăng xuất Google nếu có đăng nhập bằng Google
    Get.offAll(() => const IntroScreen());
    await GoogleSignIn().signOut();
  }

  void _showSettingsMenu() {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width - 50,
        kToolbarHeight + MediaQuery.of(context).padding.top,
        0,
        0,
      ),
      items: [
        PopupMenuItem(
          value: 'setting_privacy',
          child: Row(
            children: [
              Icon(Icons.lock_outline, color: AppColors.black),
              const SizedBox(width: 10),
              Text(
                'Chỉnh sửa quyền riêng tư',
                style: TextStyle(color: AppColors.black),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, color: AppColors.black),
              const SizedBox(width: 10),
              Text('Đăng xuất', style: TextStyle(color: AppColors.black)),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'setting_privacy') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PrivacySettingsScreen()),
        );
      } else if (value == 'logout') {
        _showLogoutDialog();
      }
    });
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder:
          (BuildContext dialogContext) => AlertDialog(
            title: const Text('Đăng xuất'),
            content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text('Hủy', style: TextStyle(color: AppColors.black)),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  signOut();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonBg,
                ),
                child: const Text(
                  'Đăng xuất',
                  style: TextStyle(color: AppColors.buttonText),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 70,
        title: Row(
          children: [
            Text("Menu", style: TextStyle(color: Colors.black, fontSize: 18)),
            Expanded(
              child: Center(
                child: Image.asset("assets/learnity.png", height: 70),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              onPressed: () {
                _showSettingsMenu();
              },
              icon: Icon(Icons.settings, color: Colors.black),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(color: AppColors.black, height: 1.0),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Material(
                      color:
                          Colors
                              .transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(
                          8,
                        ),
                        onTap: () async {
                          final userInfo = UserInfoModel(
                            displayName: displayName,
                            email: email,
                            avatarUrl:
                                avatarUrl.isNotEmpty
                                    ? avatarUrl
                                    : null, 
                            followers: [],
                          );

                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfilePage(user: userInfo),
                            ),
                          );

                          // Nếu có cập nhật, thì reload lại dữ liệu người dùng
                          if (result == true) {
                            _loadUserInfo();
                          }
                        },

                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundImage: NetworkImage(
                                  avatarUrl.isNotEmpty
                                      ? avatarUrl
                                      : "https://example.com/default_avatar.png",
                                ),

                                radius: 20,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  displayName,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      height: 1,
                      color: AppColors.black,
                    ),
                    SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.add, size: 20),
                        SizedBox(width: 4),
                        Text("Đăng nhập với tài khoản khác"),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Text(
                "Lối tắt của bạn",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              SizedBox(height: 10),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundImage: AssetImage(
                                  "assets/learnity.png",
                                ),
                              ),
                              Positioned(
                                right: 2,
                                bottom: 4,
                                child: CircleAvatar(
                                  radius: 5,
                                  backgroundImage: AssetImage(
                                    "assets/followed.png",
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            users[index],
                            style: TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                childAspectRatio: 2,
                children: [
                  featureButton(Icons.search, "Tìm kiếm", () {
                    //Navigator.push(context, MaterialPageRoute(builder: (context) => SearchScreen()));
                  }),
                  featureButton(Icons.access_time, "Pomodoro", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PomodoroPage()),
                    );
                  }),
                  featureButton(Icons.group, "Nhóm của bạn", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => GroupScreen()),
                    );
                  }),
                  featureButton(Icons.note, "Ghi chú", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => NotesPage()),
                    );
                  }),
                  featureButton(Icons.share, "Đã chia sẻ", () {
                    // Navigator.push(context, MaterialPageRoute(builder: (context) => SharedScreen()));
                  }),
                  featureButton(Icons.help, "Trợ giúp và hỗ trợ", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Helpcenter()),
                    );
                  }),
                ],
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: signOut,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonBg,
                    minimumSize: Size(300, 40),
                  ),
                  child: Text(
                    "Đăng xuất",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget featureButton(IconData icon, String title, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[300],
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(children: [Icon(icon, color: Colors.black, size: 32)]),
          SizedBox(width: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
