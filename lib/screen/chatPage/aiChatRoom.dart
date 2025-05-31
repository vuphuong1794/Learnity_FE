import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';
import 'package:learnity/screen/chatPage/message.dart';

class AichatRoom extends StatefulWidget {
  const AichatRoom({super.key});

  @override
  State<AichatRoom> createState() => _AichatroomState();
}

class _AichatroomState extends State<AichatRoom> {
  TextEditingController _userInput = TextEditingController();
  final apiKey = 'AIzaSyA-SpsGatav9rV5DVhJFO6b8mJ-x-nBH2A';

  final List<Message> _messages = [];

  Future<void> talkWithGemini() async {
    final userMsg = _userInput.text.trim();

    setState(() {
      _messages.add(
        Message(
          isUser: true,
          message: userMsg,
          date: DateTime.now().toString(),
        ),
      );
      _userInput.clear();
    });
    final model = GenerativeModel(model: 'gemini-2.0-flash', apiKey: apiKey);

    final content = Content.text(userMsg);
    final response = await model.generateContent([content]);

    setState(() {
      _messages.add(
        Message(
          isUser: false,
          message: response.text ?? "",
          date: DateTime.now().toString(),
        ),
      );
    });

    //print('Response from Gemini: ${response.text}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return Messages(
                    isUser: message.isUser,
                    message: message.message,
                    date: DateFormat(
                      'HH:mm',
                    ).format(DateTime.parse(message.date)),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 15,
                    child: TextFormField(
                      style: TextStyle(color: Colors.black),
                      controller: _userInput,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        label: Text("Nhập câu hỏi của bạn"),
                      ),
                    ),
                  ),

                  SizedBox(width: 16),
                  IconButton(
                    padding: EdgeInsets.all(12),
                    iconSize: 30,
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(
                        Colors.blueAccent,
                      ),
                      foregroundColor: MaterialStateProperty.all(Colors.white),
                      shape: MaterialStateProperty.all(CircleBorder()),
                    ),
                    onPressed: () {
                      talkWithGemini();
                    },
                    icon: Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
