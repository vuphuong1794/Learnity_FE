import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:learnity/screen/groupPage/group_management_page.dart';

import 'package:provider/provider.dart';
import 'package:learnity/theme/theme.dart';
import 'package:learnity/theme/theme_provider.dart';

import '../../../models/bottom_sheet_option.dart';
import '../../../screen/groupPage/manage_group_members_screen.dart';
import '../../../screen/groupPage/manage_join_requests_screen.dart';
import '../../../screen/groupPage/manage_pending_posts_screen.dart';
import '../../common/confirm_modal.dart';
import '../../common/custom_bottom_sheet.dart';

class GroupActionButtonsWidget extends StatelessWidget {
  final String groupId;
  final String groupName;
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
  final Future<void> Function(bool isDarkMode)? onDeleteGroup;

  const GroupActionButtonsWidget({
    super.key,
    required this.groupId,
    required this.groupName,
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
    this.onDeleteGroup,
  });

  void onSelected(String value) {
    if (value == 'leave_group') {
      onLeaveGroup();
    } else if (value == 'report_group') {
      onReportGroup?.call();
    } else if (value == 'manage_group') {
      onManageGroup?.call();
    }
  }

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
            child: GestureDetector(
              onTap: () async {
                final List<BottomSheetOption> options = [];

                // Admin: các tùy chọn quản trị
                if (isAdmin) {
                  if (groupPrivacy == 'Riêng tư') {
                    options.add(
                      BottomSheetOption(
                        icon: Icons.checklist_rtl_rounded,
                        text: 'Duyệt yêu cầu tham gia',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ManageJoinRequestsScreen(
                                groupId: groupId,
                                groupName: groupName,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }

                  options.addAll([
                    BottomSheetOption(
                      icon: Icons.groups_outlined,
                      text: 'Quản lý thành viên',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ManageGroupMembersScreen(
                              groupId: groupId,
                              groupName: groupName,
                            ),
                          ),
                        );
                      },
                    ),
                    BottomSheetOption(
                      icon: Icons.rate_review_outlined,
                      text: 'Duyệt bài đăng',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ManagePendingPostsScreen(
                              groupId: groupId,
                              groupName: groupName,
                            ),
                          ),
                        );
                      },
                    ),
                    BottomSheetOption(
                      icon: Icons.delete_forever,
                      text: 'Xóa nhóm',
                      onTap: () async {
                        Navigator.pop(context);
                        final confirm = await showConfirmModal(
                          context: context,
                          isDarkMode: isDarkMode,
                          title: 'Xác nhận xóa nhóm',
                          content:
                          'Bạn có chắc chắn muốn xóa vĩnh viễn nhóm này không?',
                          cancelText: 'Hủy',
                          confirmText: 'Xóa',
                        );
                        if (confirm == true && onDeleteGroup != null) {
                          await onDeleteGroup!(isDarkMode);
                        }
                      },
                    ),
                  ]);
                  options.add(
                    BottomSheetOption(
                      icon: Icons.settings_outlined,
                      text: 'Quản lý nhóm',
                      onTap: () {
                        Navigator.pop(context);
                        onSelected('manage_group');
                      },
                    ),
                  );
                }

                // Không phải admin: báo cáo / rời nhóm
                if (!isAdmin) {
                  options.addAll([
                    BottomSheetOption(
                      icon: Icons.flag_outlined,
                      text: 'Báo cáo nhóm',
                      onTap: () {
                        Navigator.pop(context);
                        onSelected('report_group');
                      },
                    ),
                    BottomSheetOption(
                      icon: Icons.exit_to_app,
                      text: 'Rời khỏi nhóm',
                      onTap: () {
                        Navigator.pop(context);
                        onSelected('leave_group');
                      },
                    ),
                  ]);
                }

                if (options.isEmpty) {
                  Get.snackbar("Thông báo", "Không có thao tác khả dụng.");
                  return;
                }

                showCustomBottomSheet(
                  context: context,
                  isDarkMode: isDarkMode,
                  options: options,
                );
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
