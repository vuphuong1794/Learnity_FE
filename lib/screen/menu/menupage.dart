import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:learnity/screen/menu/pomodoro/PomodoroPage.dart';


import '../../../theme/theme.dart';
import '../intro.dart';
import 'notes/nodepage.dart';
import '../../screen/chatPage/chatPage.dart';



class MenuScreen extends StatelessWidget {
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

  signOut() async {
    await FirebaseAuth.instance.signOut();
    Get.offAll(() => const IntroScreen());
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
              child: Center(child: Image.asset("assets/learnity.png", height: 70)),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Icon(Icons.settings, color: Colors.black),
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
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: AssetImage("assets/learnity.png"),
                          radius: 20,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Trọng Vũ",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Icon(Icons.arrow_drop_down),
                      ],
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
                                backgroundImage: AssetImage("assets/learnity.png"),
                              ),
                              Positioned(
                                right: 2,
                                bottom: 4,
                                child: CircleAvatar(
                                  radius: 5,
                                  backgroundImage:
                                  AssetImage("assets/followed.png"),
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
                  featureButton(Icons.chat, "Nhắn tin", () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ChatPage()));
                  }),
                  featureButton(Icons.search, "Tìm kiếm", () {
                    //Navigator.push(context, MaterialPageRoute(builder: (context) => SearchScreen()));
                  }),
                  featureButton(Icons.access_time, "Pomodoro", () {
                     Navigator.push(context, MaterialPageRoute(builder: (context) => PomodoroPage()));
                  }),
                  featureButton(Icons.group, "Nhóm của bạn", () {
                    // Navigator.push(context, MaterialPageRoute(builder: (context) => GroupScreen()));
                  }),
                  featureButton(Icons.note, "Ghi chú", () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => NotesPage()));
                  }),
                  featureButton(Icons.share, "Đã chia sẻ", () {
                    // Navigator.push(context, MaterialPageRoute(builder: (context) => SharedScreen()));
                  }),
                  featureButton(Icons.help, "Trợ giúp và hỗ trợ", () {
                    // Navigator.push(context, MaterialPageRoute(builder: (context) => HelpScreen()));
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
                  child: Text("Đăng xuất", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.white),),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.black, size: 32),
            ],
          ),
          SizedBox(width: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold),
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
