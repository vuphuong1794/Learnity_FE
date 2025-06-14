import 'package:flutter/material.dart';

import '../../helper/my_date_util.dart';
import '../../main.dart';
import '../../models/app_user.dart';
import '../../widgets/profile_image.dart';

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
    return GestureDetector(
      // for hiding keyboard
      onTap: FocusScope.of(context).unfocus,
      child: Scaffold(
          //app bar
          appBar: AppBar(title: Text(widget.user.name)),

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

                  //user profile picture
                  ProfileImage(
                    size: mq.height * .2,
                    url: widget.user.avatarUrl,
                  ),

                  // for adding some space
                  SizedBox(height: mq.height * .03),

                  // user email label
                  Text(widget.user.email,
                      style:
                          const TextStyle(color: Colors.black87, fontSize: 16)),

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