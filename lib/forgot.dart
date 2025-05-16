import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/gestures.dart';
import 'dart:math'; // Để tạo mã OTP ngẫu nhiên
import 'package:mailer/mailer.dart'; // Thêm thư viện gửi email
import 'package:mailer/smtp_server.dart'; // Thêm thư viện SMTP

import 'login.dart'; // Import để quay lại trang đăng nhập
import 'reset_password.dart'; // Import trang cập nhật mật khẩu mới

class Forgot extends StatefulWidget {
  const Forgot({super.key});

  @override
  State<Forgot> createState() => _ForgotState();
}

class _ForgotState extends State<Forgot> {
  TextEditingController emailController = TextEditingController();
  TextEditingController otpController = TextEditingController();
  bool isLoading = false;
  bool isOtpSent = false;
  String generatedOtp = '';

  // Gửi OTP qua email
  Future<void> sendOtp() async {
    final enteredEmail = emailController.text.trim();

    // Kiểm tra email
    if (enteredEmail.isEmpty) {
      showSnackBar("Vui lòng nhập email của bạn.", Colors.orange);
      return;
    }

    // Kiểm tra định dạng email
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(enteredEmail)) {
      showSnackBar("Email không hợp lệ.", Colors.orange);
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Thay thế phương thức đã bị loại bỏ fetchSignInMethodsForEmail
      // Thay vào đó, chúng ta sẽ sử dụng phương thức sendPasswordResetEmail trực tiếp
      // và bắt lỗi nếu email không tồn tại

      // Tạo OTP ngẫu nhiên (6 chữ số)
      generatedOtp = generateOtp();

      // Gửi email chứa OTP
      await sendOtpEmail(enteredEmail, generatedOtp);

      setState(() {
        isOtpSent = true;
      });

      showSnackBar("Mã OTP đã được gửi đến $enteredEmail", Colors.green);
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'Không tìm thấy tài khoản với email này';
          break;
        case 'invalid-email':
          errorMessage = 'Email không hợp lệ';
          break;
        default:
          errorMessage = 'Đã xảy ra lỗi: ${e.message}';
      }
      showSnackBar(errorMessage, Colors.red);
    } catch (e) {
      showSnackBar('Đã xảy ra lỗi khi gửi OTP: $e', Colors.red);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Tạo mã OTP ngẫu nhiên
  String generateOtp() {
    Random random = Random();
    String otp = '';
    for (int i = 0; i < 6; i++) {
      otp += random.nextInt(10).toString();
    }
    return otp;
  }

  // Gửi email chứa OTP
  Future<void> sendOtpEmail(String email, String otp) async {
    final smtpServer = gmail('pvunguyen84@gmail.com', 'your_app_password');

    final message =
        Message()
          ..from = Address('pvunguyen84@gmail.com', 'HelloDoc')
          ..recipients.add(email)
          ..subject = 'Mã xác nhận đặt lại mật khẩu HelloDoc'
          ..html = '''
      <h1>HelloDoc - Đặt lại mật khẩu</h1>
      <p>Chào bạn,</p>
      <p>Đây là mã xác nhận OTP để đặt lại mật khẩu của bạn:</p>
      <h2>$otp</h2>
      <p>Mã này có hiệu lực trong 10 phút.</p>
      <p>Nếu bạn không yêu cầu đặt lại mật khẩu, vui lòng bỏ qua email này.</p>
      <p>Trân trọng,<br>Đội ngũ HelloDoc</p>
    ''';

    try {
      final sendReport = await send(message, smtpServer);
      print('Email gửi thành công: ${sendReport.toString()}');
    } catch (e) {
      print('Lỗi khi gửi email: $e');
      throw Exception('Không thể gửi email: $e');
    }
  }

  // Xác thực OTP và chuyển đến trang đặt lại mật khẩu
  void verifyOtp() {
    final enteredOtp = otpController.text.trim();

    if (enteredOtp.isEmpty) {
      showSnackBar("Vui lòng nhập mã OTP.", Colors.orange);
      return;
    }

    if (enteredOtp == generatedOtp) {
      // OTP chính xác, chuyển đến trang đặt lại mật khẩu
      Get.to(() => ResetPassword(email: emailController.text.trim()));
    } else {
      showSnackBar("Mã OTP không chính xác.", Colors.red);
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
                        'Thiết lập lại mật khẩu',
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
                        isOtpSent
                            ? 'Vui lòng nhập mã OTP đã được gửi đến email của bạn'
                            : 'Nhập email của bạn để nhận mã xác thực',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                    ),

                    // Trường nhập Email
                    const Text("Email"),
                    const SizedBox(height: 8),
                    TextField(
                      controller: emailController,
                      enabled: !isOtpSent, // Vô hiệu hóa sau khi đã gửi OTP
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Hiển thị trường nhập OTP khi đã gửi OTP
                    if (isOtpSent) ...[
                      const Text("Mã OTP"),
                      const SizedBox(height: 8),
                      TextField(
                        controller: otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          counterText: "",
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Nút chức năng (Gửi OTP hoặc Xác nhận OTP)
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
                        onPressed:
                            isLoading
                                ? null
                                : (isOtpSent ? verifyOtp : sendOtp),
                        child:
                            isLoading
                                ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                                : Text(
                                  isOtpSent ? "Xác nhận" : "Tiếp tục",
                                  style: TextStyle(color: Colors.white),
                                ),
                      ),
                    ),

                    // Nút gửi lại OTP (chỉ hiển thị khi đã gửi OTP)
                    if (isOtpSent) ...[
                      const SizedBox(height: 15),
                      Center(
                        child: RichText(
                          text: TextSpan(
                            text: "Gửi lại mã OTP",
                            style: const TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer:
                                TapGestureRecognizer()
                                  ..onTap = isLoading ? null : sendOtp,
                          ),
                        ),
                      ),
                    ],

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
                                  Get.back(); // Quay lại trang đăng nhập
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
