import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

class ApiService {
  String? _accessToken;
  String? _refreshToken;

  // HTTP client with timeout
  final http.Client _client = http.Client();
  static const _timeout = Duration(seconds: 15);

  // Singleton
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // ========== Token Management ==========

  Future<void> loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    _refreshToken = prefs.getString('refresh_token');
  }

  Future<void> saveTokens(String access, String refresh) async {
    _accessToken = access;
    _refreshToken = refresh;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', access);
    await prefs.setString('refresh_token', refresh);
  }

  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }

  bool get isLoggedIn => _accessToken != null;
  String? get token => _accessToken;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
  };

  // ========== HTTP Methods ==========

  Future<Map<String, dynamic>> get(String path, {Map<String, String>? query}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    debugPrint('[API] GET $uri');
    final res = await _client.get(uri, headers: _headers).timeout(_timeout);
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl$path');
    debugPrint('[API] POST $uri');
    final res = await _client.post(
      uri,
      headers: _headers,
      body: jsonEncode(body),
    ).timeout(_timeout);
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> put(String path, [Map<String, dynamic>? body]) async {
    final uri = Uri.parse('$baseUrl$path');
    debugPrint('[API] PUT $uri');
    final res = await _client.put(
      uri,
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    ).timeout(_timeout);
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> delete(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    debugPrint('[API] DELETE $uri');
    final res = await _client.delete(uri, headers: _headers).timeout(_timeout);
    return _handleResponse(res);
  }

  Map<String, dynamic> _handleResponse(http.Response res) {
    debugPrint('[API] Response ${res.statusCode}: ${res.body.length > 200 ? res.body.substring(0, 200) : res.body}');
    
    Map<String, dynamic> body;
    try {
      body = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      // Response is not valid JSON (e.g., HTML error page from nginx)
      throw ApiException(
        statusCode: res.statusCode,
        message: 'Server error (${res.statusCode}). Vui lòng thử lại sau.',
      );
    }
    
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body;
    }
    throw ApiException(
      statusCode: res.statusCode,
      message: body['error'] ?? 'Unknown error',
    );
  }

  // ========== Auth APIs ==========

  Future<Map<String, dynamic>> register(String phone, String password, String deviceId) async {
    final res = await post('/auth/register', {
      'phone': phone,
      'password': password,
      'device_id': deviceId,
    });
    if (res['success'] == true && res['data'] != null) {
      await saveTokens(res['data']['access_token'], res['data']['refresh_token']);
    }
    return res;
  }

  Future<Map<String, dynamic>> login(String phone, String password) async {
    final res = await post('/auth/login', {
      'phone': phone,
      'password': password,
    });
    if (res['success'] == true && res['data'] != null) {
      await saveTokens(res['data']['access_token'], res['data']['refresh_token']);
    }
    return res;
  }

  Future<void> logout() async {
    await clearTokens();
  }

  // ========== Profile APIs ==========

  Future<Map<String, dynamic>> getMyProfile() => get('/profile');
  
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) => put('/profile', data);
  
  Future<Map<String, dynamic>> getProfile(String userId) => get('/profile/$userId');
  
  Future<Map<String, dynamic>> updateLocation(double lng, double lat) => put('/profile/location', {
    'longitude': lng,
    'latitude': lat,
  });

  // ========== Club APIs ==========

  Future<Map<String, dynamic>> getClubs({String? city, String? category}) {
    final query = <String, String>{};
    if (city != null) query['city'] = city;
    if (category != null) query['category'] = category;
    return get('/clubs', query: query.isEmpty ? null : query);
  }

  Future<Map<String, dynamic>> createClub(Map<String, dynamic> data) => post('/clubs', data);
  
  Future<Map<String, dynamic>> getClub(String id) => get('/clubs/$id');
  
  Future<Map<String, dynamic>> joinClub(String id) => post('/clubs/$id/join', {});
  
  Future<Map<String, dynamic>> leaveClub(String id) => delete('/clubs/$id/leave');
  
  Future<Map<String, dynamic>> getClubMembers(String id) => get('/clubs/$id/members');

  // ========== Meetup APIs ==========

  Future<Map<String, dynamic>> getMeetups({String? clubId}) {
    final query = <String, String>{};
    if (clubId != null) query['club_id'] = clubId;
    return get('/meetups', query: query.isEmpty ? null : query);
  }

  Future<Map<String, dynamic>> createMeetup(Map<String, dynamic> data) => post('/meetups', data);
  
  Future<Map<String, dynamic>> getMeetup(String id) => get('/meetups/$id');
  
  Future<Map<String, dynamic>> joinMeetup(String id) => post('/meetups/$id/join', {});
  
  Future<Map<String, dynamic>> leaveMeetup(String id) => delete('/meetups/$id/leave');
  
  Future<Map<String, dynamic>> nearbyMeetups(double lng, double lat, {double radius = 5}) {
    return get('/meetups/nearby', query: {
      'longitude': lng.toString(),
      'latitude': lat.toString(),
      'radius_km': radius.toString(),
    });
  }

  Future<Map<String, dynamic>> inviteToMeetup(String meetupId, List<String> userIds) =>
      post('/meetups/$meetupId/invite', {'user_ids': userIds});

  Future<Map<String, dynamic>> getPendingInvites() => get('/invites/pending');
  
  Future<Map<String, dynamic>> acceptInvite(String id) => put('/invites/$id/accept');
  
  Future<Map<String, dynamic>> declineInvite(String id) => put('/invites/$id/decline');

  // ========== Chat APIs ==========

  Future<Map<String, dynamic>> getMessages(String roomId, {int page = 1}) =>
      get('/chat/$roomId/messages', query: {'page': page.toString()});

  Future<Map<String, dynamic>> sendMessage(String roomId, String content, {String type = 'text'}) =>
      post('/chat/$roomId/messages', {'content': content, 'message_type': type});

  // ========== Notification APIs ==========

  Future<Map<String, dynamic>> getNotifications({int page = 1}) =>
      get('/notifications', query: {'page': page.toString()});

  Future<Map<String, dynamic>> markNotificationRead(String id) => put('/notifications/$id/read');
  
  Future<Map<String, dynamic>> markAllNotificationsRead() => put('/notifications/read-all');
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException($statusCode): $message';
}
