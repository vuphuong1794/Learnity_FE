import 'package:flutter/material.dart';
import 'package:learnity/models/bottom_sheet_option.dart';
import 'package:learnity/theme/theme.dart';

Future<void> showCustomBottomSheet({
  required BuildContext context,
  required bool isDarkMode,
  required List<BottomSheetOption> options,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: AppBackgroundStyles.modalBackground(isDarkMode),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children:
            options
                .map(
                  (option) => ListTile(
                    leading: Icon(
                      option.icon,
                      color: AppIconStyles.iconPrimary(isDarkMode),
                    ),
                    title: Text(
                      option.text,
                      style: TextStyle(
                        color: AppTextStyles.normalTextColor(isDarkMode),
                      ),
                    ),
                    onTap: option.onTap,
                  ),
                )
                .toList(),
      );
    },
  );
}
