import 'package:flutter/foundation.dart' show kIsWeb;

// For web: use same-origin (Nginx proxies /api and /ws to backend)
// For mobile: use direct server IP
String get _host {
  if (kIsWeb) {
    return Uri.base.host; // auto-detects: localhost or domain
  }
  return '103.232.122.149'; // Direct server IP for mobile
}

String get _protocol {
  if (kIsWeb) {
    return Uri.base.scheme; // auto: http or https
  }
  return 'http';
}

String get _wsProtocol {
  if (kIsWeb) {
    return Uri.base.scheme == 'https' ? 'wss' : 'ws';
  }
  return 'ws';
}

// Web: same-origin (no port needed, Nginx proxies)
// Mobile: direct connection with port
final String baseUrl = kIsWeb
    ? '$_protocol://$_host/api/v1'
    : 'http://$_host:8090/api/v1';

final String wsUrl = kIsWeb
    ? '$_wsProtocol://$_host/ws'
    : 'ws://$_host:8090/ws';

