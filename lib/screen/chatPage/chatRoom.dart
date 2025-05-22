import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';
import '../../theme/theme_provider.dart';
import '../../theme/theme.dart';

class ChatRoom extends StatelessWidget {
  final Map<String, dynamic> userMap;
  final String chatRoomId;

  ChatRoom({required this.chatRoomId, required this.userMap});

  final TextEditingController _message = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isMessageNotEmpty = false;

  File? imageFile;

  Future getImage() async {
    ImagePicker _picker = ImagePicker();

    await _picker.pickImage(source: ImageSource.gallery).then((xFile) {
      if (xFile != null) {
        imageFile = File(xFile.path);
        uploadImage();
      }
    });
  }

  Future uploadImage() async {
    String fileName = Uuid().v1();
    int status = 1;

    await _firestore
        .collection('chatroom')
        .doc(chatRoomId)
        .collection('chats')
        .doc(fileName)
        .set({
      "sendby": _auth.currentUser!.displayName,
      "message": "",
      "type": "img",
      "time": FieldValue.serverTimestamp(),
    });

    var ref =
        FirebaseStorage.instance.ref().child('images').child("$fileName.jpg");

    var uploadTask = await ref.putFile(imageFile!).catchError((error) async {
      await _firestore
          .collection('chatroom')
          .doc(chatRoomId)
          .collection('chats')
          .doc(fileName)
          .delete();

      status = 0;
    });

    if (status == 1) {
      String imageUrl = await uploadTask.ref.getDownloadURL();

      await _firestore
          .collection('chatroom')
          .doc(chatRoomId)
          .collection('chats')
          .doc(fileName)
          .update({"message": imageUrl});

      print(imageUrl);
    }
  }

  void onSendMessage() async {
    if (_message.text.isNotEmpty) {
      Map<String, dynamic> messages = {
        "sendby": _auth.currentUser!.displayName,
        "message": _message.text,
        "type": "text",
        "time": FieldValue.serverTimestamp(),
      };

      _message.clear();
      await _firestore
          .collection('chatroom')
          .doc(chatRoomId)
          .collection('chats')
          .add(messages);
    } else {
      print("Enter Some Text");
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppBackgroundStyles.mainBackground(isDarkMode),
      appBar: AppBar(
        backgroundColor: AppBackgroundStyles.mainBackground(isDarkMode),
        title: StreamBuilder<DocumentSnapshot>(
          stream:
              _firestore.collection("users").doc(userMap['uid']).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.data != null) {
              return Container(
                child: Column(
                  children: [
                    Text(userMap['username']),
                    Text(
                      snapshot.data!['status'] == "Online" ? "Đang hoạt động" : "",
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              );
            } else {
              return Container();
            }
          },
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(color: AppColors.black, height: 1.0),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: size.height / 1.24,
              width: size.width,
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('chatroom')
                    .doc(chatRoomId)
                    .collection('chats')
                    .orderBy("time", descending: false)
                    .snapshots(),
                builder: (BuildContext context,
                    AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.data != null) {
                    return ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        Map<String, dynamic> map = snapshot.data!.docs[index]
                            .data() as Map<String, dynamic>;
                        return messages(size, map, context, index, snapshot.data!.docs);
                      },
                    );
                  } else {
                    return Container();
                  }
                },
              ),
            ),
            Container(
              color: Color(0xFFB3EBD9), // Nền xanh nhạt
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Container(
                    height: 50,
                    width: 40,
                    // decoration: BoxDecoration(
                    //   shape: BoxShape.circle,
                    //   color: Color(0xFFA3D8C5),
                    // ),
                    child: IconButton(
                      onPressed: getImage,
                      icon: Icon(
                        Icons.image,
                        color: Color(0xFF2E7D32), // Đặt màu tại đây
                        size: 30,                  // Kích thước icon
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Color(0xFFA3D8C5), // Màu nền khung nhập
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _message,
                              decoration: InputDecoration(
                                hintText: 'Nhắn tin',
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          // IconButton(
                          //   onPressed: () => getImage(),
                          //   icon: Icon(
                          //     Icons.image,
                          //     color: Color(0xFF2E7D32), // Đặt màu tại đây
                          //     size: 30,                  // Kích thước icon
                          //   ),
                          // ),

                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    height: 50,
                    width: 40,
                    // decoration: BoxDecoration(
                    //   shape: BoxShape.circle,
                    //   color: Color(0xFFA3D8C5),
                    // ),
                    child: IconButton(
                      onPressed: onSendMessage,
                      icon: Icon(
                        Icons.send,
                        color: Color(0xFF2E7D32), // Đặt màu tại đây
                        size: 30,                  // Kích thước icon
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget messages(
    Size size,
    Map<String, dynamic> map,
    BuildContext context,
    int index,
    List<QueryDocumentSnapshot> messageList,
  ) {
    final String? sendBy = map['sendby'];
    final String? currentUser = _auth.currentUser?.displayName;
    final bool isMe = sendBy != null && currentUser != null && sendBy == currentUser;

    // ==== HANDLE TIME ====
    final Timestamp? timeStamp = map['time'] as Timestamp?;
    final DateTime currentTime = timeStamp?.toDate() ?? DateTime.now();

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

      if (prevMap['sendby'] == map['sendby'] && isSameDay(currentTime, prevTime)) {
        isFirstOfGroup = false;
      }
    }

    if (index < messageList.length - 1) {
      final nextMap = messageList[index + 1].data() as Map<String, dynamic>;
      final Timestamp? nextTimeStamp = nextMap['time'] as Timestamp?;
      final DateTime nextTime = nextTimeStamp?.toDate() ?? DateTime.now();

      if (nextMap['sendby'] == map['sendby'] && isSameDay(currentTime, nextTime)) {
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
                        backgroundImage: map['avatarUrl'] != null
                            ? NetworkImage(map['avatarUrl'])
                            : null,
                        backgroundColor: Colors.black87,
                        child: map['avatarUrl'] == null
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
                              map['sendby'] ?? "Unknown",
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ),
                        map['type'] == "text"
                            ? Container(
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  color: isMe ? const Color(0xFF2E7D32) : const Color(0xFF455A64),
                                ),
                                child: Text(
                                  map['message'] ?? '',
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
                                    builder: (_) => ShowImage(imageUrl: map['message']),
                                  ),
                                ),
                                child: Container(
                                  height: size.height / 2.5,
                                  width: size.width / 2,
                                  decoration: BoxDecoration(border: Border.all()),
                                  alignment:
                                      map['message'] != "" ? null : Alignment.center,
                                  child: map['message'] != ""
                                      ? Image.network(
                                          map['message'],
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
  }


  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

}

String formatDateGroup(DateTime time) {
  return "${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')}/${time.year}";
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
