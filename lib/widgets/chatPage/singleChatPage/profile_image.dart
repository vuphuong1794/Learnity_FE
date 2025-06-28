import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../api/user_apis.dart';

import 'package:provider/provider.dart';
import 'package:learnity/theme/theme.dart';
import 'package:learnity/theme/theme_provider.dart';

class ProfileImage extends StatelessWidget {
  final double size;
  final String? url;
  final bool isOnline;

  const ProfileImage({
    super.key,
    required this.size,
    this.url,
    this.isOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(size)),
          child: CachedNetworkImage(
            width: size,
            height: size,
            fit: BoxFit.cover,
            imageUrl: url ?? APIs.user.photoURL.toString(),
            errorWidget: (context, url, error) =>
                const CircleAvatar(child: Icon(CupertinoIcons.person)),
          ),
        ),
        if (isOnline)
          Positioned(
            bottom: -2,
            right: -2,
            child: Container(
              width: size * 0.35,
              height: size * 0.35,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppBackgroundStyles.mainBackground(isDarkMode), // để có viền trắng tách nền
                  width: 2.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}