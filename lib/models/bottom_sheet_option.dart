import 'dart:ui';

import 'package:flutter/material.dart';

class BottomSheetOption {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  BottomSheetOption({
    required this.icon,
    required this.text,
    required this.onTap,
  });
}
