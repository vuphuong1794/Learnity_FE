import 'package:flutter/material.dart';

import '../../helper/my_date_util.dart';
import '../../main.dart';
import '../../models/app_user.dart';
import '../../widgets/chatPage/singleChatPage/large_profile_image.dart';
import '../../widgets/chatPage/singleChatPage/profile_image.dart';

import 'package:provider/provider.dart';
import 'package:learnity/theme/theme.dart';
import 'package:learnity/theme/theme_provider.dart';

//view profile screen -- to view profile of user
class ViewProfileScreen extends StatefulWidget {
  final AppUser user;

  const ViewProfileScreen({super.key, required this.user});

  @override
  State<ViewProfileScreen> createState() => _ViewProfileScreenState();
}

class _ViewProfileScreenState extends State<ViewProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return GestureDetector(
      // for hiding keyboard
      onTap: FocusScope.of(context).unfocus,
      child: Scaffold(
        backgroundColor: AppBackgroundStyles.mainBackground(isDarkMode),
          //app bar
          appBar: AppBar(
            backgroundColor: AppBackgroundStyles.mainBackground(isDarkMode),
            iconTheme: IconThemeData(
              color: AppIconStyles.iconPrimary(isDarkMode), // Đổi màu mũi tên tại đây
            ),
            title: Text(widget.user.name, style: TextStyle(color: AppTextStyles.normalTextColor(isDarkMode))),
            elevation: 0, // không cần shadow
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                height: 1,
                color: AppTextStyles.buttonTextColor(isDarkMode).withOpacity(0.2), // bạn có thể chỉnh màu ở đây
              ),
            ),
          ),

          //user about
          // floatingActionButton: Row(
          //   mainAxisAlignment: MainAxisAlignment.center,
          //   children: [
          //     const Text(
          //       'Joined On: ',
          //       style: TextStyle(
          //           color: Colors.black87,
          //           fontWeight: FontWeight.w500,
          //           fontSize: 15),
          //     ),
          //     Text(
          //         MyDateUtil.getLastMessageTime(
          //             context: context,
          //             time: widget.user.createdAt,
          //             showYear: true),
          //         style: const TextStyle(color: Colors.black54, fontSize: 15)),
          //   ],
          // ),

          //body
          body: Padding(
            padding: EdgeInsets.symmetric(horizontal: mq.width * .05),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // for adding some space
                  SizedBox(width: mq.width, height: mq.height * .03),

                  LargeProfileImage(
                    size: mq.height * .05,
                    url: widget.user.avatarUrl,
                    isOnline: widget.user.isOnline,
                  ),

                  // for adding some space
                  SizedBox(height: mq.height * .03),

                  Text(widget.user.name,
                      style:
                          TextStyle(color: AppTextStyles.normalTextColor(isDarkMode), fontSize: 18, fontWeight: FontWeight.bold)),

                  // for adding some space
                  SizedBox(height: mq.height * .01),

                  // user email label
                  Text(widget.user.email,
                      style:
                          TextStyle(color: AppTextStyles.normalTextColor(isDarkMode), fontSize: 14, fontWeight: FontWeight.w300)),

                  // for adding some space
                  SizedBox(height: mq.height * .02),

                  //user about
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.center,
                  //   children: [
                  //     const Text(
                  //       'About: ',
                  //       style: TextStyle(
                  //           color: Colors.black87,
                  //           fontWeight: FontWeight.w500,
                  //           fontSize: 15),
                  //     ),
                  //     Text(widget.user.bio,
                  //         style: const TextStyle(
                  //             color: Colors.black54, fontSize: 15)),
                  //   ],
                  // ),
                ],
              ),
            ),
          )),
    );
  }
}