import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';

import '../../../api/user_apis.dart';
import '../../../enum/message_type.dart';
import '../../common/dialogs.dart';
import '../../common/my_date_util.dart';
import '../../../main.dart';
import '../../../models/message.dart';
import 'package:learnity/widgets/common/option_modal_item.dart';

import 'package:provider/provider.dart';
import 'package:learnity/theme/theme.dart';
import 'package:learnity/theme/theme_provider.dart';

// for showing single message details
class MessageCard extends StatefulWidget {
  final Message message;
  final int index;
  final List<Message> messageList;
  final String? senderName;
  final String? senderAvatarUrl;

  const MessageCard({
    super.key,
    required this.message,
    required this.index,
    required this.messageList,
    this.senderName,
    this.senderAvatarUrl,
  });

  @override
  State<MessageCard> createState() => _MessageCardState();
}

class _MessageCardState extends State<MessageCard> {
  late bool isMe;
  late DateTime currentTime;
  late bool showDateHeader;
  late bool showUsername;
  late bool showAvatarAndTime;

  @override
  void initState() {
    super.initState();
    _calculateMessageAttributes();
  }

  void _calculateMessageAttributes() {
    isMe = APIs.user.uid == widget.message.fromId;
    currentTime = DateTime.fromMillisecondsSinceEpoch(int.parse(widget.message.sent));

    // Kiểm tra xem có phải là tin nhắn đầu tiên trong ngày không
    showDateHeader = widget.index == 0 || 
        !MyDateUtil.isSameDay(
          currentTime, 
          DateTime.fromMillisecondsSinceEpoch(int.parse(widget.messageList[widget.index - 1].sent))
        );

    // Kiểm tra xem có phải là tin nhắn đầu tiên của người gửi trong ngày không
    showUsername = !isMe && (widget.index == 0 || 
        widget.message.fromId != widget.messageList[widget.index - 1].fromId || 
        !MyDateUtil.isSameDay(
          currentTime, 
          DateTime.fromMillisecondsSinceEpoch(int.parse(widget.messageList[widget.index - 1].sent))
        ));

    // Kiểm tra xem có phải là tin nhắn cuối cùng trong chuỗi liên tiếp không
    showAvatarAndTime = widget.index == widget.messageList.length - 1 ||
        widget.message.fromId != widget.messageList[widget.index + 1].fromId ||
        !MyDateUtil.isSameDay(
          currentTime, 
          DateTime.fromMillisecondsSinceEpoch(int.parse(widget.messageList[widget.index + 1].sent))
        );
  }

  String _getFormattedDate() {
    return "${currentTime.hour.toString().padLeft(2, '0')}:${currentTime.minute.toString().padLeft(2, '0')} ${currentTime.day.toString().padLeft(2, '0')}/${currentTime.month.toString().padLeft(2, '0')}/${currentTime.year}";
  }

  String _getFormattedTime() {
    return "${currentTime.hour.toString().padLeft(2, '0')}:${currentTime.minute.toString().padLeft(2, '0')}";
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
              // decoration: BoxDecoration(
              //   color: Colors.grey[300],
              //   borderRadius: BorderRadius.circular(12),
              // ),
              child: Text(
                _getFormattedDate(),
                style: TextStyle(
                  fontSize: 12,
                  color: AppTextStyles.subTextColor(isDarkMode),
                ),
              ),
            ),
          ),
        
        // Nội dung tin nhắn
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: mq.width * .04,
            vertical: mq.height * .002,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Avatar (chỉ hiện với tin nhắn cuối cùng trong chuỗi liên tiếp của người khác)
              if (!isMe)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: showAvatarAndTime
                      ? CircleAvatar(
                          radius: 16,
                          backgroundImage: widget.senderAvatarUrl != null
                              ? CachedNetworkImageProvider(widget.senderAvatarUrl!)
                              : null,
                          child: widget.senderAvatarUrl == null
                              ? const Icon(Icons.person, size: 16)
                              : null,
                        )
                      : const SizedBox(width: 32), // 👈 Thụt lề để căn hàng
                ),

              
              // Expanded để chiếm phần còn lại
              Expanded(
                child: Column(
                  crossAxisAlignment: 
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    // Tên người gửi (chỉ hiện với tin nhắn đầu tiên trong chuỗi liên tiếp của người khác)
                    if (showUsername && widget.senderName != null)
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
                    
                    // Thời gian (chỉ hiện với tin nhắn cuối cùng trong chuỗi liên tiếp)
                    if (showAvatarAndTime)
                      Padding(
                        padding: EdgeInsets.only(
                          left: isMe ? 0 : 2,
                          right: isMe ? 2 : 0,
                          top: 2,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                          children: [
                            Text(
                              _getFormattedTime(),
                              style: TextStyle(
                                fontSize: 10,
                                color: AppTextStyles.subTextColor(isDarkMode),
                              ),
                            ),
                            if (isMe && widget.message.read.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Icon(
                                  Icons.done_all_rounded,
                                  color: AppIconStyles.iconPrimary(isDarkMode),
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
    if (widget.message.read.isEmpty) {
      APIs.updateMessageReadStatus(widget.message);
    }

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
          bottomLeft: showAvatarAndTime 
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
          bottomRight: showAvatarAndTime 
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
  void _showBottomSheet(bool isDarkMode, bool isMe) {
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
                  OptionItem(
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

                            Dialogs.showSnackbar(ctx, 'Đã sao chép tin nhắn!');
                          }
                        });
                      })
                  :
                  //save option
                  OptionItem(
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
                OptionItem(
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
                OptionItem(
                    icon: Icon(Icons.delete_forever,
                        color: AppIconStyles.iconPrimary(isDarkMode), size: 26),
                    name: 'Xóa tin nhắn',
                    onTap: (ctx) async {
                      await APIs.deleteMessage(widget.message).then((value) {
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
              // OptionItem(
              //     icon: const Icon(Icons.remove_red_eye, color: Colors.blue),
              //     name:
              //         'Gửi lúc: ${MyDateUtil.getMessageTime(time: widget.message.sent)}',
              //     onTap: (_) {}),

              // //read time
              // OptionItem(
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
  void _showMessageUpdateDialog(bool isDarkMode, final BuildContext ctx) {
    String updatedMsg = widget.message.msg;

    showDialog(
        context: ctx,
        builder: (_) => AlertDialog(
            backgroundColor: AppBackgroundStyles.modalBackground(isDarkMode),
              contentPadding: const EdgeInsets.only(
                  left: 24, right: 24, top: 20, bottom: 10),

              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20))),

              //title
              title: Row(
                children: [
                  Icon(
                    Icons.message,
                    color: AppIconStyles.iconPrimary(isDarkMode),
                    size: 28,
                  ),
                  Text(' Chỉnh sửa tin nhắn', style: TextStyle(color: AppTextStyles.normalTextColor(isDarkMode)))
                ],
              ),

              //content
              content: TextFormField(
                style: TextStyle(color: AppTextStyles.normalTextColor(isDarkMode)),
                initialValue: updatedMsg,
                maxLines: null,
                onChanged: (value) => updatedMsg = value,
                decoration: InputDecoration(
                  hintText: 'Nhập tin nhắn',
                  hintStyle: TextStyle(
                    color: AppTextStyles.normalTextColor(isDarkMode).withOpacity(0.5),
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(15)))),
              ),

              //actions
              actions: [
                //cancel button
                MaterialButton(
                    onPressed: () {
                      //hide alert dialog
                      Navigator.pop(ctx);
                    },
                    child: Text(
                      'Hủy',
                      style: TextStyle(color: AppTextStyles.subTextColor(isDarkMode), fontSize: 16),
                    )),
                    
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor:
                    AppBackgroundStyles.buttonBackground(
                        isDarkMode),
                    foregroundColor:
                    AppTextStyles.buttonTextColor(isDarkMode),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () {
                      APIs.updateMessage(widget.message, updatedMsg);
                      //hide alert dialog
                      Navigator.pop(ctx);

                      //for hiding bottom sheet
                      Navigator.pop(ctx);
                    },
                  child: const Text('Chỉnh sửa'),
                ),
              ],
            ));
  }
}

//custom options card (for copy, edit, delete, etc.)