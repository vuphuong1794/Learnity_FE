import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:learnity/api/user_apis.dart';

import 'package:provider/provider.dart';
import 'package:learnity/theme/theme.dart';
import 'package:learnity/theme/theme_provider.dart';

class CreatePostBarWidget extends StatefulWidget {
  final VoidCallback onTapTextField;
  final VoidCallback onTapPhoto;
  final VoidCallback onTapCamera;
  final VoidCallback onTapMic;

  const CreatePostBarWidget({
    super.key,
    required this.onTapTextField,
    required this.onTapPhoto,
    required this.onTapCamera,
    required this.onTapMic, String? currentUserAvatarUrl,
  });

  @override
  State<CreatePostBarWidget> createState() => _CreatePostBarWidgetState();
}

class _CreatePostBarWidgetState extends State<CreatePostBarWidget> {
  String? _fetchedUserAvatarUrl;
  bool _isLoadingAvatar = true;
  final APIs _userApi = APIs();

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  Future<void> _loadAvatar() async {
    setState(() {
      _isLoadingAvatar = true;
    });
    final avatarUrl = await _userApi.getCurrentUserAvatarUrl();
    if (mounted) {
      setState(() {
        _fetchedUserAvatarUrl = avatarUrl;
        _isLoadingAvatar = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: AppBackgroundStyles.buttonBackgroundSecondary(isDarkMode),
        border: Border.all(color: AppColors.black.withOpacity(0.3), width: 1.0),
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          _isLoadingAvatar
              ? const CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey,
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
              : CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey.shade300,
                backgroundImage:
                    (_fetchedUserAvatarUrl != null &&
                            _fetchedUserAvatarUrl!.isNotEmpty)
                        ? NetworkImage(_fetchedUserAvatarUrl!)
                        : null,
                child:
                    (_fetchedUserAvatarUrl == null ||
                            _fetchedUserAvatarUrl!.isEmpty)
                        ? Icon(
                          Icons.person,
                          size: 20,
                          color: Colors.grey.shade700,
                        )
                        : null,
              ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              readOnly: true,
              onTap: widget.onTapTextField,
              decoration: InputDecoration(
                hintText: 'Hãy đăng một gì đó lên nhóm của bạn?',
                hintStyle: TextStyle(
                    color: AppTextStyles.normalTextColor(isDarkMode).withOpacity(0.5),
                  ),
                filled: true,
                fillColor: AppBackgroundStyles.buttonBackgroundSecondary(isDarkMode),
                border: InputBorder.none,
                // hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15),
              ),
              style: const TextStyle(fontSize: 15),
            ),
          ),
          IconButton(
            icon: Icon(Icons.photo_library, color: AppIconStyles.iconPrimary(isDarkMode)),
            onPressed: widget.onTapPhoto,
          ),
          IconButton(
            icon: Icon(Icons.camera_alt, color: AppIconStyles.iconPrimary(isDarkMode)),
            onPressed: widget.onTapCamera,
          ),
        ],
      ),
    );
  }
}
