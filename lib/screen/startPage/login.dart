import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:learnity/screen/adminPage/adminDashboard.dart';
import 'package:learnity/screen/startPage/set_username_screen.dart';

import 'forgot.dart';
import 'signup.dart';
import '../../navigation_menu.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();

  final FocusNode emailFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();

  bool rememberMe = false;
  bool obscurePassword = true;
  bool isLoading = false;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
    super.dispose();
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

  Future<void> saveFcmTokenToFirestore(String uid) async {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken != null) {
      final usersRef = FirebaseFirestore.instance.collection('users');
      await usersRef.doc(uid).update({
        'fcmTokens': FieldValue.arrayUnion([fcmToken]),
        'lastFcmTokenUpdate': DateTime.now(),
      });
    }
  }

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
              await saveFcmTokenToFirestore(user.uid);

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
        showSnackBar(
          "Lỗi khi đăng nhập bằng Google: ${e.toString()}",
          Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> signIn() async {
    final enteredEmail = email.text.trim();
    final enteredPassword = password.text.trim();

    if (enteredEmail.isEmpty || enteredPassword.isEmpty) {
      showSnackBar("Vui lòng nhập đầy đủ email và mật khẩu.", Colors.orange);
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(enteredEmail)) {
      showSnackBar("Email không hợp lệ.", Colors.orange);
      return;
    }

    if (enteredPassword.length < 6) {
      showSnackBar("Mật khẩu phải có ít nhất 6 ký tự.", Colors.orange);
      return;
    }

    setState(() => isLoading = true);

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: enteredEmail,
        password: enteredPassword,
      );
      final uid = credential.user?.uid;
      print('UID: $uid');
      if (uid != null) {
        final docSnapshot =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();

        if (docSnapshot.exists) {
          final data = docSnapshot.data()!;
          final role = data['role'] ?? 'user';

          await saveFcmTokenToFirestore(uid);

          Get.snackbar(
            "Thông báo",
            "Đăng nhập thành công!",
            backgroundColor: Colors.blue.withOpacity(0.9),
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
          );

          // Điều hướng theo role
          switch (role) {
            case 'admin':
              Get.offAll(() => const Admindashboard());
              break;
            default:
              Get.offAll(() => const NavigationMenu());
              break;
          }
        } else {
          Get.snackbar(
            "Lỗi",
            "Tài khoản không tồn tại.",
            backgroundColor: Colors.red.withOpacity(0.9),
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'Tài khoản không tồn tại';
          break;
        case 'wrong-password':
          errorMessage = 'Sai mật khẩu';
          break;
        case 'invalid-email':
          errorMessage = 'Email không hợp lệ';
          break;
        default:
          errorMessage = 'Đã xảy ra lỗi: ${e.message}';
      }
      showSnackBar(errorMessage, Colors.red);
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFACF0DD),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                            'Đăng Nhập',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        const Text("Email"),
                        const SizedBox(height: 8),
                        TextField(
                          controller: email,
                          focusNode: emailFocus,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          onSubmitted:
                              (_) => FocusScope.of(
                                context,
                              ).requestFocus(passwordFocus),
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.email),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text("Mật khẩu"),
                        const SizedBox(height: 8),
                        TextField(
                          controller: password,
                          focusNode: passwordFocus,
                          obscureText: obscurePassword,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => signIn(),
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  obscurePassword = !obscurePassword;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed:
                                () =>
                                    Get.to(() => const ForgotPasswordScreen()),
                            child: const Text("Quên mật khẩu"),
                          ),
                        ),
                        Row(
                          children: [
                            Checkbox(
                              value: rememberMe,
                              onChanged: (val) {
                                setState(() => rememberMe = val ?? false);
                              },
                            ),
                            const Text("Lưu đăng nhập"),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : signIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF093B29),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child:
                                isLoading
                                    ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                    : const Text(
                                      "Đăng nhập",
                                      style: TextStyle(color: Colors.white),
                                    ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: RichText(
                            text: TextSpan(
                              text: "Bạn mới biết đến Learnity? ",
                              style: const TextStyle(color: Colors.black),
                              children: [
                                TextSpan(
                                  text: "Đăng ký",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                    color: Colors.blue,
                                  ),
                                  recognizer:
                                      TapGestureRecognizer()
                                        ..onTap =
                                            () => Get.to(() => const Signup()),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: const [
                            Expanded(child: Divider()),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Text("Hoặc"),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: isLoading ? null : signInWithGoogle,
                            icon: Image.asset(
                              'assets/google.png',
                              height: 20,
                              width: 20,
                            ),
                            label: const Text(
                              "Tiếp tục với Google",
                              style: TextStyle(color: Colors.black),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        Center(
                          child: Text(
                            "Điều khoản sử dụng | Chính sách riêng tư",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
