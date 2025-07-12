import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'login.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  int step = 1;
  bool isLoading = false;

  final FocusNode otpFocusNode = FocusNode();

  final String apiBaseUrl = "https://learnity-be.onrender.com";

  void showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  Future<void> sendOtp() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      showSnackBar("Vui lòng nhập email.", Colors.orange);
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/auth/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        showSnackBar("OTP đã được gửi về email.", Colors.green);
        setState(() => step = 2);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          otpFocusNode.requestFocus();
        });
      } else {
        showSnackBar(data['message'] ?? 'Lỗi gửi OTP.', Colors.red);
      }
    } catch (e) {
      showSnackBar('Lỗi gửi OTP: $e', Colors.red);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> verifyOtp() async {
    final email = emailController.text.trim();
    final otp = otpController.text.trim();
    if (otp.isEmpty) {
      showSnackBar("Vui lòng nhập mã OTP.", Colors.orange);
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otp': otp}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        showSnackBar("Xác minh OTP thành công.", Colors.green);
        setState(() => step = 3);
      } else {
        showSnackBar(data['message'] ?? 'Lỗi xác minh OTP.', Colors.red);
      }
    } catch (e) {
      showSnackBar('Lỗi xác minh OTP: $e', Colors.red);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> resetPassword() async {
    final email = emailController.text.trim();
    final newPassword = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      showSnackBar("Vui lòng nhập đầy đủ mật khẩu.", Colors.orange);
      return;
    }

    if (newPassword != confirmPassword) {
      showSnackBar("Mật khẩu không khớp.", Colors.orange);
      return;
    }

    if (newPassword.length < 6) {
      showSnackBar("Mật khẩu phải ít nhất 6 ký tự.", Colors.orange);
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'newPassword': newPassword}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        showSnackBar("Đặt lại mật khẩu thành công.", Colors.green);
        Future.delayed(const Duration(seconds: 2), () {
          Get.back(); // Quay lại trang login
        });
      } else {
        showSnackBar(data['message'] ?? 'Lỗi đổi mật khẩu.', Colors.red);
      }
    } catch (e) {
      showSnackBar('Lỗi đổi mật khẩu: $e', Colors.red);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget buildStep1() => Column(
    children: [
      const SizedBox(height: 20),
      Center(
        child: Text(
          'Learnity',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
      const SizedBox(height: 20),
      Center(
        child: Text(
          'Thiết lập lại mật khẩu',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
      ),
      const SizedBox(height: 20),
      Text(
        'Nhấp vào "Tiếp tục" để đặt lại mật khẩu',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
      ),
      const SizedBox(height: 30),

      TextField(
        controller: emailController,
        decoration: InputDecoration(
          labelText: "Email",
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 12,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      const SizedBox(height: 30),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isLoading ? null : sendOtp,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF093B29),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child:
              isLoading
                  ? const CircularProgressIndicator()
                  : const Text(
                    "Tiếp tục",
                    style: TextStyle(color: Colors.white),
                  ),
        ),
      ),

      const SizedBox(height: 30),
      Center(
        child: RichText(
          text: TextSpan(
            text: 'Quay lại đăng nhập',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: Colors.blue, // Add color for clickable text
            ),
            recognizer:
                TapGestureRecognizer()
                  ..onTap = () {
                    Get.to(() => const Login());
                  },
          ),
        ),
      ),
    ],
  );

  Widget buildStep2() => Column(
    children: [
      const SizedBox(height: 20),
      Center(
        child: Text(
          'Learnity',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
      const SizedBox(height: 20),
      Center(
        child: Text(
          "Kiểm tra hộp thư đến\ncủa bạn",
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
      ),
      const SizedBox(height: 20),
      Text(
        'Vui lòng nhập mã xác minh chúng tôi vừa gửi đến ${emailController.text.trim()}',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
      ),
      const SizedBox(height: 30),

      TextField(
        focusNode: otpFocusNode,
        controller: otpController,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          labelText: "Mã OTP",
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 12,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      const SizedBox(height: 30),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isLoading ? null : verifyOtp,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF093B29),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child:
              isLoading
                  ? const CircularProgressIndicator()
                  : const Text(
                    "Tiếp tục",
                    style: TextStyle(color: Colors.white),
                  ),
        ),
      ),

      const SizedBox(height: 30),
      Center(
        child: RichText(
          text: TextSpan(
            text: isLoading ? "Đang gửi lại..." : "Gửi lại email",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: Colors.blue, // Add color for clickable text
            ),
            recognizer:
                TapGestureRecognizer()
                  ..onTap = () {
                    isLoading ? null : sendOtp();
                  },
          ),
        ),
      ),
    ],
  );

  Widget buildStep3() => Column(
    children: [
      const SizedBox(height: 20),
      Center(
        child: Text(
          'Learnity',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
      const SizedBox(height: 20),
      Center(
        child: Text(
          "Tạo mật khẩu mới",
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
      ),
      const SizedBox(height: 30),

      TextField(
        controller: newPasswordController,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          labelText: "Mật khẩu mới",
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 12,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      const SizedBox(height: 30),
      TextField(
        controller: confirmPasswordController,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          labelText: "Nhập lại mật khẩu",
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 12,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      const SizedBox(height: 30),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isLoading ? null : resetPassword,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF093B29),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child:
              isLoading
                  ? const CircularProgressIndicator()
                  : const Text(
                    "Tiếp tục",
                    style: TextStyle(color: Colors.white),
                  ),
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFACF0DD),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    Expanded(
                      child:
                          step == 1
                              ? buildStep1()
                              : step == 2
                              ? buildStep2()
                              : buildStep3(),
                    ),
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
          ),
        ),
      ),
    );
  }
}
