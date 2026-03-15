import 'package:flutter/foundation.dart' show kIsWeb;

// For web: use the same host the page is served from (works for localhost AND LAN)
// For mobile: use 10.0.2.2 (Android emulator) or localhost (iOS simulator)
String get _host {
  if (kIsWeb) {
    // On web, we'll use the server's known address
    // When running locally: localhost
    // When accessing from phone on same WiFi: use LAN IP
    return Uri.base.host; // auto-detects: localhost or 192.168.x.x
  }
  return '103.232.122.149'; // Android emulator
}

final String baseUrl = 'http://$_host:8090/api/v1';
final String wsUrl = 'ws://$_host:8090/ws';
