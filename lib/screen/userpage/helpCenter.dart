import 'package:flutter/material.dart';

class Helpcenter extends StatelessWidget {
  const Helpcenter({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFA7F6D1),
      appBar: AppBar(
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          'Trợ giúp và hỗ trợ',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 25,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFA7F6D1),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.help_outline, color: Colors.black),
                  SizedBox(width: 8),
                  Text(
                    'Câu hỏi thường gặp',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...[
                "Làm cách nào để đổi mật khẩu?",
                "Cách tạo một ghi chú mới?",
                "Pomodoro hoạt động như thế nào?",
                "Tôi muốn xóa app ?",
              ].map(
                (q) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(q),
                ),
              ),
              const SizedBox(height: 20),

              // Responsive buttons
              isSmallScreen
                  ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {},
                        icon: const Icon(Icons.mail_outline),
                        label: const Text("Hộp thư hỗ trợ"),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {},
                        icon: const Icon(Icons.report_gmailerrorred_outlined),
                        label: const Text("Báo cáo sự cố"),
                      ),
                    ],
                  )
                  : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {},
                        icon: const Icon(Icons.mail_outline),
                        label: const Text("Hộp thư hỗ trợ"),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {},
                        icon: const Icon(Icons.report_gmailerrorred_outlined),
                        label: const Text("Báo cáo sự cố"),
                      ),
                    ],
                  ),

              const SizedBox(height: 30),
              const Row(
                children: [
                  Icon(Icons.contact_mail_outlined, color: Colors.black),
                  SizedBox(width: 8),
                  Text(
                    'Liên hệ với chúng tôi',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const ListTile(
                leading: Icon(Icons.email_outlined, color: Colors.pink),
                title: Text('Email : support@learnity.com'),
              ),
              const ListTile(
                leading: Icon(Icons.phone_outlined),
                title: Text('Gọi điện : +84 123 456 789'),
              ),
              const ListTile(
                leading: Icon(Icons.language_outlined),
                title: Text('Website : www.learnity.com'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
