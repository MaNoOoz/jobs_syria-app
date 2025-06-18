// lib/features/home/presentation/screens/map_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster_plus/flutter_map_marker_cluster_plus.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../../../controllers/home_controller.dart'; // Import HomeController
import '../../../../models.dart';
import 'job_details_screen.dart';
import 'map_controller.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mapCtrl = Get.find<MapControllerX>();
    final homeCtrl = Get.find<HomeController>(); // Get HomeController instance

    final cs = Theme.of(context).colorScheme;
    final TextTheme tt = Theme.of(context).textTheme;

    return Scaffold(
      body: Obx(() {
        if (mapCtrl.isLoadingLocation.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (mapCtrl.locationError.value.isNotEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_off, size: 60, color: cs.error),
                  const SizedBox(height: 16),
                  Text(
                    mapCtrl.locationError.value,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.tajawal(
                      color: cs.onSurfaceVariant,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => mapCtrl.goToCurrentLocation(), // Retry
                    icon: const Icon(Icons.refresh),
                    label: Text('إعادة المحاولة', style: GoogleFonts.tajawal()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // --- Determine initial center based on HomeController's user location ---
        final initialCenter = homeCtrl.userLat.value != null && homeCtrl.userLng.value != null
            ? LatLng(homeCtrl.userLat.value!, homeCtrl.userLng.value!)
            : LatLng(33.5132, 36.2913); // Default to Damascus if no location

        // This check should be based on mapCtrl.markers.value.isEmpty
        // or homeCtrl.filteredJobs.isEmpty if no location is available for map display
        if (mapCtrl.markers.isEmpty && (homeCtrl.userLat.value == null || homeCtrl.userLng.value == null)) {
          return Center(
            child: Text(
              'لا توجد وظائف متاحة للعرض.',
              style: GoogleFonts.tajawal(color: cs.onSurfaceVariant),
            ),
          );
        }

        return Stack(
          children: [
            // --- Map Layer ---
            FlutterMap(
              mapController: mapCtrl.mapController,
              options: MapOptions(
                initialCenter: initialCenter,
                initialZoom: 12.0,
                maxZoom: 18.0,
                minZoom: 3.0,
                onTap: (_, __) {
                  mapCtrl.popupController.hideAllPopups();
                  mapCtrl.resetMarkerIcons(); // Reset icons and clear selections
                },
              ),
              children: [
                Obx(
                      () => TileLayer(
                    urlTemplate: mapCtrl.isDarkMap.value
                        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                        : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                    subdomains: const ['a', 'b', 'c'],
                    userAgentPackageName: 'com.example.app', // IMPORTANT for FlutterMap
                  ),
                ),

                PopupScope(
                  child: MarkerClusterLayerWidget(
                    options: MarkerClusterLayerOptions(
                      maxClusterRadius: 45,
                      size: const Size(50, 50),
                      alignment: Alignment.center,
                      markers: mapCtrl.markers.value, // Markers list from controller
                      polygonOptions: PolygonOptions(
                          borderColor: cs.primary.withOpacity(0.5),
                          color: cs.primaryContainer.withOpacity(0.2),
                          borderStrokeWidth: 3),
                      popupOptions: PopupOptions(
                        popupController: mapCtrl.popupController,
                        popupBuilder: (ctx, marker) {
                          if (marker.key == const ValueKey('user_marker')) {
                            return const SizedBox.shrink(); // No popup for user marker
                          }
                          // Find the matching job from HomeController's filtered jobs using the marker's key
                          final matchingJob = homeCtrl.filteredJobs.firstWhereOrNull(
                                  (j) => ValueKey(j.id) == marker.key);
                          if (matchingJob == null) return const SizedBox.shrink();

                          return _JobPopup(context, matchingJob, cs, mapCtrl);
                        },
                      ),
                      onClusterTap: (cluster) {
                        mapCtrl.updateMarkerIconsInCluster(cluster.markers);
                      },
                      builder: (ctx, markers) {
                        return Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              color: cs.secondaryContainer, shape: BoxShape.circle),
                          child: Text(markers.length.toString(),
                              style: GoogleFonts.tajawal(
                                  color: cs.onSecondaryContainer,
                                  fontWeight: FontWeight.bold)),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),

            // --- Floating Action Buttons ---
            Positioned(
              bottom: 280, // Adjust position as needed
              right: 16,
              child: FloatingActionButton(
                shape: const CircleBorder(),
                mini: true,
                onPressed: () => mapCtrl.toggleMapStyle(),
                backgroundColor: cs.primary,
                tooltip: 'تبديل مظهر الخريطة',
                child: const Icon(Icons.satellite_alt, color: Colors.white),
              ),
            ),
            Positioned(
              bottom: 220, // Adjust position as needed
              right: 16,
              child: FloatingActionButton(
                shape: const CircleBorder(),
                mini: true,
                onPressed: () => mapCtrl.goToCurrentLocation(),
                backgroundColor: cs.primary,
                tooltip: 'موقعي الحالي',
                child: const Icon(Icons.my_location, color: Colors.white),
              ),
            ),

            // --- Horizontal Floating Job List ---
            Obx(() {
              final List<JobModel> jobsToDisplay = mapCtrl.selectedClusterJobs.isNotEmpty
                  ? mapCtrl.selectedClusterJobs
                  : (mapCtrl.selectedSingleJob.value != null ? [mapCtrl.selectedSingleJob.value!] : []);
              if (jobsToDisplay.isEmpty) {
                return const SizedBox.shrink();
              }
              return Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: 160,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: jobsToDisplay.length,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemBuilder: (ctx, idx) {
                      final job = jobsToDisplay[idx];
                      return _JobHorizontalListItem(context, job, cs, mapCtrl);
                    },
                  ),
                ),
              );
            }),
          ],
        );
      }),
    );
  }

  // --- Widgets for MapScreen ---
  Widget _JobPopup(
      BuildContext context, JobModel job, ColorScheme cs, MapControllerX mapCtrl) {
    return Card(
      color: cs.surfaceVariant,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Get.to(() => JobDetailsScreen(job: job));
        },
        child: Container(
          width: 200,
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                job.title,
                style: GoogleFonts.tajawal(
                    fontSize: 16, fontWeight: FontWeight.bold, color: cs.primary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                job.description,
                style: GoogleFonts.tajawal(fontSize: 13, color: cs.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: cs.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      job.location,
                      style: GoogleFonts.tajawal(fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (job.distanceInKm != null) // Display distance if available
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Row(
                    children: [
                      Icon(Icons.near_me, size: 16, color: cs.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        '${job.distanceInKm!.toStringAsFixed(1)} كم',
                        style: GoogleFonts.tajawal(fontSize: 13),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _JobHorizontalListItem(
      BuildContext context, JobModel job, ColorScheme cs, MapControllerX mapCtrl) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 0),
      color: cs.surface,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Get.to(() => JobDetailsScreen(job: job));
        },
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          padding: const EdgeInsets.all(12),
          child: IntrinsicHeight(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Text(
                    job.createdAt.toIso8601String(),
                    style: GoogleFonts.tajawal(
                        fontSize: 12, fontStyle: FontStyle.italic, color: cs.onSurfaceVariant),
                  ),
                ),
                Text(
                  job.title,
                  style: GoogleFonts.tajawal(fontSize: 16, fontWeight: FontWeight.bold, color: cs.primary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  job.location,
                  style: GoogleFonts.tajawal(fontSize: 14, color: cs.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: cs.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Expanded(
                        child: Text(job.city,
                            style: GoogleFonts.tajawal(fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.work, size: 16, color: cs.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Expanded(
                        child: Text(job.jobType,
                            style: GoogleFonts.tajawal(fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Ensure the firstWhereOrNull extension is defined somewhere accessible
extension IterableExtension<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E element) test) {
    for (var element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }
}