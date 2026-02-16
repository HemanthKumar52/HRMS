import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:dio/dio.dart';

import '../../../core/services/biometric_service.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/responsive.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/widgets/check_in_type_dialog.dart';
import '../../../core/widgets/face_verification_dialog.dart';
import '../../../shared/providers/work_mode_provider.dart';
import '../../../shared/providers/login_method_provider.dart';
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
  final LatLng _officeLocation = const LatLng(12.9669, 80.2459);
  final MapController _mapController = MapController();
  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = false;
  double _distanceToOffice = 0;
  bool _isSimulated = false;
  bool _isMapReady = false;
  CheckInType? _selectedCheckInType;
  String? _facePhotoPath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startLocationUpdates();
    });
  }

  /// Get button color based on login method
  Color _getButtonColor(LoginMethod loginMethod, bool isClockedIn) {
    if (isClockedIn) {
      // Clock out state - use red tones
      return AppColors.error;
    }

    // Clock in state - color based on login method
    switch (loginMethod) {
      case LoginMethod.biometric:
        return AppColors.biometricLogin; // Green
      case LoginMethod.phone:
        return AppColors.phoneLogin; // Violet
      case LoginMethod.faceId:
        return AppColors.faceIdLogin; // Orange
      case LoginMethod.password:
        return AppColors.passwordLogin; // Blue
    }
  }

  void _startLocationUpdates() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          _showLocationServiceDialog();
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

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
         setState(() {
            _currentLocation = LatLng(pos.latitude, pos.longitude);
            _checkGeofence();
         });

         if (_isMapReady) {
           try {
             _mapController.move(_currentLocation!, 16);
           } catch (e) {
             debugPrint('Map controller not ready: $e');
           }
         }
      }

      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        )
      ).listen((Position position) {
        if (_isSimulated) return;
        if (mounted) {
          setState(() {
            _currentLocation = LatLng(position.latitude, position.longitude);
            _checkGeofence();
          });
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

  /// Show dialog to enable location services
  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.location_off, color: AppColors.warning),
            SizedBox(width: 12),
            Text('Location Required'),
          ],
        ),
        content: const Text(
          'Location services are disabled. Please enable location to mark attendance.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await Geolocator.openLocationSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _checkGeofence() {
    if (_currentLocation == null) return;
    final distance = const Distance().as(LengthUnit.Meter, _currentLocation!, _officeLocation);
    setState(() {
      _distanceToOffice = distance;
      _isInsideGeofence = distance <= 200;
    });
  }

  void _simulateLocation() {
    setState(() {
      _isSimulated = true;
      _currentLocation = _officeLocation;
      _routePoints = [];
      _checkGeofence();
    });
    if (_isMapReady) {
      try {
        _mapController.move(_officeLocation, 18);
      } catch (e) {
        debugPrint('Map controller error: $e');
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Location simulated at Office')),
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
               debugPrint('Map controller error: $e');
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

  /// Handle clock in/out toggle
  Future<void> _handlePunchToggle(bool isClockedIn) async {
    final punchType = isClockedIn ? PunchType.clockOut : PunchType.clockIn;
    final workModeNotifier = ref.read(workModeProvider.notifier);
    final workMode = ref.read(workModeProvider);

    String? locationAddress;
    double? capturedLat;
    double? capturedLong;

    // For mobile check-in (non-office), ask for check-in type
    if (!isClockedIn && workMode != 'OFFICE' && workMode != 'REMOTE') {
      final checkInType = await showCheckInTypeDialog(context);
      if (checkInType == null) {
        return; // User cancelled
      }
      _selectedCheckInType = checkInType;
    }

    // Face verification for clock in (required for all modes)
    if (!isClockedIn) {
      final photoPath = await showFaceVerificationDialog(context);
      if (photoPath == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Face verification required to clock in'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }
      _facePhotoPath = photoPath;
    }

    // Location capture for ON_DUTY and FIELD modes
    if (workMode == 'ON_DUTY' || _selectedCheckInType != null) {
      try {
        // Check if location service is enabled
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          if (mounted) {
            _showLocationServiceDialog();
          }
          return;
        }

        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Location permission required'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
            return;
          }
        }

        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        capturedLat = position.latitude;
        capturedLong = position.longitude;

        // Reverse geocoding for address
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
          debugPrint('Geocoding error: $e');
          locationAddress = 'Lat: ${position.latitude.toStringAsFixed(6)}, Long: ${position.longitude.toStringAsFixed(6)}';
        }

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

    // Biometric check for OFFICE mode
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
      final lat = (workMode == 'ON_DUTY' || _selectedCheckInType != null) ? capturedLat : _currentLocation?.latitude;
      final long = (workMode == 'ON_DUTY' || _selectedCheckInType != null) ? capturedLong : _currentLocation?.longitude;

      await ref.read(punchProvider.notifier).punch(
            punchType: punchType,
            latitude: lat,
            longitude: long,
            address: locationAddress,
            workMode: workMode,
          );

      final result = ref.read(punchProvider).value;

      ref.invalidate(todayStatusProvider);
      ref.invalidate(attendanceSummaryProvider);

      if (mounted) {
        String msg;
        if (_selectedCheckInType != null) {
          msg = '${punchType == PunchType.clockIn ? "Clock In" : "Clock Out"} (${_selectedCheckInType!.displayName}) at: $locationAddress';
        } else if (workMode == 'ON_DUTY') {
          msg = '${punchType == PunchType.clockIn ? "Clock In" : "Clock Out"} recorded at: $locationAddress';
        } else {
          msg = punchType == PunchType.clockIn ? 'Clocked In Successfully' : 'Clocked Out Successfully';
        }
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
        setState(() {
          _isPunching = false;
          _selectedCheckInType = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    final todayAsync = ref.watch(todayStatusProvider);
    final isOnline = ref.watch(isOnlineProvider);
    final workMode = ref.watch(workModeProvider);
    final workModeNotifier = ref.read(workModeProvider.notifier);
    final loginMethod = ref.watch(loginMethodProvider);

    final showMap = workMode != 'REMOTE';
    final showGeofence = workModeNotifier.requiresGeofence;

    // Responsive map height
    final mapHeight = Responsive.value(mobile: 300.0, tablet: 400.0);

    return SafeScaffold(
      appBar: AdaptiveAppBar(
        title: 'Attendance',
      ),
      body: Column(
        children: [
        // MAP SECTION
        if (showMap)
          SizedBox(
            height: mapHeight,
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
                      if (showGeofence)
                        CircleLayer(
                          circles: [
                            CircleMarker(
                              point: _officeLocation,
                              color: AppColors.primary.withOpacity(0.1),
                              borderColor: AppColors.primary,
                              borderStrokeWidth: 2,
                              useRadiusInMeter: true,
                              radius: 200,
                            ),
                          ],
                        ),
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
                      if (_currentLocation != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _currentLocation!,
                              width: 60,
                              height: 60,
                              child: const Icon(Icons.person_pin_circle, color: Colors.blueAccent, size: 40),
                            ),
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
                  // Overlay Status Card
                  Positioned(
                    top: Responsive.value(mobile: 10.0, tablet: 16.0),
                    left: Responsive.horizontalPadding,
                    right: Responsive.horizontalPadding,
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.cardRadius)),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: Responsive.horizontalPadding,
                          vertical: Responsive.value(mobile: 12.0, tablet: 16.0),
                        ),
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
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: Responsive.sp(14),
                                        ),
                                      ),
                                      Text(
                                        showGeofence ? 'Olympia Pinnacle, Thoraipakkam' : 'GPS tracking active',
                                        style: TextStyle(fontSize: Responsive.sp(12), color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
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
              data: (status) {
                final buttonColor = _getButtonColor(loginMethod, status.isClockedIn);
                final buttonText = status.isClockedIn ? 'Clock Out' : 'Clock In';
                final buttonIcon = status.isClockedIn ? Icons.logout : Icons.login;

                return SingleChildScrollView(
                  padding: EdgeInsets.all(Responsive.horizontalPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ATTENDANCE CARD
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.cardRadius)),
                        child: Padding(
                          padding: EdgeInsets.all(Responsive.value(mobile: 16.0, tablet: 24.0)),
                          child: Column(
                            children: [
                               Text(
                                  workMode == 'ON_DUTY' ? "On Duty Attendance" :
                                  workMode == 'REMOTE' ? "Remote Attendance" : "Office Attendance",
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
                               ),

                               // Login method indicator
                               Padding(
                                 padding: EdgeInsets.only(top: Responsive.value(mobile: 8.0, tablet: 12.0)),
                                 child: Row(
                                   mainAxisAlignment: MainAxisAlignment.center,
                                   children: [
                                     Container(
                                       padding: EdgeInsets.symmetric(
                                         horizontal: Responsive.value(mobile: 12.0, tablet: 16.0),
                                         vertical: Responsive.value(mobile: 4.0, tablet: 6.0),
                                       ),
                                       decoration: BoxDecoration(
                                         color: _getButtonColor(loginMethod, false).withOpacity(0.1),
                                         borderRadius: BorderRadius.circular(20),
                                         border: Border.all(
                                           color: _getButtonColor(loginMethod, false).withOpacity(0.3),
                                         ),
                                       ),
                                       child: Row(
                                         mainAxisSize: MainAxisSize.min,
                                         children: [
                                           Icon(
                                             _getLoginMethodIcon(loginMethod),
                                             size: Responsive.sp(14),
                                             color: _getButtonColor(loginMethod, false),
                                           ),
                                           SizedBox(width: Responsive.value(mobile: 6.0, tablet: 8.0)),
                                           Text(
                                             'Logged in via ${loginMethod.displayName}',
                                             style: TextStyle(
                                               fontSize: Responsive.sp(11),
                                               color: _getButtonColor(loginMethod, false),
                                               fontWeight: FontWeight.w500,
                                             ),
                                           ),
                                         ],
                                       ),
                                     ),
                                   ],
                                 ),
                               ),

                               if (workMode == 'ON_DUTY' || workMode != 'OFFICE' && workMode != 'REMOTE')
                                  Padding(
                                    padding: EdgeInsets.only(top: Responsive.value(mobile: 8.0, tablet: 12.0)),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.info_outline, size: Responsive.sp(16), color: Colors.blue),
                                        SizedBox(width: Responsive.value(mobile: 8.0, tablet: 12.0)),
                                        Text(
                                          "GPS location & face verification required",
                                          style: TextStyle(color: Colors.grey[700], fontSize: Responsive.sp(12)),
                                        ),
                                      ],
                                    ),
                                  ),
                               SizedBox(height: Responsive.value(mobile: 20.0, tablet: 28.0)),

                               // SINGLE CLOCK IN/OUT BUTTON
                               SizedBox(
                                 width: double.infinity,
                                 height: Responsive.value(mobile: 56.0, tablet: 64.0),
                                 child: ElevatedButton.icon(
                                   onPressed: _isPunching ||
                                       (workModeNotifier.requiresGeofence && !_isInsideGeofence)
                                       ? null
                                       : () => _handlePunchToggle(status.isClockedIn),
                                   style: ElevatedButton.styleFrom(
                                     backgroundColor: buttonColor,
                                     foregroundColor: Colors.white,
                                     disabledBackgroundColor: Colors.grey[300],
                                     disabledForegroundColor: Colors.grey[500],
                                     shape: RoundedRectangleBorder(
                                       borderRadius: BorderRadius.circular(Responsive.cardRadius),
                                     ),
                                     elevation: 4,
                                   ),
                                   icon: _isPunching
                                       ? SizedBox(
                                           width: Responsive.sp(24),
                                           height: Responsive.sp(24),
                                           child: const CircularProgressIndicator(
                                             strokeWidth: 2,
                                             valueColor: AlwaysStoppedAnimation(Colors.white),
                                           ),
                                         )
                                       : Icon(buttonIcon, size: Responsive.sp(28)),
                                   label: Text(
                                     _isPunching ? 'Processing...' : buttonText,
                                     style: TextStyle(
                                       fontSize: Responsive.sp(18),
                                       fontWeight: FontWeight.bold,
                                     ),
                                   ),
                                 ),
                               ),

                               if (workModeNotifier.requiresGeofence && !_isInsideGeofence)
                                 Padding(
                                   padding: EdgeInsets.only(top: Responsive.value(mobile: 12.0, tablet: 16.0)),
                                   child: Text(
                                     "Move closer to office to mark attendance.",
                                     style: TextStyle(color: Colors.grey[600], fontSize: Responsive.sp(12)),
                                   ),
                                 ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: Responsive.value(mobile: 20.0, tablet: 28.0)),

                      // Logic Note
                      Container(
                        padding: EdgeInsets.all(Responsive.value(mobile: 12.0, tablet: 16.0)),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(Responsive.cardRadius * 0.5),
                          border: Border.all(color: Colors.blue.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: Responsive.sp(18), color: Colors.blue),
                            SizedBox(width: Responsive.value(mobile: 8.0, tablet: 12.0)),
                            Expanded(
                              child: Text(
                                "Face verification required for clock in. Location captured for field work.",
                                style: TextStyle(fontSize: Responsive.sp(12), color: Colors.blue),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: Responsive.value(mobile: 20.0, tablet: 28.0)),

                      // Stats Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                           _buildStat("Clock In", status.clockInTime?.timeOnly ?? '--:--'),
                           _buildStat("Clock Out", status.clockOutTime?.timeOnly ?? '--:--'),
                           _buildStat("Total Hrs", status.totalHours),
                        ],
                      )
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text("Error: $e")),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getLoginMethodIcon(LoginMethod method) {
    switch (method) {
      case LoginMethod.biometric:
        return Icons.fingerprint;
      case LoginMethod.phone:
        return Icons.phone_android;
      case LoginMethod.faceId:
        return Icons.face;
      case LoginMethod.password:
        return Icons.password;
    }
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: Responsive.sp(16),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey,
            fontSize: Responsive.sp(12),
          ),
        ),
      ],
    );
  }
}
