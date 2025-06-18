// lib/screens/map_picker_screen.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class MapPickerScreen extends StatefulWidget {
  final LatLng initialLocation;
  const MapPickerScreen({required this.initialLocation, super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late LatLng pickedLocation;
  final MapController _mapController = MapController();
  bool _loadingLocation = false;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    pickedLocation = widget.initialLocation;
  }

  Future<void> _goToCurrentLocation() async {
    setState(() {
      _loadingLocation = true;
      _locationError = null;
    });

    try {
      LatLng? currentLocation;

      if (kIsWeb) {
        // Web-specific location handling
        currentLocation = await _getCurrentLocationWeb();
      } else {
        // Mobile-specific location handling
        currentLocation = await _getCurrentLocationMobile();
      }

      if (currentLocation != null) {
        setState(() {
          pickedLocation = currentLocation!;
        });
        _mapController.move(currentLocation, 15.0);
      }
    } catch (e) {
      setState(() {
        _locationError = e.toString();
      });
    } finally {
      setState(() {
        _loadingLocation = false;
      });
    }
  }

  Future<LatLng?> _getCurrentLocationWeb() async {
    try {
      // For web, we'll use the browser's geolocation API through geolocator
      // But with different error handling

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // On web, this might always return false, so we'll try anyway
        debugPrint('Location services might not be available on web');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('تم رفض صلاحية الموقع من المتصفح');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('صلاحية الموقع مرفوضة نهائيًا من المتصفح. يرجى تفعيلها من إعدادات المتصفح');
      }

      // For web, use a longer timeout and lower accuracy
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );

      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      debugPrint('Web location error: $e');
      // Provide more web-specific error messages
      if (e.toString().contains('User denied') || e.toString().contains('denied')) {
        throw Exception('تم رفض صلاحية الموقع من المتصفح. يرجى السماح للموقع بالوصول للموقع');
      } else if (e.toString().contains('timeout') || e.toString().contains('time')) {
        throw Exception('انتهت مهلة تحديد الموقع. يرجى التأكد من تفعيل خدمة الموقع في المتصفح');
      } else if (e.toString().contains('network') || e.toString().contains('Network')) {
        throw Exception('خطأ في الشبكة. يرجى التأكد من اتصال الإنترنت');
      } else {
        throw Exception('خطأ في تحديد الموقع على المتصفح: ${e.toString()}');
      }
    }
  }

  Future<LatLng?> _getCurrentLocationMobile() async {
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
      throw Exception('صلاحية الموقع مرفوضة نهائيًا');
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    return LatLng(position.latitude, position.longitude);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختر موقع الوظيفة'),
        actions: [
          if (_loadingLocation)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.my_location),
              tooltip: kIsWeb ? 'موقعي الحالي (يتطلب إذن المتصفح)' : 'موقعي الحالي',
              onPressed: _goToCurrentLocation,
            ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () => Navigator.of(context).pop(pickedLocation),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialLocation,
              initialZoom: 13.0,
              onTap: (_, latlng) {
                setState(() {
                  pickedLocation = latlng;
                  _locationError = null; // Clear error when user taps
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                // Add user agent for web compatibility
                additionalOptions: kIsWeb ? {
                  'User-Agent': 'YourAppName/1.0',
                } : {},
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    width: 40,
                    height: 40,
                    point: pickedLocation,
                    child: const Icon(
                      Icons.location_on,
                      size: 32,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Instructions overlay for web users
          if (kIsWeb)
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'انقر على الخريطة لاختيار الموقع، أو استخدم زر الموقع الحالي',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          // Error message
          if (_locationError != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _locationError!,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    if (kIsWeb && _locationError!.contains('رفض'))
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          'يمكنك النقر على الخريطة لاختيار الموقع يدوياً',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _locationError = null;
                        });
                      },
                      child: const Text(
                        'إغلاق',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Crosshair indicator for better UX
          const Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Icon(
                  Icons.add,
                  size: 30,
                  color: Colors.black54,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}