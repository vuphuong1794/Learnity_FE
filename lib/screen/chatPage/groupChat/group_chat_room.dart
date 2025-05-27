// import 'package:chat_app/group_chats/group_info.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/theme.dart';
import 'group_info.dart';

class GroupChatRoom extends StatelessWidget {
  final String groupChatId, groupName;

  GroupChatRoom({required this.groupName, required this.groupChatId, Key? key})
      : super(key: key);

  final TextEditingController _message = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void onSendMessage() async {
    if (_message.text.isNotEmpty) {
      Map<String, dynamic> chatData = {
        "sendby": _auth.currentUser!.displayName,
        "message": _message.text,
        "type": "text",
        "time": FieldValue.serverTimestamp(),
      };

      _message.clear();

      await _firestore
          .collection('groups')
          .doc(groupChatId)
          .collection('chats')
          .add(chatData);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppBackgroundStyles.mainBackground(isDarkMode),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: Stack(
          children: [
            // Nút quay lại
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),

            // Vùng tiêu đề có hiệu ứng bấm
            Positioned.fill(
              left: kToolbarHeight, // chừa vùng nút back (56px mặc định)
              child: Material(
                color: AppBackgroundStyles.mainBackground(isDarkMode),
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => GroupInfo(
                          groupName: groupName,
                          groupId: groupChatId,
                        ),
                      ),
                    );
                  },
                  splashColor: Colors.grey.withOpacity(0.2),
                  highlightColor: Colors.transparent,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            groupName,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('groups')
                  .doc(groupChatId)
                  .collection('chats')
                  .orderBy('time')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                return ListView.builder(
                  padding: EdgeInsets.only(top: 10, bottom: 10),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    Map<String, dynamic> chatMap =
                        snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    return messageTile(size, chatMap, context, index, snapshot.data!.docs);
                  },
                );
              },
            ),
          ),

          // Ô nhập tin nhắn
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            color: const Color(0xFFB3EBD9),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    // TODO: thêm tính năng gửi ảnh
                  },
                  icon: Icon(Icons.image, color: Color(0xFF2E7D32)),
                ),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Color(0xFFA3D8C5),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextField(
                      controller: _message,
                      decoration: InputDecoration(
                        hintText: 'Nhắn tin',
                        border: InputBorder.none,
                      ),
                      onSubmitted: (value) => onSendMessage(),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onSendMessage,
                  icon: Icon(Icons.send, color: Color(0xFF2E7D32)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget messageTile(
    Size size, 
    Map<String, dynamic> chatMap,
    BuildContext context,
    int index,
    List<QueryDocumentSnapshot> messageList,
  ) {
    // ==== HANDLE TIME ====
    final Timestamp? timeStamp = chatMap['time'] as Timestamp?;
    final DateTime currentTime = timeStamp?.toDate() ?? DateTime.now();

    return Builder(builder: (_) {
      if (chatMap['type'] == "text" || chatMap['type'] == "img") {
        final String? sendby = chatMap['sendby'];
    final String? currentUser = _auth.currentUser?.displayName;
    final bool isMe = sendby != null && currentUser != null && sendby == currentUser;

    // // ==== HANDLE TIME ====
    // final Timestamp? timeStamp = chatMap['time'] as Timestamp?;
    // final DateTime currentTime = timeStamp?.toDate() ?? DateTime.now();

    // === LOGIC PHÂN NGÀY ===
    bool showDateHeader = false;
    if (index == 0) {
      showDateHeader = true;
    } else {
      final prevMap = messageList[index - 1].data() as Map<String, dynamic>;
      final Timestamp? prevTimeStamp = prevMap['time'] as Timestamp?;
      final DateTime prevTime = prevTimeStamp?.toDate() ?? DateTime.now();
      if (!isSameDay(currentTime, prevTime)) {
        showDateHeader = true;
      }
    }

    // === LOGIC PHÂN CHUỖI ===
    bool isFirstOfGroup = true;
    bool isLastOfGroup = true;

    if (index > 0) {
      final prevMap = messageList[index - 1].data() as Map<String, dynamic>;
      final Timestamp? prevTimeStamp = prevMap['time'] as Timestamp?;
      final DateTime prevTime = prevTimeStamp?.toDate() ?? DateTime.now();

      if (prevMap['type'] != "notify" && prevMap['sendby'] == chatMap['sendby'] && isSameDay(currentTime, prevTime)) {
        isFirstOfGroup = false;
      }
    }

    if (index < messageList.length - 1) {
      final nextMap = messageList[index + 1].data() as Map<String, dynamic>;
      final Timestamp? nextTimeStamp = nextMap['time'] as Timestamp?;
      final DateTime nextTime = nextTimeStamp?.toDate() ?? DateTime.now();

      if (nextMap['type'] != "notify" && nextMap['sendby'] == chatMap['sendby'] && isSameDay(currentTime, nextTime)) {
        isLastOfGroup = false;
      }
    }

    const double avatarSize = 32.0;
    const double avatarSpacing = 6.0;

    return Column(
      children: [
        if (showDateHeader)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              "${currentTime.hour.toString().padLeft(2, '0')}:${currentTime.minute.toString().padLeft(2, '0')} "
              "${currentTime.day.toString().padLeft(2, '0')}/${currentTime.month.toString().padLeft(2, '0')}/${currentTime.year}",
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey),
            ),
          ),

        Container(
          margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 10),
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: [
                  if (!isMe && isLastOfGroup)
                    Padding(
                      padding: const EdgeInsets.only(right: avatarSpacing),
                      child: CircleAvatar(
                        radius: avatarSize / 2,
                        backgroundImage: chatMap['avatarUrl'] != null
                            ? NetworkImage(chatMap['avatarUrl'])
                            : null,
                        backgroundColor: Colors.black87,
                        child: chatMap['avatarUrl'] == null
                            ? const Icon(Icons.person, size: 18, color: Colors.white)
                            : null,
                      ),
                    )
                  else if (!isMe)
                    SizedBox(width: avatarSize + avatarSpacing),

                  Flexible(
                    child: Column(
                      crossAxisAlignment:
                          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        if (!isMe && isFirstOfGroup)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              chatMap['sendby'] ?? "Unknown",
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ),
                        chatMap['type'] == "text"
                            ? Container(
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  color: isMe ? const Color(0xFF2E7D32) : const Color(0xFF455A64),
                                ),
                                child: Text(
                                  chatMap['message'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : InkWell(
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ShowImage(imageUrl: chatMap['message']),
                                  ),
                                ),
                                child: Container(
                                  height: size.height / 2.5,
                                  width: size.width / 2,
                                  decoration: BoxDecoration(border: Border.all()),
                                  alignment:
                                      chatMap['message'] != "" ? null : Alignment.center,
                                  child: chatMap['message'] != ""
                                      ? Image.network(
                                          chatMap['message'],
                                          fit: BoxFit.cover,
                                        )
                                      : const CircularProgressIndicator(),
                                ),
                              ),
                      ],
                    ),
                  ),
                ],
              ),
              if (isLastOfGroup)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0, left: 8, right: 8),
                  child: Row(
                    mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                    children: [
                      if (!isMe) const SizedBox(width: avatarSize + avatarSpacing),
                      Text(
                        "${currentTime.hour.toString().padLeft(2, '0')}:${currentTime.minute.toString().padLeft(2, '0')}",
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
      } else if (chatMap['type'] == "notify") {
        // === LOGIC PHÂN NGÀY ===
        bool showDateHeader = false;
        if (index == 0) {
          showDateHeader = true;
        } else {
          final prevMap = messageList[index - 1].data() as Map<String, dynamic>;
          final Timestamp? prevTimeStamp = prevMap['time'] as Timestamp?;
          final DateTime prevTime = prevTimeStamp?.toDate() ?? DateTime.now();
          if (!isSameDay(currentTime, prevTime)) {
            showDateHeader = true;
          }
        }
        return Column (
          children: [
            if (showDateHeader)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  "${currentTime.hour.toString().padLeft(2, '0')}:${currentTime.minute.toString().padLeft(2, '0')} "
                  "${currentTime.day.toString().padLeft(2, '0')}/${currentTime.month.toString().padLeft(2, '0')}/${currentTime.year}",
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey),
                ),
              ),

            Container(
              width: size.width,
              alignment: Alignment.center,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                margin: EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: Colors.black38,
                ),
                child: Text(
                  chatMap['message'],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );
      } else {
        return SizedBox();
      }
    });
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String formatDateGroup(DateTime time) {
    return "${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')}/${time.year}";
  }
}

class ShowImage extends StatelessWidget {
  final String imageUrl;

  const ShowImage({required this.imageUrl, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        height: size.height,
        width: size.width,
        color: Colors.black,
        child: Image.network(imageUrl),
      ),
    );
  }
}
