import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:learnity/screen/intro.dart';
import 'package:learnity/theme/theme.dart';
import 'package:provider/provider.dart';
import '../../theme/theme_provider.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final user = FirebaseAuth.instance.currentUser;

  signOut() async {
    await FirebaseAuth.instance.signOut();
    Get.offAll(() => const IntroScreen());
  }

  @override
  Widget build(BuildContext context) {
    // Lấy provider
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: themeProvider.isDarkMode 
          ? AppColors.darkBackground 
          : AppColors.white,
      appBar: AppBar(title: const Text('Homepage')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(child: Text('${user?.email ?? "Không có email"}')),
          const SizedBox(height: 20),
          SwitchListTile(
            title: const Text("Chế độ tối"),
            value: isDarkMode,
            onChanged: (value) {
              themeProvider.setDarkMode(value);
            },
            secondary: const Icon(Icons.dark_mode),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: signOut,
        child: const Icon(Icons.logout),
      ),
    );
  }
}
