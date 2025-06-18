import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
class LocationService{

  Future<Map<String, dynamic>> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('خدمة الموقع غير مفعّلة');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('تم رفض صلاحية الموقع');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('صلاحية الموقع مرفوضة نهائياً');
    }

    final position = await Geolocator.getCurrentPosition();
    final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
    final place = placemarks.first;

    final locationName = "${place.street}, ${place.locality}";

    return {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'location': locationName,
    };
  }

}