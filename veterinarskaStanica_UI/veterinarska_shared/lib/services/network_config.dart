import 'dart:io';
import 'package:flutter/foundation.dart';

class NetworkConfig {
  // Detektuj platformu i odredi base URL
  static String get baseUrl {
    if (kIsWeb) {
      // Web - koristi localhost
      return 'http://localhost:5160/api';
    } else if (Platform.isAndroid) {
      // Android emulator - koristi 10.0.2.2
      return 'http://10.0.2.2:5160/api';
    } else if (Platform.isIOS) {
      // iOS simulator - koristi 127.0.0.1
      return 'http://127.0.0.1:5160/api';
    } else {
      // Desktop/ostalo - koristi localhost
      return 'http://localhost:5160/api';
    }
  }

  // Override preko --dart-define
  static String get apiBaseUrl {
    // Proveri da li je definisan custom URL preko --dart-define
    const customUrl = String.fromEnvironment('API_BASE_URL');
    if (customUrl.isNotEmpty) {
      if (kDebugMode) {
        print('🌐 Using custom API URL from --dart-define: $customUrl');
      }
      return customUrl;
    }
    
    final url = baseUrl;
    if (kDebugMode) {
      print('🌐 Using platform-specific API URL: $url');
    }
    return url;
  }
}


