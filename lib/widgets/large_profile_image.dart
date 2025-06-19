import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../api/user_apis.dart';

class LargeProfileImage extends StatelessWidget {
  final double size;
  final String? url;
  final bool isOnline;

  const LargeProfileImage({
    super.key,
    required this.size,
    this.url,
    this.isOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(size*3)),
          child: CachedNetworkImage(
            width: size*2.5,
            height: size*2.5,
            fit: BoxFit.cover,
            imageUrl: url ?? APIs.user.photoURL.toString(),
            errorWidget: (context, url, error) =>
                const CircleAvatar(child: Icon(CupertinoIcons.person)),
          ),
        ),
        if (isOnline)
          Positioned(
            bottom: 3,
            right: 3,
            child: Container(
              width: size * 0.5,
              height: size * 0.5,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white, // để có viền trắng tách nền
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}