import 'package:flutter/material.dart';

class CheckBadWords {
  static final List<String> _badWords = [
    'chửi', 'đm', 'vkl', 'vl', 'cc', 'shit', 'fuck', 'bitch', 'ngu', 'đần',
    'dốt', 'địt', 'lồn', 'cặc', 'đụ', 'đéo', 'má', 'mẹ', 'cút', 'clm'
  ];

  // Hàm kiểm tra có chứa từ cấm hay không
  static bool containsBadWords(String text) {
    final lowerText = text.toLowerCase();
    return _badWords.any((word) => lowerText.contains(word));
  }
}
