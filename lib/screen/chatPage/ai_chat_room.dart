import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';
import 'package:learnity/screen/chatPage/message.dart';

import 'package:provider/provider.dart';
import 'package:learnity/theme/theme.dart';
import 'package:learnity/theme/theme_provider.dart';

class AichatRoom extends StatefulWidget {
  const AichatRoom({super.key});

  @override
  State<AichatRoom> createState() => _AichatroomState();
}

class _AichatroomState extends State<AichatRoom> {
  final TextEditingController _userInput = TextEditingController();
  final List<Message> _messages = [];
  final apiKey = 'AIzaSyA-SpsGatav9rV5DVhJFO6b8mJ-x-nBH2A';

  final ScrollController _scrollController = ScrollController();

  Future<void> talkWithGemini() async {
    final userMsg = _userInput.text.trim();
    if (userMsg.isEmpty) return;

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
          message: response.text ?? "Không có phản hồi.",
          date: DateTime.now().toString(),
        ),
      );
    });

    await Future.delayed(const Duration(milliseconds: 100));
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 100,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: AppBackgroundStyles.mainBackground(isDarkMode),
      appBar: AppBar(
        title: const Text(
          'Learnity AI',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppBackgroundStyles.secondaryBackground(isDarkMode),
        foregroundColor: AppTextStyles.normalTextColor(isDarkMode),
        elevation: 2,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              // color: Colors.grey[100],
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final isUser = message.isUser;

                  return Align(
                    alignment:
                        isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 8,
                      ),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isUser ? Color(0xFF2E7D32) : Color(0xFF455A64),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(isUser ? 16 : 0),
                          bottomRight: Radius.circular(isUser ? 0 : 16),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message.message,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat(
                              'HH:mm',
                            ).format(DateTime.parse(message.date)),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTextStyles.subTextColor(isDarkMode),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
            child: Row(
              children: [
                // GestureDetector(
                //   onTap: () {},
                //   child: Icon(Icons.image, color: AppIconStyles.iconPrimary(isDarkMode), size: 28,)
                // ),
                // const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    style: TextStyle(
                      color: AppTextStyles.normalTextColor(isDarkMode),
                    ),
                    controller: _userInput,
                    decoration: InputDecoration(
                      hintText: "Nhập câu hỏi...",
                      hintStyle: TextStyle(
                        color: AppTextStyles.normalTextColor(isDarkMode).withOpacity(0.5),
                      ),
                      filled: true,
                      fillColor: AppBackgroundStyles.buttonBackgroundSecondary(isDarkMode),

                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onFieldSubmitted: (_) => talkWithGemini(),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: talkWithGemini,
                  child: CircleAvatar(
                    backgroundColor: AppBackgroundStyles.buttonBackground(isDarkMode),
                    radius: 24,
                    child: Icon(Icons.send, color: AppIconStyles.iconPrimary(isDarkMode)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
