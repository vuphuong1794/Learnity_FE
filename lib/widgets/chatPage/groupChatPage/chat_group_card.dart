import 'package:flutter/material.dart';

import 'package:learnity/api/user_apis.dart';
import 'package:learnity/enum/message_type.dart';
import 'package:learnity/widgets/common/my_date_util.dart';
import 'package:learnity/models/app_user.dart';
import 'package:learnity/models/message.dart';
import 'package:learnity/screen/chatPage/chat_screen.dart';

import 'package:provider/provider.dart';
import 'package:learnity/theme/theme.dart';
import 'package:learnity/theme/theme_provider.dart';

//card to represent a single user in home screen
class ChatGroupCard extends StatefulWidget {
  final AppUser user;

  const ChatGroupCard({super.key, required this.user});

  @override
  State<ChatGroupCard> createState() => _ChatGroupCardState();
}

class _ChatGroupCardState extends State<ChatGroupCard> {
  //last message info (if null --> no message)
  Message? _message;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Card(
      color: AppBackgroundStyles.mainBackground(isDarkMode),
      // margin: EdgeInsets.symmetric(horizontal: mq.width * .04, vertical: 4),
      // color: Colors.blue.shade100,
      // elevation: 0.5,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(15))),
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(15)),
          onTap: () {
            //for navigating to chat screen
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ChatScreen(user: widget.user)));
          },
          child: StreamBuilder(
            stream: APIs.getLastMessage(widget.user),
            builder: (context, snapshot) {
              final data = snapshot.data?.docs;
              final list =
                  data?.map((e) => Message.fromJson(e.data())).toList() ?? [];
              if (list.isNotEmpty) _message = list[0];

              return ListTile(
                //user profile picture
                leading:  Icon(Icons.group),

                //user name
                title: Text(
                  widget.user.name,
                  style: TextStyle(
                    fontWeight: _message != null &&
                            _message!.read.isEmpty &&
                            _message!.fromId != APIs.user.uid
                        ? FontWeight.w900
                        : FontWeight.w500,
                        color: AppTextStyles.normalTextColor(isDarkMode)
                  ),
                ),


                //last message
                subtitle: Text(
                  _message != null
                      ? _message!.type == MessageType.image
                          ? 'Đã gửi hình ảnh'
                          : _message!.msg
                      : 'Hãy gửi lời chào! 👋',
                  maxLines: 1,
                  style: TextStyle(
                    fontWeight: _message != null &&
                            _message!.read.isEmpty &&
                            _message!.fromId != APIs.user.uid
                        ? FontWeight.w900
                        : FontWeight.w400,
                    color: AppTextStyles.normalTextColor(isDarkMode),
                  ),
                ),


                //last message time
                trailing: Text(
                  _message != null 
                  ? MyDateUtil.getLastMessageTime(
                                context: context, time: _message!.sent)
                                : "",
                  style: TextStyle(
                    fontWeight: _message != null &&
                            _message!.read.isEmpty &&
                            _message!.fromId != APIs.user.uid
                        ? FontWeight.w900
                        : FontWeight.w400,
                    color: AppTextStyles.normalTextColor(isDarkMode),
                  ),
                ),      
              );
            },
          )),
    );
  }
}