import 'package:flutter/material.dart';
import '../../theme/theme.dart';  // Đường dẫn import file theme của bạn, điều chỉnh nếu cần

class FooterBar extends StatelessWidget {
  final bool isDarkMode;

  final void Function(int) onTap;
  final int selectedIndex;

  const FooterBar({
    Key? key,
    required this.isDarkMode,
    required this.onTap,
    required this.selectedIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isDarkMode ? AppColors.darkBackground : AppColors.background;
    final iconColor = isDarkMode ? Colors.white : Colors.black;

    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildIconButton(Icons.home, 0, iconColor),
          _buildIconButton(Icons.search, 1, iconColor),
          _buildIconButton(Icons.add_circle_outline, 2, iconColor),
          _buildIconButton(Icons.notifications_outlined, 3, iconColor),
          _buildIconButton(Icons.menu, 4, iconColor),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, int index, Color iconColor) {
    final isSelected = index == selectedIndex;
    return IconButton(
      onPressed: () => onTap(index),
      icon: Icon(
        icon,
        color: isSelected ? Colors.blue : iconColor,
        size: 28,
      ),
    );
  }
}
