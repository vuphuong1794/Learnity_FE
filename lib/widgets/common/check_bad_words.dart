import 'package:flutter/material.dart';

class CheckBadWords {
  static final List<String> _badWords = [
    'chửi', 'đm', 'vkl', 'vl', 'cc', 'dm', 'cl', 'clm', 'dcm', 'vcl',
    'shit', 'fuck', 'f*ck', 'fck', 'bitch', 'bít', 'ngu', 'đần', 'dốt',
    'địt', 'lồn', 'cặc', 'đụ', 'đéo', 'đếch', 'bú', 'bú lol', 'bú l',
    'cmm', 'cml', 'má', 'mẹ', 'con mẹ', 'cái lồn', 'thằng chó', 'con chó',
    'đồ chó', 'óc chó', 'óc lợn', 'mẹ mày', 'bố mày', 'bố láo', 'láo toét',
    'mịa', 'mịa nó', 'mẹ kiếp', 'rảnh chó', 'mày', 'tao', 'chó chết',
    'nigger', 'nigga', 'retard', 'whore', 'slut', 'asshole',
    'sale', 'giảm giá', 'khuyến mãi', 'mua ngay', 'giá sốc', 'xả hàng',
    'ship cod', 'đặt hàng', 'order', 'inbox ngay', 'bán gấp', 'thanh lý',
    'sale off', 'giao tận nơi', 'mở bán', 'săn sale', 'deal hot', 'like share',
    'đăng ký ngay', 'nhận hàng', 'ưu đãi', 'freeship', 'tặng kèm', 'sỉ lẻ',
    'fuk', 'phắc', 'ccmnr', 'đmnl', 'đụ má', 'nòi', 'dkm', 'vcl thật',
  ];

  // Hàm kiểm tra có chứa từ cấm hay không
  static bool containsBadWords(String text) {
    final lowerText = text.toLowerCase();
    return _badWords.any((word) => lowerText.contains(word));
  }
}
