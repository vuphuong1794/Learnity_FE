import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:learnity/models/user_info_model.dart';

import '../screen/userPage/profile_page.dart';
import '../screen/userPage/their_profile_page.dart';

void navigateToUserProfile(BuildContext context, UserInfoModel user) {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  if (user.uid == currentUserId) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage(user: user)));
  } else {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TheirProfilePage(user: user)),
    );
  }
}
