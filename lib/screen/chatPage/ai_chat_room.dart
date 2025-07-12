import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';
import 'package:learnity/config.dart';
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

  final ScrollController _scrollController = ScrollController();

  // System prompt để hướng dẫn AI chỉ trả lời về học tập
  final String systemPrompt = """
Bạn là một trợ lý AI học tập thông minh. Nhiệm vụ của bạn là:

1. CHỈ trả lời những câu hỏi liên quan đến học tập, giáo dục, kiến thức học thuật
2. Các chủ đề được phép:
   - Toán học, Vật lý, Hóa học, Sinh học
   - Ngữ văn, Lịch sử, Địa lý
   - Tiếng Anh và các ngoại ngữ khác
   - Tin học, Công nghệ
   - Kỹ năng học tập, phương pháp học
   - Giải thích bài tập, lý thuyết

3. KHÔNG trả lời các câu hỏi về:
   - Giải trí, phim ảnh, âm nhạc (trừ khi liên quan đến học tập)
   - Đời sống cá nhân, tình cảm
   - Chính trị, tôn giáo
   - Các chủ đề không liên quan đến học tập

4. Nếu câu hỏi không liên quan đến học tập, hãy lịch sự từ chối và gợi ý hỏi về chủ đề học tập.

Hãy trả lời bằng tiếng Việt một cách thân thiện và dễ hiểu.
""";

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

    try {
      final model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: Config.geminiApiKey,
        systemInstruction: Content.text(systemPrompt), // Thêm system prompt
      );

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
    } catch (e) {
      setState(() {
        _messages.add(
          Message(
            isUser: false,
            message: "Có lỗi xảy ra khi xử lý câu hỏi. Vui lòng thử lại.",
            date: DateTime.now().toString(),
          ),
        );
      });
    }

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
          'Learnity AI - Trợ lý học tập',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppBackgroundStyles.secondaryBackground(isDarkMode),
        foregroundColor: AppTextStyles.normalTextColor(isDarkMode),
        elevation: 2,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Thêm banner thông báo về chức năng
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.school, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tôi chỉ trả lời các câu hỏi về học tập và giáo dục',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue[800],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
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
                            style: TextStyle(color: Colors.white, fontSize: 16),
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
                Expanded(
                  child: TextFormField(
                    style: TextStyle(
                      color: AppTextStyles.normalTextColor(isDarkMode),
                    ),
                    controller: _userInput,
                    decoration: InputDecoration(
                      hintText: "Hỏi về bài học, kiến thức...",
                      hintStyle: TextStyle(
                        color: AppTextStyles.normalTextColor(
                          isDarkMode,
                        ).withOpacity(0.5),
                      ),
                      filled: true,
                      fillColor: AppBackgroundStyles.buttonBackgroundSecondary(
                        isDarkMode,
                      ),

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
                    backgroundColor: AppBackgroundStyles.buttonBackground(
                      isDarkMode,
                    ),
                    radius: 24,
                    child: Icon(
                      Icons.send,
                      color: AppIconStyles.iconPrimary(isDarkMode),
                    ),
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
