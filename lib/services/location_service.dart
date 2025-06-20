// lib/services/location_service.dart

import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:logger/logger.dart'; // Add logger import if you want to use it here

class LocationService {
  final Logger _logger = Logger(); // Initialize logger

  Future<Map<String, dynamic>> getCurrentLocation() async {
    _logger.d('LocationService: Checking if service is enabled...');
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _logger.e('LocationService: Location service is not enabled.');
      throw Exception('خدمة الموقع غير مفعّلة');
    }

    _logger.d('LocationService: Checking permissions...');
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      _logger.w('LocationService: Location permission denied, requesting...');
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _logger.e('LocationService: Location permission denied after request.');
        throw Exception('تم رفض صلاحية الموقع');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _logger.e('LocationService: Location permission denied forever.');
      throw Exception('صلاحية الموقع مرفوضة نهائياً');
    }

    _logger.d('LocationService: Permissions granted. Attempting to get current position...');
    Position? position; // Make it nullable for safer initial assignment
    try {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10), // Add a timeout
      );
      if (position == null) {
        _logger.e('LocationService: Geolocator.getCurrentPosition returned null.');
        throw Exception('فشل في الحصول على الموقع: قيمة فارغة غير متوقعة');
      }
      _logger.d('LocationService: Position obtained: ${position.latitude}, ${position.longitude}');
    } on TimeoutException {
      _logger.e('LocationService: Geolocator.getCurrentPosition timed out.');
      throw Exception('فشل في الحصول على الموقع: انتهت المهلة');
    } catch (e) {
      _logger.e('LocationService: Error getting position: $e');
      throw Exception('فشل في الحصول على الموقع: $e');
    }


    _logger.d('LocationService: Attempting to get placemarks...');
    List<Placemark> placemarks = [];
    try {
      placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isEmpty) {
        _logger.w('LocationService: No placemarks found for coordinates: ${position.latitude}, ${position.longitude}');
        // You might decide to still return location even if name is not found
        return {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'location': 'موقع غير معروف', // Default if no placemark
        };
      }
      _logger.d('LocationService: Placemarks obtained.');
    } catch (e) {
      _logger.e('LocationService: Error getting placemarks: $e');
      // If geocoding fails, you still have lat/lng
      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'location': 'فشل تحديد الاسم (خطأ: $e)',
      };
    }

    final place = placemarks.first;
    final locationName = "${place.street}, ${place.locality}";
    _logger.d('LocationService: Location name: $locationName');

    return {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'location': locationName,
    };
  }
}