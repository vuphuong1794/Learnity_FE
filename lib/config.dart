import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config {
  // Endpoint
  static String get apiUrl =>
      dotenv.env['API_URL'] ?? '';

  // Gemini
  static String get geminiApiKey =>
      dotenv.env['GEMINI_API_KEY'] ?? '';

  static int get appId =>
    int.tryParse(dotenv.env['APP_ID'] ?? '') ?? 0;
  static String get appSign =>
      dotenv.env['APP_SIGN'] ?? '';

  // Cloudinary
  static String get cloudinaryApiKey1 =>
      dotenv.env['CLOUDINARY_API_KEY1'] ?? '';
  static String get cloudinaryApiSecret1 =>
      dotenv.env['CLOUDINARY_API_SECRET1'] ?? '';
  static String get cloudinaryCloudName1 =>
      dotenv.env['CLOUDINARY_CLOUD_NAME1'] ?? '';

  static String get cloudinaryApiKey2 =>
      dotenv.env['CLOUDINARY_API_KEY2'] ?? '';
  static String get cloudinaryApiSecret2 =>
      dotenv.env['CLOUDINARY_API_SECRET2'] ?? '';
  static String get cloudinaryCloudName2 =>
      dotenv.env['CLOUDINARY_CLOUD_NAME2'] ?? '';
}
