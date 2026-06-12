import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._();

  static const String appName = 'Arteflix';

  static String get driveApiKey => _get('DRIVE_API_KEY');
  static String get driveFolderId => _get('DRIVE_FOLDER_ID');

  static const String driveBaseUrl = 'https://www.googleapis.com/drive/v3';
  static const String driveDownloadUrl = 'https://www.googleapis.com/drive/v3/files';

  static const String placeholderImage = 'assets/placeholder.png';

  static const Duration cacheDuration = Duration(hours: 1);

  static String _get(String key) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      throw Exception('$key no está definida en el archivo .env');
    }
    return value;
  }
}
