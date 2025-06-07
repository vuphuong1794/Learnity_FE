import 'package:flutter/material.dart';

class ViewInviteGroup extends StatefulWidget {
  const ViewInviteGroup({super.key});

  @override
  State<ViewInviteGroup> createState() => _ViewInviteGroupState();
}

class _ViewInviteGroupState extends State<ViewInviteGroup> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lời mời tham gia nhóm',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16.0),
          const Text(
            'Bạn đã được mời tham gia nhóm này. Bạn có thể chấp nhận hoặc từ chối lời mời.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16.0),
          ElevatedButton(
            onPressed: () {
              // Xử lý chấp nhận lời mời
            },
            child: const Text('Chấp nhận'),
          ),
          ElevatedButton(
            onPressed: () {
              // Xử lý từ chối lời mời
            },
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );
  }
}
