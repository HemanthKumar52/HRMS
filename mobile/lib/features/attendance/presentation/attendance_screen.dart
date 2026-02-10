import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:dio/dio.dart';

import '../../../core/services/biometric_service.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/services/offline_queue_service.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../../shared/providers/work_mode_provider.dart';
import '../data/attendance_model.dart';
import '../providers/attendance_provider.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  bool _isPunching = false;
  LatLng? _currentLocation;
  bool _isInsideGeofence = false;
  final LatLng _officeLocation = const LatLng(12.9669, 80.2459); // Olympia Pinnacle, Thoraipakkam (Approx)
  final MapController _mapController = MapController();
  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = false;
  double _distanceToOffice = 0;
  bool _isSimulated = false;
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    // Delay location updates until map is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startLocationUpdates();
    });
  }

  void _startLocationUpdates() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled. Please enable them.')),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission denied')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are permanently denied. Please enable in Settings.')),
          );
        }
        return;
      }

      // Get initial position with high accuracy
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      if (mounted) {
         setState(() {
            _currentLocation = LatLng(pos.latitude, pos.longitude);
            _checkGeofence();
         });

         // Center map on user's actual location (only if map is ready)
         if (_isMapReady) {
           try {
             _mapController.move(_currentLocation!, 16);
           } catch (e) {
             print('Map controller not ready: $e');
           }
         }

         print('📍 Current Location: ${pos.latitude}, ${pos.longitude}');
         print('🏢 Office Location: ${_officeLocation.latitude}, ${_officeLocation.longitude}');
      }

      // Start listening for location updates
      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5, // Update every 5 meters
        )
      ).listen((Position position) {
        if (_isSimulated) return;
        if (mounted) {
          setState(() {
            _currentLocation = LatLng(position.latitude, position.longitude);
            _checkGeofence();
          });
          print('📍 Location updated: ${position.latitude}, ${position.longitude}');
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location error: ${e.toString()}')),
        );
      }
    }
   }

  void _checkGeofence() {
    if (_currentLocation == null) return;
    final distance = const Distance().as(LengthUnit.Meter, _currentLocation!, _officeLocation);
    setState(() {
      _distanceToOffice = distance;
      _isInsideGeofence = distance <= 200; // 200m Radius
    });
  }

  void _simulateLocation() {
    setState(() {
      _isSimulated = true;
      _currentLocation = _officeLocation;
      _routePoints = []; // Clear route if any
      _checkGeofence();
    });
    if (_isMapReady) {
      try {
        _mapController.move(_officeLocation, 18);
      } catch (e) {
        print('Map controller error: $e');
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('📍 Location simulated at Office')),
    );
  }

  Future<void> _fetchRoute() async {
    if (_currentLocation == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Current location unknown')));
      return;
    }
    
    setState(() => _isLoadingRoute = true);
    
    try {
      final dio = Dio();
      final response = await dio.get(
        'http://router.project-osrm.org/route/v1/driving/${_currentLocation!.longitude},${_currentLocation!.latitude};${_officeLocation.longitude},${_officeLocation.latitude}?overview=full&geometries=geojson'
      );
      
      if (response.statusCode == 200 && response.data['code'] == 'Ok') {
        final routes = response.data['routes'] as List;
        if (routes.isNotEmpty) {
           final geometry = routes[0]['geometry'];
           final coordinates = geometry['coordinates'] as List;
           final points = coordinates.map((coord) => LatLng(coord[1].toDouble(), coord[0].toDouble())).toList();
           
           setState(() {
             _routePoints = points;
           });
           
           if (points.isNotEmpty && _isMapReady) {
             // Calculate bounds
             double minLat = points.first.latitude;
             double maxLat = points.first.latitude;
             double minLng = points.first.longitude;
             double maxLng = points.first.longitude;
             for (var p in points) {
                if (p.latitude < minLat) minLat = p.latitude;
                if (p.latitude > maxLat) maxLat = p.latitude;
                if (p.longitude < minLng) minLng = p.longitude;
                if (p.longitude > maxLng) maxLng = p.longitude;
             }

             final bounds = LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));

             try {
               _mapController.fitCamera(
                 CameraFit.bounds(
                   bounds: bounds,
                   padding: const EdgeInsets.all(50)
                 )
               );
             } catch (e) {
               print('Map controller error: $e');
             }
           }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching route: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoadingRoute = false);
    }
  }

  Future<void> _handlePunch(PunchType punchType, {bool isOD = false}) async {
    final workModeNotifier = ref.read(workModeProvider.notifier);
    final workMode = ref.read(workModeProvider);
    
    String? locationAddress;
    double? capturedLat;
    double? capturedLong;
    
    // For ON_DUTY mode: Capture location and address
    if (workMode == 'ON_DUTY') {
      try {
        // Request location permission if not granted
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Location permission required for On Duty mode'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
            return;
          }
        }
        
        // Get current location with high accuracy
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        
        capturedLat = position.latitude;
        capturedLong = position.longitude;
        
        // Get address from coordinates using geocoding
        try {
          final placemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          );
          
          if (placemarks.isNotEmpty) {
            final place = placemarks.first;
            locationAddress = '${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea} ${place.postalCode}';
          }
        } catch (e) {
          print('Geocoding error: $e');
          locationAddress = 'Lat: ${position.latitude.toStringAsFixed(6)}, Long: ${position.longitude.toStringAsFixed(6)}';
        }
        
        print('📍 ON_DUTY Location captured:');
        print('   Coordinates: $capturedLat, $capturedLong');
        print('   Address: $locationAddress');
        
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to get location: ${e.toString()}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }
    }
    
    // Biometric Security Check (only for OFFICE mode)
    if (workModeNotifier.requiresBiometric) {
      final bioService = ref.read(biometricServiceProvider);
      final authenticated = await bioService.authenticate(reason: 'Authenticate to mark attendance');
      
      if (!authenticated) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Authentication Required'), backgroundColor: AppColors.error),
          );
        }
        return;
      }
    }

    setState(() => _isPunching = true);

    try {
      // Use captured location for ON_DUTY, current location for others
      final lat = workMode == 'ON_DUTY' ? capturedLat : _currentLocation?.latitude;
      final long = workMode == 'ON_DUTY' ? capturedLong : _currentLocation?.longitude;
      
      await ref.read(punchProvider.notifier).punch(
            punchType: punchType,
            latitude: lat,
            longitude: long,
            address: locationAddress, // Send address to backend
            workMode: workMode, // Send work mode
          );

      final result = ref.read(punchProvider).value;

      ref.invalidate(todayStatusProvider);
      ref.invalidate(attendanceSummaryProvider);

      if (mounted) {
        String msg = workMode == 'ON_DUTY' 
            ? '${punchType == PunchType.clockIn ? "Clock In" : "Clock Out"} recorded at: $locationAddress'
            : (punchType == PunchType.clockIn ? 'Clocked In' : 'Clocked Out');
        if (result?.isOffline == true) msg += ' (Offline)';
        
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to record punch'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() => _isPunching = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final todayAsync = ref.watch(todayStatusProvider);
    final isOnline = ref.watch(isOnlineProvider);
    final workMode = ref.watch(workModeProvider);
    final workModeNotifier = ref.read(workModeProvider.notifier);

    // Determine if we should show the map
    final showMap = workMode != 'REMOTE'; // Remote workers don't need map
    final showGeofence = workModeNotifier.requiresGeofence; // Only office mode

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
          // MAP SECTION (conditional based on work mode)
          if (showMap)
            SizedBox(
              height: 350,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _currentLocation ?? _officeLocation,
                      initialZoom: 15,
                      onMapReady: () {
                        setState(() {
                          _isMapReady = true;
                        });
                        // Move to current location once map is ready
                        if (_currentLocation != null) {
                          _mapController.move(_currentLocation!, 16);
                        }
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.kaaspro.hrms',
                      ),
                      // Geofence Circle (only for office mode)
                      if (showGeofence)
                        CircleLayer(
                          circles: [
                            CircleMarker(
                              point: _officeLocation,
                              color: AppColors.primary.withOpacity(0.1),
                              borderColor: AppColors.primary,
                              borderStrokeWidth: 2,
                              useRadiusInMeter: true,
                              radius: 200, // 200m Geofence
                            ),
                          ],
                        ),
                      // Route Line
                      if (_routePoints.isNotEmpty)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _routePoints,
                              color: Colors.blue,
                              strokeWidth: 4.0,
                            ),
                          ],
                        ),
                      // User Marker
                      if (_currentLocation != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _currentLocation!,
                              width: 60,
                              height: 60,
                              child: const Icon(Icons.person_pin_circle, color: Colors.blueAccent, size: 40),
                            ),
                            // Office Marker (only for office mode)
                            if (showGeofence)
                              Marker(
                                point: _officeLocation,
                                width: 80,
                                height: 80,
                                child: const Column(children: [
                                   Icon(Icons.business, color: AppColors.primary, size: 30),
                                   Text("Olympia Pinnacle", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10), overflow: TextOverflow.visible, textAlign: TextAlign.center),
                                ]),
                              )
                          ],
                        ),
                    ],
                  ),
                  // Overlay Status
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 10,
                    left: 16,
                    right: 16,
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  showGeofence 
                                    ? (_isInsideGeofence ? Icons.verified_user : Icons.location_off)
                                    : Icons.location_on,
                                  color: showGeofence
                                    ? (_isInsideGeofence ? Colors.green : Colors.orange)
                                    : Colors.blue,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        showGeofence
                                          ? (_isInsideGeofence 
                                              ? 'You are in Office Zone' 
                                              : 'Outside Office (${(_distanceToOffice / 1000).toStringAsFixed(1)} km away)')
                                          : 'Location: ${workMode ?? 'Field'}',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        showGeofence ? 'Olympia Pinnacle, Thoraipakkam' : 'GPS tracking active',
                                        style: const TextStyle(fontSize: 12, color: Colors.grey)
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            // Directions Button
                            if (showGeofence && !_isInsideGeofence)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Column(
                                    children: [
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: _simulateLocation,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.orange.shade100,
                                            foregroundColor: Colors.orange.shade900,
                                            elevation: 0,
                                          ),
                                          icon: const Icon(Icons.location_on),
                                          label: const Text('Simulate Location (Test)'),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton.icon(
                                           onPressed: _isLoadingRoute ? null : _fetchRoute,
                                           style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.blue,
                                              side: const BorderSide(color: Colors.blue), 
                                           ),
                                           icon: _isLoadingRoute 
                                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) 
                                              : const Icon(Icons.directions, size: 18),
                                           label: Text(_routePoints.isEmpty ? "Show Route on Map" : "Refresh Route"),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // CONTROLS SECTION
          Expanded(
            child: todayAsync.when(
              data: (status) => SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // OFFICE PUNCH CARD
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                             Text(
                                workMode == 'ON_DUTY' ? "On Duty Attendance" : 
                                workMode == 'REMOTE' ? "Remote Attendance" : "Office Attendance",
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
                             ),
                             if (workMode == 'ON_DUTY')
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                                      const SizedBox(width: 8),
                                      Text(
                                        "GPS location will be captured",
                                        style: TextStyle(color: Colors.grey[700], fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                             const SizedBox(height: 16),
                             Row(
                               children: [
                                 Expanded(
                                   child: _buildPunchButton(
                                     context, 
                                     label: "Clock In", 
                                     icon: Icons.login, 
                                     color: AppColors.success, 
                                     // Enable logic based on work mode:
                                     // Office: requires geofence
                                     // Remote/Field/OD: no geofence required
                                     isEnabled: !_isPunching && 
                                       (workModeNotifier.requiresGeofence ? _isInsideGeofence : true) && 
                                       !status.isClockedIn,
                                     onTap: () => _handlePunch(PunchType.clockIn),
                                   ),
                                 ),
                                 const SizedBox(width: 12),
                                 Expanded(
                                   child: _buildPunchButton(
                                     context, 
                                     label: "Clock Out", 
                                     icon: Icons.logout, 
                                     color: AppColors.error, 
                                     isEnabled: !_isPunching && 
                                       (workModeNotifier.requiresGeofence ? _isInsideGeofence : true) && 
                                       status.isClockedIn,
                                     onTap: () => _handlePunch(PunchType.clockOut),
                                   ),
                                 ),
                               ],
                             ),
                             if (workModeNotifier.requiresGeofence && !_isInsideGeofence)
                               Padding(
                                 padding: const EdgeInsets.only(top: 12),
                                 child: Text("Move closer to office to mark attendance.", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                               ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),



                    
                    const SizedBox(height: 24),
                    
                    // Logic Note
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withOpacity(0.2)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, size: 18, color: Colors.blue),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Calculated from First Entry to Last Exit. Breaks are not deducted.",
                              style: TextStyle(fontSize: 12, color: Colors.blue),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    // Stats Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                         _buildStat("Clock In", status.clockInTime?.timeOnly ?? '--:--'),
                         _buildStat("Clock Out", status.clockInTime?.timeOnly ?? '--:--'),
                         _buildStat("Total Hrs", status.totalHours),
                      ],
                    )
                  ],
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text("Error: $e")),
            ),
          ),
        ],
      ),
    ),
  );
  }

  Widget _buildPunchButton(BuildContext context, {required String label, required IconData icon, required Color color, required bool isEnabled, required VoidCallback onTap}) {
    return ElevatedButton.icon(
      onPressed: isEnabled ? onTap : null,
      style: ElevatedButton.styleFrom(
         backgroundColor: color,
         foregroundColor: Colors.white,
         padding: const EdgeInsets.symmetric(vertical: 16),
         disabledBackgroundColor: Colors.grey[300],
         disabledForegroundColor: Colors.grey[500],
      ),
      icon: Icon(icon),
      label: Text(label),
    );
  }
  
  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}
