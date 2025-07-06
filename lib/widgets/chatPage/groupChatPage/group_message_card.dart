import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:get/get.dart';
import 'package:learnity/models/group_message.dart';
import 'package:learnity/widgets/common/custom_snackbar.dart';
import 'package:learnity/widgets/common/text_field_modal.dart';

import '../../../api/group_chat_api.dart';
import '../../../api/user_apis.dart';
import '../../../enum/message_type.dart';
import '../../common/dialogs.dart';
import '../../common/my_date_util.dart';
import '../../../main.dart';
import '../../../models/message.dart';

import 'package:provider/provider.dart';
import 'package:learnity/theme/theme.dart';
import 'package:learnity/theme/theme_provider.dart';

// for showing single message details
class GroupMessageCard extends StatefulWidget {
  final GroupMessage message;
  final int index;
  final List<GroupMessage> messageList;
  final String? senderName;
  final String? senderAvatarUrl;

  const GroupMessageCard({
    super.key,
    required this.message,
    required this.index,
    required this.messageList,
    this.senderName,
    this.senderAvatarUrl,
  });

  @override
  State<GroupMessageCard> createState() => _GroupMessageCardState();
}

class _GroupMessageCardState extends State<GroupMessageCard> {
  late bool isMe;
  late DateTime currentTime;
  late bool showDateHeader;
  late bool isFirstOfGroup;
  late bool isLastOfGroup;

  @override
  void initState() {
    super.initState();
    _calculateMessageAttributes();
  }

  void _calculateMessageAttributes() {
    isMe = GroupChatApi.user.uid == widget.message.fromUserId;
    currentTime = DateTime.fromMillisecondsSinceEpoch(int.parse(widget.message.sent));

    // Kiểm tra xem có phải là tin nhắn đầu tiên trong ngày không
    showDateHeader = widget.index == 0 || 
        !MyDateUtil.isSameDay(
          currentTime, 
          DateTime.fromMillisecondsSinceEpoch(int.parse(widget.messageList[widget.index - 1].sent))
        );

    // Kiểm tra xem có phải là tin nhắn đầu tiên của người gửi trong ngày không
    isFirstOfGroup = !isMe && (widget.index == 0 || 
        widget.message.fromUserId != widget.messageList[widget.index - 1].fromUserId || 
        !MyDateUtil.isSameDay(
          currentTime, 
          DateTime.fromMillisecondsSinceEpoch(int.parse(widget.messageList[widget.index - 1].sent))
        ) ||
        widget.messageList[widget.index - 1].type == MessageType.notify
        );

    // Kiểm tra xem có phải là tin nhắn cuối cùng trong chuỗi liên tiếp không
    isLastOfGroup = widget.index == widget.messageList.length - 1 ||
        widget.message.fromUserId != widget.messageList[widget.index + 1].fromUserId ||
        !MyDateUtil.isSameDay(
          currentTime, 
          DateTime.fromMillisecondsSinceEpoch(int.parse(widget.messageList[widget.index + 1].sent))
        ) ||
        widget.messageList[widget.index + 1].type == MessageType.notify;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Column(
      children: [
        // Date header (chỉ hiện ở tin nhắn đầu tiên trong ngày)
        if (showDateHeader)
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                MyDateUtil.getFormattedDateTimeWithDateTime(currentTime),
                style: TextStyle(
                  fontSize: 12,
                  color: AppTextStyles.subTextColor(isDarkMode),
                ),
              ),
            ),
          ),

        // Nếu là notify message
        widget.message.type == MessageType.notify
            ? Container(
                width: mq.width,
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: AppTextStyles.subTextColor(isDarkMode),
                  ),
                  child: Text(
                    widget.message.msg,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
            : Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: mq.width * .04,
                  vertical: mq.height * .002,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Avatar (chỉ hiện với tin cuối của chuỗi từ người khác)
                    if (!isMe)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: isLastOfGroup
                            ? CircleAvatar(
                                radius: 16,
                                backgroundImage: widget.senderAvatarUrl != null
                                    ? CachedNetworkImageProvider(widget.senderAvatarUrl!)
                                    : null,
                                child: widget.senderAvatarUrl == null
                                    ? const Icon(Icons.person, size: 16)
                                    : null,
                              )
                            : const SizedBox(width: 32), // căn avatar giả
                      ),

                    // Nội dung tin nhắn + tên + thời gian
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          // Tên người gửi (chỉ hiện ở đầu chuỗi liên tiếp)
                          if (isFirstOfGroup && widget.senderName != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 10.0, bottom: 4),
                              child: Text(
                                widget.senderName!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTextStyles.normalTextColor(isDarkMode),
                                ),
                              ),
                            ),

                          // Nội dung tin nhắn
                          InkWell(
                            onLongPress: () => _showBottomSheet(isDarkMode, isMe),
                            child: isMe
                                ? _currentUserMessage()
                                : _otherUserMessage(),
                          ),

                          // Thời gian (chỉ hiển thị ở cuối chuỗi)
                          if (isLastOfGroup)
                            Padding(
                              padding: EdgeInsets.only(
                                left: isMe ? 0 : 2,
                                right: isMe ? 2 : 0,
                                top: 2,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: isMe
                                    ? MainAxisAlignment.end
                                    : MainAxisAlignment.start,
                                children: [
                                  Text(
                                    MyDateUtil.getFormattedTimeWithDateTime(currentTime),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppTextStyles.subTextColor(isDarkMode),
                                    ),
                                  ),
                                  if (isMe && widget.message.read.isNotEmpty)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 4),
                                      child: Icon(
                                        Icons.done_all_rounded,
                                        color: Colors.blue,
                                        size: 14,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ],
    );
  }


  // Tin nhắn người khác
  Widget _otherUserMessage() {
    // Cập nhật trạng thái đọc nếu cần
    // if (widget.message.read.isEmpty) {
    //   GroupChatApi.updateMessageReadStatus(widget.message);
    // }

    return Container(
      constraints: BoxConstraints(maxWidth: mq.width * 0.7),
      padding: EdgeInsets.all(widget.message.type == MessageType.image
          ? mq.width * .03
          : mq.width * .04),
      decoration: BoxDecoration(
        color: const Color(0xFF455A64),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(12),
          topRight: const Radius.circular(12),
          bottomLeft: isLastOfGroup 
            ? const Radius.circular(4) 
            : const Radius.circular(12),
          bottomRight: const Radius.circular(12),
        ),
      ),
      child: widget.message.type == MessageType.text
          ? Text(
              widget.message.msg,
              style: const TextStyle(fontSize: 15, color: Colors.white),
            )
          : ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              child: CachedNetworkImage(
                imageUrl: widget.message.msg,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                errorWidget: (context, url, error) =>
                    const Icon(Icons.image, size: 70),
              ),
            ),
    );
  }

  // Tin nhắn của người dùng hiện tại
  Widget _currentUserMessage() {
    return Container(
      constraints: BoxConstraints(maxWidth: mq.width * 0.7),
      padding: EdgeInsets.all(widget.message.type == MessageType.image
          ? mq.width * .03
          : mq.width * .04),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(12),
          topRight: const Radius.circular(12),
          bottomLeft: const Radius.circular(12),
          bottomRight: isLastOfGroup 
            ? const Radius.circular(4) 
            : const Radius.circular(12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // if (widget.message.read.isNotEmpty)
          //   const Padding(
          //     padding: EdgeInsets.only(right: 4),
          //     child: Icon(Icons.done_all_rounded, 
          //       color: Colors.blue, 
          //       size: 16),
          //   ),
          Flexible(
            child: widget.message.type == MessageType.text
                ? Text(
                    widget.message.msg,
                    style: const TextStyle(fontSize: 15, color: Colors.white),
                  )
                : ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    child: CachedNetworkImage(
                      imageUrl: widget.message.msg,
                      placeholder: (context, url) => const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.image, size: 70),
                    ),
                  ),
          ),
        ],
      ),
    );
  }


  // bottom sheet for modifying message details
  void _showBottomSheet(bool isDarkMode,bool isMe) {
    showModalBottomSheet(
        context: context,
        backgroundColor: AppBackgroundStyles.modalBackground(isDarkMode),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20), topRight: Radius.circular(20))),
        builder: (_) {
          return ListView(
            shrinkWrap: true,
            children: [
              //black divider
              Container(
                height: 4,
                margin: EdgeInsets.symmetric(
                    vertical: mq.height * .015, horizontal: mq.width * .4),
                decoration: BoxDecoration(
                    color: AppTextStyles.normalTextColor(isDarkMode),
                    borderRadius: BorderRadius.all(Radius.circular(8))),
              ),

              widget.message.type == MessageType.text
                  ?
                  //copy option
                  _OptionItem(
                      icon: Icon(Icons.copy_all_rounded,
                          color: AppIconStyles.iconPrimary(isDarkMode), size: 26),
                      name: 'Sao chép tin nhắn',
                      onTap: (ctx) async {
                        await Clipboard.setData(
                                ClipboardData(text: widget.message.msg))
                            .then((value) {
                          if (ctx.mounted) {
                            //for hiding bottom sheet
                            Navigator.pop(ctx);

                            CustomSnackbar.show(
                              title: "Thành công",
                              message: "Đã sao chép tin nhắn!",
                            );
                          }
                        });
                      })
                  :
                  //save option
                  _OptionItem(
                      icon: Icon(Icons.download_rounded,
                          color: AppIconStyles.iconPrimary(isDarkMode), size: 26),
                      name: 'Lưu hình ảnh',
                      onTap: (ctx) async {
                        try {
                          log('Image Url: ${widget.message.msg}');
                          await GallerySaver.saveImage(widget.message.msg,
                                  albumName: 'We Chat')
                              .then((success) {
                            if (ctx.mounted) {
                              //for hiding bottom sheet
                              Navigator.pop(ctx);
                              if (success != null && success) {
                                Dialogs.showSnackbar(
                                    ctx, 'Đã lưu hình ảnh thành công!');
                              }
                            }
                          });
                        } catch (e) {
                          log('ErrorWhileSavingImg: $e');
                        }
                      }),

              //separator or divider
              if (isMe)
                Divider(
                  color: AppTextStyles.normalTextColor(isDarkMode).withOpacity(0.2),
                  endIndent: mq.width * .04,
                  indent: mq.width * .04,
                ),

              //edit option
              if (widget.message.type == MessageType.text && isMe)
                _OptionItem(
                    icon: Icon(Icons.edit, color: AppIconStyles.iconPrimary(isDarkMode), size: 26),
                    name: 'Chỉnh sửa tin nhắn',
                    onTap: (ctx) {
                      if (ctx.mounted) {
                        _showMessageUpdateDialog(isDarkMode, ctx);

                        //for hiding bottom sheet
                        // Navigator.pop(ctx);
                      }
                    }),

              //delete option
              if (isMe)
                _OptionItem(
                    icon: Icon(Icons.delete_forever,
                        color: AppIconStyles.iconPrimary(isDarkMode), size: 26),
                    name: 'Xóa tin nhắn',
                    onTap: (ctx) async {
                      await GroupChatApi.deleteMessage(widget.message).then((value) {
                        //for hiding bottom sheet
                        if (ctx.mounted) Navigator.pop(ctx);
                      });
                    }),

              //separator or divider
              // Divider(
              //   color: Colors.black54,
              //   endIndent: mq.width * .04,
              //   indent: mq.width * .04,
              // ),

              // //sent time
              // _OptionItem(
              //     icon: const Icon(Icons.remove_red_eye, color: Colors.blue),
              //     name:
              //         'Gửi lúc: ${MyDateUtil.getMessageTime(time: widget.message.sent)}',
              //     onTap: (_) {}),

              // //read time
              // _OptionItem(
              //     icon: const Icon(Icons.remove_red_eye, color: Colors.green),
              //     name: widget.message.read.isEmpty
              //         ? 'Người dùng chưa đọc'
              //         : 'Đọc lúc: ${MyDateUtil.getMessageTime(time: widget.message.read)}',
              //     onTap: (_) {}),
            ],
          );
        });
  }

  //dialog for updating message content
  void _showMessageUpdateDialog(bool isDarkMode, BuildContext ctx) {
    showTextFieldModal(
      context: ctx,
      isDarkMode: isDarkMode,
      title: 'Chỉnh sửa tin nhắn',
      hintText: 'Nhập tin nhắn mới',
      confirmText: 'Chỉnh sửa',
      initialText: widget.message.msg,
      onConfirm: (updatedMsg) async {
        if (updatedMsg.trim().isEmpty || updatedMsg == widget.message.msg) return;

        await GroupChatApi.updateMessage(widget.message, updatedMsg.trim());

        if (ctx.mounted) {
          // đóng bottom sheet nếu có
          Navigator.pop(ctx);
        }
      },
    );
  }
}

//custom options card (for copy, edit, delete, etc.)
class _OptionItem extends StatelessWidget {
  final Icon icon;
  final String name;
  final Function(BuildContext) onTap;

  const _OptionItem(
      {required this.icon, required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return InkWell(
        onTap: () => onTap(context),
        child: Padding(
          padding: EdgeInsets.only(
              left: mq.width * .05,
              top: mq.height * .015,
              bottom: mq.height * .015),
          child: Row(children: [
            icon,
            Flexible(
                child: Text('    $name',
                    style: TextStyle(
                        fontSize: 15,
                        color: AppTextStyles.normalTextColor(isDarkMode),
                        letterSpacing: 0.5)))
          ]),
        ));
  }
}