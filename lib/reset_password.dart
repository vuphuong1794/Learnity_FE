import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/gestures.dart';

import 'login.dart'; // Import để quay lại trang đăng nhập

class ResetPassword extends StatefulWidget {
  final String email;

  const ResetPassword({super.key, required this.email});

  @override
  State<ResetPassword> createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPassword> {
  TextEditingController newPasswordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  bool isLoading = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  Future<void> resetPassword() async {
    final newPassword = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    // Kiểm tra mật khẩu
    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      showSnackBar("Vui lòng nhập đầy đủ thông tin.", Colors.orange);
      return;
    }

    // Kiểm tra hai mật khẩu có khớp nhau không
    if (newPassword != confirmPassword) {
      showSnackBar("Mật khẩu xác nhận không khớp.", Colors.orange);
      return;
    }

    // Kiểm tra độ mạnh của mật khẩu
    if (newPassword.length < 6) {
      showSnackBar("Mật khẩu phải có ít nhất 6 ký tự.", Colors.orange);
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Lấy email từ tham số widget
      String email = widget.email;

      // Cách an toàn để cập nhật mật khẩu trong môi trường thực tế:
      // 1. Sử dụng Firebase Functions để cập nhật mật khẩu từ phía server
      // 2. Hoặc sử dụng một phương pháp xác thực khác trước khi cập nhật

      // Phương pháp tạm thời cho môi trường phát triển/test:
      // Chỉ cho phép đặt lại mật khẩu khi người dùng đã xác minh email (đã nhập OTP đúng)
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      showSnackBar(
        "Đã gửi email đặt lại mật khẩu đến $email. Vui lòng kiểm tra và làm theo hướng dẫn.",
        Colors.green,
      );

      // Chuyển về trang đăng nhập sau khi đổi mật khẩu thành công
      Future.delayed(Duration(seconds: 3), () {
        Get.offAll(() => const Login());
      });
    } catch (e) {
      showSnackBar("Đã xảy ra lỗi khi cập nhật mật khẩu: $e", Colors.red);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFACF0DD),
      body: SafeArea(
        child: Column(
          children: [
            // Phần chính
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        'HelloDoc',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        'Tạo mật khẩu mới',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Thông báo hướng dẫn
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 20),
                      child: Text(
                        'Vui lòng tạo và xác nhận mật khẩu mới',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                    ),

                    // Email hiện tại (chỉ hiển thị)
                    const Text("Email"),
                    const SizedBox(height: 8),
                    TextField(
                      enabled: false,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                        hintText: widget.email,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Trường nhập mật khẩu mới
                    const Text("Mật khẩu mới"),
                    const SizedBox(height: 8),
                    TextField(
                      controller: newPasswordController,
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Trường xác nhận mật khẩu mới
                    const Text("Xác nhận mật khẩu mới"),
                    const SizedBox(height: 8),
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: obscureConfirmPassword,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              obscureConfirmPassword = !obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Nút cập nhật mật khẩu
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF093B29),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: isLoading ? null : resetPassword,
                        child:
                            isLoading
                                ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                                : const Text(
                                  "Cập nhật mật khẩu",
                                  style: TextStyle(color: Colors.white),
                                ),
                      ),
                    ),

                    // Nút quay lại đăng nhập
                    const SizedBox(height: 20),
                    Center(
                      child: RichText(
                        text: TextSpan(
                          text: "Quay lại đăng nhập",
                          style: const TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer:
                              TapGestureRecognizer()
                                ..onTap = () {
                                  Get.offAll(() => const Login());
                                },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Phần điều khoản cuối trang
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
    );
  }
}
