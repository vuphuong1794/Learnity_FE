import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:learnity/navigation_menu.dart';
import 'package:learnity/screen/adminPage/adminDashboard.dart';
import 'package:learnity/screen/startPage/login.dart';
import 'package:learnity/screen/startPage/set_username_screen.dart';
import 'package:learnity/wrapper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
  bool isLoading = false;

  final _formKey = GlobalKey<FormState>();
  final _usernameNode = FocusNode();
  final _emailNode = FocusNode();
  final _passwordNode = FocusNode();
  final _confirmPasswordNode = FocusNode();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    username.dispose();
    email.dispose();
    password.dispose();
    confirmPassword.dispose();
    _usernameNode.dispose();
    _emailNode.dispose();
    _passwordNode.dispose();
    _confirmPasswordNode.dispose();
    super.dispose();
  }

  // Đăng ký bằng email/password (không thay đổi)
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
      Get.snackbar(
        "Lỗi",
        "Vui lòng điền đầy đủ thông tin.",
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      return;
    }

    // Kiểm tra định dạng email đơn giản
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(enteredEmail)) {
      Get.snackbar(
        "Lỗi",
        "Email không hợp lệ.",
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      return;
    }

    if (enteredPassword.length < 6) {
      Get.snackbar(
        "Lỗi",
        "Mật khẩu phải có ít nhất 6 ký tự.",
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      return;
    }

    if (enteredPassword != enteredConfirmPassword) {
      Get.snackbar(
        "Lỗi",
        "Mật khẩu không khớp.",
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    FirebaseAuth _auth = FirebaseAuth.instance;
    FirebaseFirestore _firestore = FirebaseFirestore.instance;

    try {
      UserCredential userCrendetial = await _auth
          .createUserWithEmailAndPassword(
            email: enteredEmail,
            password: enteredPassword,
          );

      userCrendetial.user!.updateDisplayName(enteredUsername);

      await _firestore.collection('users').doc(_auth.currentUser!.uid).set({
        "username": enteredUsername,
        "email": enteredEmail,
        "uid": _auth.currentUser!.uid,
        "createdAt": DateTime.now(),
        "displayName": enteredUsername,
        "bio": "",
        "avatarUrl":
            "https://imgs.search.brave.com/mDztPWayQWWrIPAy2Hm_FNfDjDVgayj73RTnUIZ15L0/rs:fit:860:0:0:0/g:ce/aHR0cHM6Ly90NC5m/dGNkbi5uZXQvanBn/LzAyLzE1Lzg0LzQz/LzM2MF9GXzIxNTg0/NDMyNV90dFg5WWlJ/SXllYVI3TmU2RWFM/TGpNQW15NEd2UEM2/OS5qcGc",
        "followers": [],
        "following": [],
        "posts": [],
        "role": "user",
      });

      // Điều hướng đến trang đăng nhập sau khi đăng ký thành công
      Get.to(() => const Login());
    } catch (e) {
      Get.snackbar("Lỗi", e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Đăng ký bằng Google
  Future<void> signInWithGoogle() async {
    setState(() => isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => isLoading = false);
        return; // Người dùng hủy đăng nhập
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Đăng nhập với Firebase
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);

      final User? user = userCredential.user;

      if (user != null) {
        final usersRef = FirebaseFirestore.instance.collection('users');
        final userDoc = await usersRef.doc(user.uid).get();

        if (!userDoc.exists) {
          // Nếu chưa có tài khoản, tạo mới và chuyển sang màn hình đặt username
          await usersRef.doc(user.uid).set({
            "email": user.email,
            "uid": user.uid,
            "createdAt": DateTime.now(),
            "displayName": user.displayName,
            "bio": "",
            "avatarUrl": user.photoURL,
            "followers": [],
            "following": [],
            "posts": [],
            "role": "user", // default role
          });

          if (mounted) {
            Get.to(
              () => SetUsernameScreen(
                userId: user.uid,
                displayName: user.displayName,
                initialEmail: user.email,
                avatarUrl: user.photoURL,
              ),
            );
          }
        } else {
          final userData = userDoc.data() as Map<String, dynamic>?;

          if (userData == null ||
              userData['username'] == null ||
              userData['username'].toString().isEmpty) {
            if (mounted) {
              Get.to(
                () => SetUsernameScreen(
                  userId: user.uid,
                  displayName: userData?['displayName'] ?? user.displayName,
                  initialEmail: userData?['email'] ?? user.email,
                  avatarUrl: userData?['avatarUrl'] ?? user.photoURL,
                ),
              );
            }
          } else {
            if (mounted) {
              final role = userData['role'] ?? 'user';
              Get.snackbar(
                "Thông báo",
                "Đăng nhập thành công!",
                backgroundColor: Colors.blue.withOpacity(0.9),
                colorText: Colors.white,
                duration: const Duration(seconds: 4),
              );

              switch (role) {
                case 'admin':
                  Get.offAll(() => const Admindashboard());
                  break;
                default:
                  Get.offAll(() => const NavigationMenu());
                  break;
              }
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          "Lỗi",
          "Không thể đăng nhập bằng Google: ${e.toString()}",
          backgroundColor: Colors.red.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
      ),
    );
  }

  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập tên người dùng';
    }
    if (value.trim().length < 3) {
      return 'Tên người dùng phải có ít nhất 3 ký tự';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập email';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Email không hợp lệ';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }
    if (value.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng xác nhận mật khẩu';
    }
    if (value != password.text) {
      return 'Mật khẩu không khớp';
    }
    return null;
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required FocusNode focusNode,
    FocusNode? nextFocusNode,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    bool isPassword = false,
    VoidCallback? onToggleVisibility,
    bool? isVisible,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF093B29),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          validator: validator,
          keyboardType: keyboardType,
          obscureText: isPassword ? !isVisible! : obscureText,
          textInputAction: textInputAction,
          onFieldSubmitted: (_) {
            if (nextFocusNode != null) {
              FocusScope.of(context).requestFocus(nextFocusNode);
            } else {
              FocusScope.of(context).unfocus();
              if (_formKey.currentState!.validate()) {
                signUp();
              }
            }
          },
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey.shade500),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF093B29), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            suffixIcon:
                isPassword
                    ? IconButton(
                      icon: Icon(
                        isVisible! ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey.shade600,
                      ),
                      onPressed: onToggleVisibility,
                    )
                    : null,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFACF0DD),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Header cố định
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 20,
                ),
                child: Column(
                  children: [
                    const Text(
                      'Learnity',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF093B29),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Đăng Ký',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF093B29),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tạo tài khoản mới để bắt đầu học tập',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),

              // Phần form có thể cuộn
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      // Nút đăng ký bằng Google
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black87,
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _isLoading ? null : signInWithGoogle,
                          child:
                              _isLoading
                                  ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFF093B29),
                                      ),
                                    ),
                                  )
                                  : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.network(
                                        'https://developers.google.com/identity/images/g-logo.png',
                                        height: 20,
                                        width: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        "Tiếp tục với Google",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Divider
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey.shade400)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'HOẶC',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.grey.shade400)),
                        ],
                      ),

                      const SizedBox(height: 24),

                      _buildTextField(
                        controller: username,
                        labelText: "Tên người dùng",
                        hintText: "Nhập tên người dùng của bạn",
                        focusNode: _usernameNode,
                        nextFocusNode: _emailNode,
                        validator: _validateUsername,
                        keyboardType: TextInputType.text,
                      ),
                      const SizedBox(height: 20),

                      _buildTextField(
                        controller: email,
                        labelText: "Email",
                        hintText: "Nhập địa chỉ email của bạn",
                        focusNode: _emailNode,
                        nextFocusNode: _passwordNode,
                        validator: _validateEmail,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 20),

                      _buildTextField(
                        controller: password,
                        labelText: "Mật khẩu",
                        hintText: "Nhập mật khẩu (ít nhất 6 ký tự)",
                        focusNode: _passwordNode,
                        nextFocusNode: _confirmPasswordNode,
                        validator: _validatePassword,
                        isPassword: true,
                        isVisible: _isPasswordVisible,
                        onToggleVisibility: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      const SizedBox(height: 20),

                      _buildTextField(
                        controller: confirmPassword,
                        labelText: "Xác nhận mật khẩu",
                        hintText: "Nhập lại mật khẩu",
                        focusNode: _confirmPasswordNode,
                        validator: _validateConfirmPassword,
                        isPassword: true,
                        isVisible: _isConfirmPasswordVisible,
                        textInputAction: TextInputAction.done,
                        onToggleVisibility: () {
                          setState(() {
                            _isConfirmPasswordVisible =
                                !_isConfirmPasswordVisible;
                          });
                        },
                      ),

                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF093B29),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            disabledBackgroundColor: Colors.grey.shade400,
                          ),
                          onPressed: _isLoading ? null : signUp,
                          child:
                              _isLoading
                                  ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                  : const Text(
                                    "Đăng ký",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      Center(
                        child: RichText(
                          text: TextSpan(
                            text: "Bạn đã có tài khoản? ",
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 14,
                            ),
                            children: [
                              TextSpan(
                                text: "Đăng nhập",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                  color: Color(0xFF093B29),
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

                      const SizedBox(height: 32),

                      Center(
                        child: Text(
                          "Điều khoản sử dụng | Chính sách riêng tư",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
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
