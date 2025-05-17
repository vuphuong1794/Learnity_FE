import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  final String apiBaseUrl = "http://192.168.1.8:3000";

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
      if (response.statusCode == 200) {
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
      const Text("Nhập Email để nhận OTP", style: TextStyle(fontSize: 18)),
      const SizedBox(height: 16),
      TextField(
        controller: emailController,
        decoration: const InputDecoration(labelText: 'Email'),
      ),
      const SizedBox(height: 20),
      ElevatedButton(
        onPressed: isLoading ? null : sendOtp,
        child:
            isLoading
                ? const CircularProgressIndicator()
                : const Text("Gửi OTP"),
      ),
    ],
  );

  Widget buildStep2() => Column(
    children: [
      const Text("Nhập mã OTP", style: TextStyle(fontSize: 18)),
      const SizedBox(height: 16),
      TextField(
        controller: otpController,
        decoration: const InputDecoration(labelText: 'OTP'),
      ),
      const SizedBox(height: 20),
      ElevatedButton(
        onPressed: isLoading ? null : verifyOtp,
        child:
            isLoading
                ? const CircularProgressIndicator()
                : const Text("Xác minh OTP"),
      ),
    ],
  );

  Widget buildStep3() => Column(
    children: [
      const Text("Tạo mật khẩu mới", style: TextStyle(fontSize: 18)),
      const SizedBox(height: 16),
      TextField(
        controller: newPasswordController,
        obscureText: true,
        decoration: const InputDecoration(labelText: 'Mật khẩu mới'),
      ),
      const SizedBox(height: 10),
      TextField(
        controller: confirmPasswordController,
        obscureText: true,
        decoration: const InputDecoration(labelText: 'Xác nhận mật khẩu'),
      ),
      const SizedBox(height: 20),
      ElevatedButton(
        onPressed: isLoading ? null : resetPassword,
        child:
            isLoading
                ? const CircularProgressIndicator()
                : const Text("Đặt lại mật khẩu"),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Quên mật khẩu")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            step == 1
                ? buildStep1()
                : step == 2
                ? buildStep2()
                : buildStep3(),
      ),
    );
  }
}
