import 'package:flutter/foundation.dart' show kIsWeb;

class AppConfig {
  // Chrome/desktop: the Laravel server is running on this computer.
  // Android Emulator: 10.0.2.2 maps back to the host computer.
  // Real phone: replace the host with your PC's LAN IP (same Wi-Fi).
  static const String host =
      kIsWeb ? 'http://127.0.0.1:8000' : 'http://10.0.2.2:8000';

  static const String apiUrl = '$host/api';
  // Serve images through the API so Flutter Web receives the API CORS headers.
  static const String storageUrl = '$host/api/images';
}
