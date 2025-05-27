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
        "sendBy": _auth.currentUser!.displayName,
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
                    return messageTile(size, chatMap);
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


  Widget messageTile(Size size, Map<String, dynamic> chatMap) {
    return Builder(builder: (_) {
      if (chatMap['type'] == "text") {
        return Container(
          width: size.width,
          alignment: chatMap['sendBy'] == _auth.currentUser!.displayName
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: Container(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 14),
              margin: EdgeInsets.symmetric(vertical: 5, horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: Colors.blue,
              ),
              child: Column(
                children: [
                  Text(
                    chatMap['sendBy'],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(
                    height: size.height / 200,
                  ),
                  Text(
                    chatMap['message'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              )),
        );
      } else if (chatMap['type'] == "img") {
        return Container(
          width: size.width,
          alignment: chatMap['sendBy'] == _auth.currentUser!.displayName
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            margin: EdgeInsets.symmetric(vertical: 5, horizontal: 8),
            height: size.height / 2,
            child: Image.network(
              chatMap['message'],
            ),
          ),
        );
      } else if (chatMap['type'] == "notify") {
        return Container(
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
        );
      } else {
        return SizedBox();
      }
    });
  }
}