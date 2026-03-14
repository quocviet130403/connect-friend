import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LocationService {
  /// Request permission and get current GPS position
  static Future<Position?> getCurrentPosition() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services disabled');
      return null;
    }

    // Check/request permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Location permission denied');
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permission permanently denied');
      return null;
    }

    // Get current position
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );
  }

  /// Reverse geocode coordinates to address using OpenStreetMap Nominatim (free)
  static Future<Map<String, String>?> reverseGeocode(double lat, double lng) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1',
      );

      final response = await http.get(url, headers: {
        'User-Agent': 'ConnectApp/1.0',
        'Accept-Language': 'vi',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>? ?? {};

        // Build a human-readable address
        final parts = <String>[];
        if (address['road'] != null) parts.add(address['road']);
        if (address['suburb'] != null) parts.add(address['suburb']);
        if (address['city_district'] != null) parts.add(address['city_district']);
        if (address['city'] != null) parts.add(address['city']);

        return {
          'display_name': data['display_name'] ?? '',
          'short_address': parts.join(', '),
          'city': address['city'] ?? address['town'] ?? address['state'] ?? '',
          'road': address['road'] ?? '',
        };
      }
    } catch (e) {
      debugPrint('Reverse geocode error: $e');
    }
    return null;
  }
}
