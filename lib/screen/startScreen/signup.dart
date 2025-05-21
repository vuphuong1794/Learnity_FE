import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:learnity/screen/startScreen/login.dart';
import 'package:learnity/wrapper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  TextEditingController username = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();
  TextEditingController confirmPassword = TextEditingController();

  signUp() async {
    final enteredUsername = username.text.trim();
    final enteredEmail = email.text.trim();
    final enteredPassword = password.text.trim();
    final enteredConfirmPassword = confirmPassword.text.trim();

    // Kiểm tra dữ liệu đầu vào
    if (enteredUsername.isEmpty ||
        enteredEmail.isEmpty ||
        enteredPassword.isEmpty ||
        enteredConfirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập đầy đủ thông tin.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Kiểm tra định dạng email đơn giản
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(enteredEmail)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email không hợp lệ.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (enteredPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mật khẩu phải có ít nhất 6 ký tự.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (enteredPassword != enteredConfirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mật khẩu không khớp.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    FirebaseAuth _auth = FirebaseAuth.instance;

    FirebaseFirestore _firestore = FirebaseFirestore.instance;
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text.trim(),
      );

      await _firestore.collection('users').doc(_auth.currentUser!.uid).set({
        "username": enteredUsername,
        "email": enteredEmail,
        "uid": _auth.currentUser!.uid,
        "createdAt": DateTime.now(),
        "bio": "",
        "avatarUrl": "",
        "followers": [],
        "following": [],
        "posts": [],
      });

      // Điều hướng đến trang đăng nhập sau khi đăng ký thành công
      Get.to(() => const Login());
    } catch (e) {
      Get.snackbar("Lỗi", e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFACF0DD),
      body: SafeArea(
        // Đảm bảo nội dung không bị che bởi notch hoặc các khu vực an toàn
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Column(
                children: [
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      'Learnity',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      'Đăng Ký',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              // Phần chính của form đăng ký
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),

                      const Text("Username"),
                      const SizedBox(height: 8),
                      TextField(
                        controller: username,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),

                      const Text("Email"),
                      const SizedBox(height: 8),
                      TextField(
                        controller: email,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),

                      const Text("Mật khẩu"),
                      const SizedBox(height: 8),
                      TextField(
                        controller: password,
                        obscureText: true,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),

                      const Text("Xác nhận mật khẩu"),
                      const SizedBox(height: 8),
                      TextField(
                        controller: confirmPassword,
                        obscureText: true,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              0xFF093B29,
                            ), // Màu xanh đậm
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: (() => signUp()),
                          child: const Text(
                            "Đăng ký",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),

                      SizedBox(height: 30),
                      Center(
                        child: RichText(
                          text: TextSpan(
                            text: "Bạn đã có tài khoản? ",
                            style: TextStyle(color: Colors.black),
                            children: [
                              TextSpan(
                                text: "Đăng nhập",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                  color: Colors.blue,
                                ),
                                recognizer:
                                    TapGestureRecognizer()
                                      ..onTap = () {
                                        Get.to(() => const Login());
                                      },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Phần chân trang với điều khoản
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Center(
                  child: Text(
                    "Điều khoản sử dụng | Chính sách riêng tư",
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
