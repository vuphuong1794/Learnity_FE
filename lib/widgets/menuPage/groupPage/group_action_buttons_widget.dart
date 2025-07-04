import 'package:flutter/material.dart';
import 'package:learnity/screen/groupPage/group_management_page.dart';

import 'package:provider/provider.dart';
import 'package:learnity/theme/theme.dart';
import 'package:learnity/theme/theme_provider.dart';

class GroupActionButtonsWidget extends StatelessWidget {
  final String groupId;
  final bool isLoading;
  final bool isMember;
  final bool isAdmin;
  final bool isPreviewMode;
  final String groupPrivacy;
  final VoidCallback onJoinGroup;
  final VoidCallback onLeaveGroup;
  final VoidCallback onReportGroup;
  final VoidCallback? onInviteMember;
  final VoidCallback? onManageGroup;

  const GroupActionButtonsWidget({
    super.key,
    required this.groupId,
    required this.isLoading,
    required this.isMember,
    required this.isAdmin,
    required this.isPreviewMode,
    required this.groupPrivacy,
    required this.onJoinGroup,
    required this.onLeaveGroup,
    required this.onReportGroup,
    required this.onInviteMember,
    this.onManageGroup,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

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
          backgroundColor: groupPrivacy == 'Riêng tư'?AppBackgroundStyles.mainBackground(isDarkMode):AppBackgroundStyles.modalBackground(isDarkMode),
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          // overlayColor: Colors.transparent,
        ),
        onPressed: onJoinGroup,
        child: Text(
          (groupPrivacy == 'Riêng tư'
              ? 'Gửi yêu cầu tham gia'
              : 'Tham gia nhóm'),
          style: TextStyle(
            color: AppTextStyles.buttonTextColor(isDarkMode),
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
                  // Xử lý chia sẻ nhóm
                } else if (value == 'report_group') {
                  onReportGroup?.call();
                } else if (value == 'manage_group') {
                  onManageGroup?.call();
                }
              },
              itemBuilder: (BuildContext context) {
                List<PopupMenuEntry<String>> menuItems = [];

                // Nếu là admin, thêm các tùy chọn admin
                if (isAdmin) {
                  menuItems.addAll([
                    PopupMenuItem<String>(
                      value: 'manage_group',
                      child: ListTile(
                        leading: Icon(
                          Icons.settings_outlined,
                          color: Colors.blue,
                        ),
                        title: Text(
                          'Quản lý nhóm',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                    ),
                    const PopupMenuDivider(),
                  ]);
                }

                // Các tùy chọn chung cho tất cả thành viên
                menuItems.addAll([
                  const PopupMenuItem<String>(
                    value: 'share_group',
                    child: ListTile(
                      leading: Icon(Icons.share_outlined),
                      title: Text('Chia sẻ nhóm'),
                    ),
                  ),
                ]);

                // Nếu không phải admin, hiển thị tùy chọn báo cáo và rời nhóm
                if (!isAdmin) {
                  menuItems.addAll([
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
                  ]);
                }

                return menuItems;
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: isAdmin ? AppColors.adminColor : AppBackgroundStyles.buttonBackgroundSecondary(isDarkMode),
                  borderRadius: BorderRadius.circular(25.0),
                  border: Border.all(
                    color: AppIconStyles.iconPrimary(isDarkMode),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isAdmin
                          ? Icons.admin_panel_settings
                          : Icons.people_alt_outlined,
                      size: 20,
                      color: isAdmin ? Colors.white : AppIconStyles.iconPrimary(isDarkMode),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isAdmin ? 'Quản trị viên' : 'Đã tham gia',
                      style: TextStyle(
                        fontSize: 15,
                        color: isAdmin ? Colors.white : AppTextStyles.normalTextColor(isDarkMode),
                        // color: AppTextStyles.normalTextColor(isDarkMode),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_drop_down,
                      size: 24,
                      color: isAdmin ? Colors.white :  AppIconStyles.iconPrimary(isDarkMode),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onInviteMember,
              icon: Icon(
                Icons.person_add_alt_1_rounded,
                color: AppIconStyles.iconPrimary(isDarkMode),
                size: 20,
              ),
              label: Text(
                'Mời bạn',
                style: TextStyle(
                  color: AppTextStyles.buttonTextColor(isDarkMode),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: AppBackgroundStyles.mainBackground(isDarkMode),
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
  }
}
