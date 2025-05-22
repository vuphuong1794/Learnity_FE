import 'package:flutter/material.dart';
import 'package:learnity/theme/theme.dart';

import '../../models/user_model.dart';

class UserCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onToggleFollow;

  const UserCard({Key? key, required this.user, required this.onToggleFollow})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.black,
            backgroundImage:
                user.avt.isNotEmpty ? NetworkImage(user.avt) : null,
            child:
                user.avt.isEmpty
                    ? const Icon(Icons.person, color: AppColors.white)
                    : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.username,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.fullname,
                  style: const TextStyle(color: AppColors.black, fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onToggleFollow,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  user.isFollowing ? AppColors.white : AppColors.buttonBg,
              // side: BorderSide(
              //   color: user.isFollowing ? Colors.black87 : Colors.black,
              // ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
            ),
            child: Text(
              user.isFollowing ? 'Đang theo dõi' : 'Theo dõi',
              style: TextStyle(
                color: user.isFollowing ? AppColors.black : AppColors.buttonText,
                fontSize: 14,
                fontWeight: FontWeight.bold
              ),
            ),
          ),
        ],
      ),
    );
  }
}
