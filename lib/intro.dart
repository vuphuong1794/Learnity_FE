import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:learnity/signup.dart';
import 'login.dart';

class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFACF0DD),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const FlutterLogo(size: 100),
              const SizedBox(height: 20),
              const Text(
                "Chào mừng đến Learnity!",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Get.to(() => const Login());
                },
                child: const Text("Đăng nhập"),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Get.to(() => Signup());
                },
                child: const Text("Đăng ký"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
