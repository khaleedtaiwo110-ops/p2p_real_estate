import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class ApiConfig {
  static String get baseUrl {
    // 🌐 Automatically uses your live Render backend on Vercel / production releases
    if (kReleaseMode) {
      return 'https://p2p-real-estate-backend.onrender.com/api';
    }

    // 💻 Local development fallbacks
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api';
    }
    return 'http://127.0.0.1:8000/api';
  }
}