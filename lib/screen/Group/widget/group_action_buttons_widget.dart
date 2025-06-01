import 'package:flutter/material.dart';

class GroupActionButtonsWidget extends StatelessWidget {
  final bool isLoading;
  final bool isMember;
  final bool isPreviewMode;
  final String groupPrivacy;
  final VoidCallback onJoinGroup;
  final VoidCallback onLeaveGroup;

  const GroupActionButtonsWidget({
    super.key,
    required this.isLoading,
    required this.isMember,
    required this.isPreviewMode,
    required this.groupPrivacy,
    required this.onJoinGroup,
    required this.onLeaveGroup,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 10.0),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (isPreviewMode) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFB0D9D5),
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        onPressed: onJoinGroup,
        child: Text(
          (groupPrivacy == 'Riêng tư'
              ? 'Gửi yêu cầu tham gia'
              : 'Tham gia nhóm'),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    if (isMember) {
      return Row(
        children: [
          Expanded(
            child: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'leave_group') {
                  onLeaveGroup();
                } else if (value == 'share_group') {
                } else if (value == 'report_group') {}
              },
              itemBuilder:
                  (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'share_group',
                      child: ListTile(
                        leading: Icon(Icons.share_outlined),
                        title: Text('Chia sẻ nhóm'),
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'report_group',
                      child: ListTile(
                        leading: Icon(Icons.flag_outlined),
                        title: Text('Báo cáo nhóm'),
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem<String>(
                      value: 'leave_group',
                      child: ListTile(
                        leading: Icon(Icons.exit_to_app, color: Colors.red),
                        title: Text(
                          'Rời khỏi nhóm',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  ],
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0EE),
                  borderRadius: BorderRadius.circular(25.0),
                  border: Border.all(color: Colors.grey.shade400, width: 1),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_alt_outlined,
                      size: 20,
                      color: Colors.black87,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Đã tham gia',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_drop_down,
                      size: 24,
                      color: Colors.black87,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(
                Icons.person_add_alt_1_rounded,
                color: Colors.white,
                size: 20,
              ),
              label: const Text(
                'Mời bạn',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onPressed: () {
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: const Color(0xFF8A9A95),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25.0),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
      );
    } else {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFB0D9D5),
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        onPressed:
            onJoinGroup,
        child: Text(
          (groupPrivacy == 'Riêng tư'
              ? 'Gửi yêu cầu tham gia'
              : 'Tham gia nhóm'),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }
}
