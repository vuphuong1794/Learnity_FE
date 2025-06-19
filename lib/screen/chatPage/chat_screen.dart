import 'dart:io';
import 'dart:math' as math;
import 'dart:developer' as dev;


import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../api/user_apis.dart';
import '../../enum/message_type.dart';
import '../../helper/my_date_util.dart';
import '../../main.dart';
import '../../models/app_user.dart';
import '../../models/message.dart';
import '../../widgets/call_service.dart';
import '../../widgets/message_card.dart';
import '../../widgets/profile_image.dart';
import '../../widgets/video_call_screen.dart';
import 'view_profile_screen.dart';
import 'package:provider/provider.dart';
import '../../theme/theme_provider.dart';
import '../../theme/theme.dart';

class ChatScreen extends StatefulWidget {
  final AppUser user;

  const ChatScreen({super.key, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  //for storing all messages
  List<Message> _list = [];

  //for handling message text changes
  final _textController = TextEditingController();
  final String sharedChannelName = 'myRoom123'; // Dùng chung cho cả voice & video call

  //showEmoji -- for storing value of showing or hiding emoji
  //isUploading -- for checking if image is uploading or not?
  bool _showEmoji = false, _isUploading = false;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return GestureDetector(
      onTap: FocusScope.of(context).unfocus,
      child: PopScope(
        // onWillPop: () {
        //   if (_showEmoji) {
        //     setState(() => _showEmoji = !_showEmoji);
        //     return Future.value(false);
        //   } else {
        //     return Future.value(true);
        //   }
        // },

        //if emojis are shown & back button is pressed then hide emojis
        //or else simple close current screen on back button click
        canPop: false,

        onPopInvokedWithResult: (_, __) {
          if (_showEmoji) {
            setState(() => _showEmoji = !_showEmoji);
            return;
          }

          // some delay before pop
          // Future.delayed(const Duration(milliseconds: 300), () {
          //   try {
          //     if (Navigator.canPop(context)) Navigator.pop(context);
          //   } catch (e) {
          //     dev.log('ErrorPop: $e');
          //   }
          // });
        },

        //
        child: Scaffold(
          //app bar
          appBar: AppBar(
            backgroundColor: AppBackgroundStyles.mainBackground(isDarkMode),
            automaticallyImplyLeading: false,
            flexibleSpace: _appBar(),
          ),

          // backgroundColor: const Color.fromARGB(255, 234, 248, 255),
          backgroundColor: AppBackgroundStyles.mainBackground(isDarkMode),

          //body
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: StreamBuilder(
                    stream: APIs.getAllMessages(widget.user),
                    builder: (context, snapshot) {
                      switch (snapshot.connectionState) {
                        //if data is loading
                        case ConnectionState.waiting:
                        case ConnectionState.none:
                          return const SizedBox();

                        //if some or all data is loaded then show it
                        case ConnectionState.active:
                        case ConnectionState.done:
                          final data = snapshot.data?.docs;
                          final messageList = data?.map((e) => Message.fromJson(e.data())).toList() ?? [];

                          if (messageList.isNotEmpty) {
                            return ListView.builder(
                              reverse: false,
                              itemCount: messageList.length,
                              padding: EdgeInsets.only(top: mq.height * .01),
                              physics: const BouncingScrollPhysics(),
                              itemBuilder: (context, index) {
                                final message = messageList[index];
                                return MessageCard(
                                  message: message,
                                  index: index,
                                  messageList: messageList,
                                  senderName: message.fromId == APIs.user.uid 
                                      ? null 
                                      : widget.user.name,
                                  senderAvatarUrl: message.fromId == APIs.user.uid 
                                      ? null 
                                      : widget.user.avatarUrl,
                                );
                              },
                            );
                          } else {
                            return const Center(
                              child: Text('Hãy gửi lời chào! 👋',
                                  style: TextStyle(fontSize: 20)),
                            );
                          }
                      }
                    },
                  ),
                ),

                //progress indicator for showing uploading
                if (_isUploading)
                  const Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                          padding:
                              EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                          child: CircularProgressIndicator(strokeWidth: 2))),

                //chat input filed
                _chatInput(),

                //show emojis on keyboard emoji button click & vice versa
                if (_showEmoji)
                  SizedBox(
                    height: mq.height * .35,
                    child: EmojiPicker(
                      textEditingController: _textController,
                      config: const Config(),
                    ),
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }

  // app bar widget
  Widget _appBar() {
  return SafeArea(
    child: InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ViewProfileScreen(user: widget.user),
          ),
        );
      },
      child: StreamBuilder(
        stream: APIs.getUserInfo(widget.user),
        builder: (context, snapshot) {
          final data = snapshot.data?.docs;
          final list = data?.map((e) => AppUser.fromJson(e.data())).toList() ?? [];

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left side: back + avatar + name + last seen
              Row(
                children: [
                  // Back button
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.black54),
                  ),

                  // Profile image
                  ProfileImage(
                    size: mq.height * .05,
                    url: list.isNotEmpty ? list[0].avatarUrl : widget.user.avatarUrl,
                  ),

                  const SizedBox(width: 10),

                  // Name + last active
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        list.isNotEmpty ? list[0].name : widget.user.name,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        list.isNotEmpty
                            ? list[0].isOnline
                                ? 'Đang hoạt động'
                                : MyDateUtil.getLastActiveTime(
                                    context: context,
                                    lastActive: list[0].lastActive)
                            : MyDateUtil.getLastActiveTime(
                                context: context,
                                lastActive: widget.user.lastActive),
                        style: const TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                    ],
                  ),
                ],
              ),

              // Right side: call + video call
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.call, color: Colors.blueAccent),
                    onPressed: () async {
                      await CallService.initialize();

                      final voiceUid = math.Random().nextInt(100000);

                      await CallService.startVoiceCall(sharedChannelName, voiceUid);

                      // Hiện thông báo hoặc điều hướng sang màn hình voice UI (nếu có)
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Voice call started on channel: $sharedChannelName")),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.videocam, color: Colors.blueAccent),
                    onPressed: () async {
                      await CallService.initialize();

                      final uid = math.Random().nextInt(100000);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VideoCallScreen(
                            channelName: sharedChannelName,
                            uid: uid,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              )
            ],
          );
        },
      ),
    ),
  );
}


  // bottom chat input field
  Widget _chatInput() {
    return Padding(
      padding: EdgeInsets.symmetric(
          vertical: mq.height * .01, horizontal: mq.width * .025),
      child: Row(
        children: [
          //input field & buttons
          Expanded(
            child: Card(
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(15))),
              child: Row(
                children: [
                  //emoji button
                  IconButton(
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        setState(() => _showEmoji = !_showEmoji);
                      },
                      icon: const Icon(Icons.emoji_emotions,
                          color: Colors.blueAccent, size: 25)),

                  Expanded(
                      child: TextField(
                    controller: _textController,
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                    onTap: () {
                      if (_showEmoji) setState(() => _showEmoji = !_showEmoji);
                    },
                    decoration: const InputDecoration(
                        hintText: 'Nhắn tin',
                        hintStyle: TextStyle(color: Colors.blueAccent),
                        border: InputBorder.none),
                  )),

                  //pick image from gallery button
                  IconButton(
                      onPressed: () async {
                        final ImagePicker picker = ImagePicker();

                        // Picking multiple images
                        final List<XFile> images =
                            await picker.pickMultiImage(imageQuality: 70);

                        // uploading & sending image one by one
                        for (var i in images) {
                          dev.log('Image Path: ${i.path}');
                          setState(() => _isUploading = true);
                          await APIs.sendChatImage(widget.user, File(i.path));
                          setState(() => _isUploading = false);
                        }
                      },
                      icon: const Icon(Icons.image,
                          color: Colors.blueAccent, size: 26)),

                  //take image from camera button
                  IconButton(
                      onPressed: () async {
                        final ImagePicker picker = ImagePicker();

                        // Pick an image
                        final XFile? image = await picker.pickImage(
                            source: ImageSource.camera, imageQuality: 70);
                        if (image != null) {
                          dev.log('Image Path: ${image.path}');
                          setState(() => _isUploading = true);

                          await APIs.sendChatImage(
                              widget.user, File(image.path));
                          setState(() => _isUploading = false);
                        }
                      },
                      icon: const Icon(Icons.camera_alt_rounded,
                          color: Colors.blueAccent, size: 26)),

                  //adding some space
                  SizedBox(width: mq.width * .02),
                ],
              ),
            ),
          ),

          //send message button
          MaterialButton(
            onPressed: () {
              if (_textController.text.isNotEmpty) {
                if (_list.isEmpty) {
                  //on first message (add user to my_user collection of chat user)
                  APIs.sendFirstMessage(
                      widget.user, _textController.text, MessageType.text);
                } else {
                  //simply send message
                  APIs.sendMessage(
                      widget.user, _textController.text, MessageType.text);
                }
                _textController.text = '';
              }
            },
            minWidth: 0,
            padding:
                const EdgeInsets.only(top: 10, bottom: 10, right: 5, left: 10),
            shape: const CircleBorder(),
            color: Color(0xFF2E7D32),
            child: const Icon(Icons.send, color: Colors.white, size: 28),
          )
        ],
      ),
    );
  }
}