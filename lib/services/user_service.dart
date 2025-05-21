import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserInfoResult {
  final String displayName;
  final String email;
  final String avatarUrl;
  final bool isGoogleSignIn;

  UserInfoResult({
    required this.displayName,
    required this.email,
    required this.avatarUrl,
    required this.isGoogleSignIn,
  });
}

class UserService {
  static Future<UserInfoResult?> loadUserInfo() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return null;

    bool isGoogleSignIn = firebaseUser.providerData.any(
      (info) => info.providerId == 'google.com',
    );

    String displayName = firebaseUser.displayName ?? "Không có tên";
    String email = firebaseUser.email ?? "";
    String avatarUrl = firebaseUser.photoURL ?? "";

    if (!isGoogleSignIn) {
      final docSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(firebaseUser.uid)
              .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        displayName = data?['username'] ?? displayName;
        email = data?['email'] ?? email;
        avatarUrl = data?['avatarUrl'] ?? avatarUrl;
      }
    }

    print("firebaseUser.uid: ${firebaseUser.uid}");
    print("firebaseUser.email: ${firebaseUser.email}");

    return UserInfoResult(
      displayName: displayName,
      email: email,
      avatarUrl: avatarUrl,
      isGoogleSignIn: isGoogleSignIn,
    );
  }
}
