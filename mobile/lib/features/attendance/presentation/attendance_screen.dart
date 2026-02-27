import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../../../core/services/biometric_service.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme_extensions.dart';
import '../../../core/responsive.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/widgets/check_in_type_dialog.dart';
import '../../../core/widgets/face_verification_dialog.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/dynamic_island_notification.dart';
import '../../../shared/providers/work_mode_provider.dart';
import '../../../shared/providers/login_method_provider.dart';
import '../../../shared/providers/clock_in_method_provider.dart';
import '../../../shared/providers/face_photo_provider.dart';
import '../data/attendance_model.dart';
import '../data/face_upload_service.dart';
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
  ClockInMethod? _pendingClockInMethod;

  // Real-time clock
  DateTime _currentDateTime = DateTime.now();
  Timer? _clockTimer;

  // GPS location address
  String _currentAddress = 'Fetching location...';

  // Strict location permission gate
  bool _locationGranted = false;

  @override
  void initState() {
    super.initState();
    // Start real-time clock that ticks every second
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _currentDateTime = DateTime.now();
        });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _enforceLocationPermission();
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
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

  /// Strict location permission enforcement — blocks UI until granted
  Future<void> _enforceLocationPermission() async {
    // 1. Check location services enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    while (!serviceEnabled) {
      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.location_off, color: AppColors.warning),
              SizedBox(width: 12),
              Expanded(child: Text('Location Required')),
            ],
          ),
          content: const Text(
            'Location services must be enabled to use attendance. Please turn on location services.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                await Geolocator.openLocationSettings();
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      // Re-check after user returns from settings
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
    }

    // 2. Check location permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // If still denied, show non-dismissible dialog
    while (permission == LocationPermission.denied) {
      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.location_off, color: AppColors.error),
              SizedBox(width: 12),
              Expanded(child: Text('Permission Required')),
            ],
          ),
          content: const Text(
            'Location permission is required to mark attendance. You cannot proceed without granting location access.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Grant Permission'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      permission = await Geolocator.requestPermission();
    }

    // 3. If permanently denied, direct to app settings
    while (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.location_off, color: AppColors.error),
              SizedBox(width: 12),
              Expanded(child: Text('Permission Denied')),
            ],
          ),
          content: const Text(
            'Location permission is permanently denied. Please enable it from App Settings to continue.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                await Geolocator.openAppSettings();
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Open App Settings'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      permission = await Geolocator.checkPermission();
    }

    // Permission granted — proceed
    if (mounted) {
      setState(() {
        _locationGranted = true;
      });
      _startLocationUpdates();
    }
  }

  void _startLocationUpdates() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
         setState(() {
            _currentLocation = LatLng(pos.latitude, pos.longitude);
            _checkGeofence();
         });

         // Reverse geocode to get user's actual address
         _reverseGeocodeLocation(pos.latitude, pos.longitude);

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
          distanceFilter: 10,
        )
      ).listen((Position position) {
        if (_isSimulated) return;
        if (mounted) {
          setState(() {
            _currentLocation = LatLng(position.latitude, position.longitude);
            _checkGeofence();
          });
          _reverseGeocodeLocation(position.latitude, position.longitude);
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

  /// Reverse geocode GPS coordinates to get a human-readable address
  Future<void> _reverseGeocodeLocation(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks.first;
        final parts = <String>[];
        if (place.street != null && place.street!.isNotEmpty) parts.add(place.street!);
        if (place.subLocality != null && place.subLocality!.isNotEmpty) parts.add(place.subLocality!);
        if (place.locality != null && place.locality!.isNotEmpty) parts.add(place.locality!);
        setState(() {
          _currentAddress = parts.isNotEmpty
              ? parts.join(', ')
              : 'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentAddress = 'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}';
        });
      }
    }
  }

  void _checkGeofence() {
    if (_currentLocation == null) return;
    final distance = const Distance().as(LengthUnit.Meter, _currentLocation!, _officeLocation);
    final wasInside = _isInsideGeofence;
    setState(() {
      _distanceToOffice = distance;
      _isInsideGeofence = distance <= 20;
    });

    // Show DynamicIsland alert when user leaves the geofence zone
    if (wasInside && !_isInsideGeofence && mounted) {
      DynamicIslandManager().show(
        context,
        message: 'You are ${distance.toStringAsFixed(0)}m from office',
        isError: true,
      );
    }
    // Show DynamicIsland when user enters the geofence zone
    if (!wasInside && _isInsideGeofence && mounted) {
      DynamicIslandManager().show(
        context,
        message: 'You are within office range',
      );
    }
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
    String? verifiedEmployeeName;
    if (!isClockedIn) {
      final verificationResult = await showFaceVerificationDialog(context);
      if (verificationResult == null) {
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
      verifiedEmployeeName = verificationResult.employeeName;
      // Store face photo path in provider for avatar display
      ref.read(facePhotoProvider.notifier).state = verificationResult.photoPath;
      // Upload face photo to backend (non-blocking)
      if (verificationResult.photoPath != null) {
        ref.read(faceUploadServiceProvider).uploadFacePhoto(verificationResult.photoPath!);
      }
    }

    // Location capture — fresh GPS for ON_DUTY/FIELD, use tracked location for others
    if (workMode == 'ON_DUTY' || _selectedCheckInType != null) {
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        capturedLat = position.latitude;
        capturedLong = position.longitude;

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

    // Method-locked attendance for OFFICE mode
    if (workModeNotifier.requiresBiometric) {
      final clockInMethod = ref.read(clockInMethodProvider);

      if (isClockedIn) {
        // Clock OUT: enforce same method used for clock in
        if (clockInMethod == ClockInMethod.biometric) {
          final bioService = ref.read(biometricServiceProvider);
          final authenticated = await bioService.authenticate(
              reason: 'Authenticate with biometric to clock out');
          if (!authenticated) {
            if (mounted) {
              DynamicIslandManager().show(context,
                  message: 'You must clock out using biometric',
                  isError: true);
            }
            return;
          }
        }
        // If clockInMethod was 'app', allow normal app-based clock out
      } else {
        // Clock IN: try biometric first, fallback to app
        final bioService = ref.read(biometricServiceProvider);
        final authenticated = await bioService.authenticate(
            reason: 'Authenticate to mark attendance');

        if (authenticated) {
          // Will save method after successful punch
          _pendingClockInMethod = ClockInMethod.biometric;
        } else {
          // Biometric failed/cancelled, proceed with app-based clock in
          _pendingClockInMethod = ClockInMethod.app;
        }
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

      // Save or clear clock-in method for method-locked attendance
      if (punchType == PunchType.clockIn && _pendingClockInMethod != null) {
        await ref
            .read(clockInMethodProvider.notifier)
            .setMethod(_pendingClockInMethod!);
        _pendingClockInMethod = null;
      } else if (punchType == PunchType.clockOut) {
        await ref.read(clockInMethodProvider.notifier).clear();
        // Clear face photo — avatar reverts to initials
        ref.read(facePhotoProvider.notifier).state = null;
      }

      if (mounted) {
        String msg;
        if (punchType == PunchType.clockIn && verifiedEmployeeName != null) {
          final name = verifiedEmployeeName[0].toUpperCase() + verifiedEmployeeName.substring(1);
          msg = 'Welcome $name! Clocked In Successfully';
        } else if (_selectedCheckInType != null) {
          msg = '${punchType == PunchType.clockIn ? "Clock In" : "Clock Out"} (${_selectedCheckInType!.displayName}) at: $locationAddress';
        } else if (workMode == 'ON_DUTY') {
          msg = '${punchType == PunchType.clockIn ? "Clock In" : "Clock Out"} recorded at: $locationAddress';
        } else {
          msg = punchType == PunchType.clockIn ? 'Clocked In Successfully' : 'Clocked Out Successfully';
        }
        if (result?.isOffline == true) msg += ' (Offline)';

        DynamicIslandManager().show(context, message: msg);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        DynamicIslandManager().show(context, message: 'Failed to record attendance', isError: true);
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

  String _computeElapsed(DateTime clockIn) {
    final elapsed = _currentDateTime.difference(clockIn);
    final h = elapsed.inHours;
    final m = elapsed.inMinutes % 60;
    final s = elapsed.inSeconds % 60;
    return '${h}h ${m}m ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    final todayAsync = ref.watch(todayStatusProvider);
    final isOnline = ref.watch(isOnlineProvider);
    final workMode = ref.watch(workModeProvider);
    final workModeNotifier = ref.read(workModeProvider.notifier);
    final loginMethod = ref.watch(loginMethodProvider);

    final showMap = true; // Always show map for location verification
    final showGeofence = workModeNotifier.requiresGeofence;

    // Responsive map height
    final mapHeight = Responsive.value(mobile: 220.0, tablet: 300.0);

    // Block UI if location permission not yet granted
    if (!_locationGranted) {
      return SafeScaffold(
        appBar: AdaptiveAppBar(
          title: 'Attendance',
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_off, size: 80, color: AppColors.warning),
                const SizedBox(height: 24),
                Text(
                  'Location Permission Required',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Location access is mandatory to mark attendance. Please grant location permission to continue.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: context.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _enforceLocationPermission,
                  icon: const Icon(Icons.location_on),
                  label: const Text('Grant Permission'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SafeScaffold(
      appBar: AdaptiveAppBar(
        title: 'Attendance',
      ),
      body: SingleChildScrollView(
        child: Column(
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
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderColor: AppColors.primary,
                                borderStrokeWidth: 2,
                                useRadiusInMeter: true,
                                radius: 20,
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
                                child: const Icon(Icons.location_on, color: Colors.red, size: 40),
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
                    // Route / simulate buttons overlay
                    if (showGeofence && !_isInsideGeofence)
                      Positioned(
                        top: Responsive.value(mobile: 10.0, tablet: 16.0),
                        right: Responsive.horizontalPadding,
                        child: Column(
                          children: [
                            _buildMapActionButton(
                              icon: Icons.location_on,
                              color: Colors.orange,
                              onTap: _simulateLocation,
                              tooltip: 'Simulate',
                            ),
                            const SizedBox(height: 8),
                            _buildMapActionButton(
                              icon: _isLoadingRoute ? Icons.hourglass_top : Icons.directions,
                              color: Colors.blue,
                              onTap: _isLoadingRoute ? null : _fetchRoute,
                              tooltip: 'Route',
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

            // REAL-TIME CLOCK + LOCATION BANNER
            if (showMap)
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.horizontalPadding,
                  vertical: Responsive.value(mobile: 10.0, tablet: 14.0),
                ),
                decoration: BoxDecoration(
                  color: showGeofence
                      ? (_isInsideGeofence ? const Color(0xFF1B5E20) : Colors.orange.shade800)
                      : Colors.blue.shade700,
                ),
                child: Column(
                  children: [
                    // Real-time date & time
                    Row(
                      children: [
                        Icon(Icons.access_time_filled, color: Colors.white, size: Responsive.sp(16)),
                        SizedBox(width: Responsive.value(mobile: 8.0, tablet: 12.0)),
                        Text(
                          DateFormat('hh:mm:ss a').format(_currentDateTime),
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: Responsive.sp(14),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('EEE, dd MMM yyyy').format(_currentDateTime),
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: Responsive.sp(12),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: Responsive.value(mobile: 6.0, tablet: 8.0)),
                    // GPS location address
                    Row(
                      children: [
                        Icon(
                          showGeofence
                              ? (_isInsideGeofence ? Icons.verified_user : Icons.location_off)
                              : Icons.location_on,
                          color: Colors.white,
                          size: Responsive.sp(16),
                        ),
                        SizedBox(width: Responsive.value(mobile: 8.0, tablet: 12.0)),
                        Expanded(
                          child: Text(
                            showGeofence
                                ? (_isInsideGeofence
                                    ? 'Verified: $_currentAddress'
                                    : 'Outside Office (${(_distanceToOffice / 1000).toStringAsFixed(1)} km) - $_currentAddress')
                                : _currentAddress,
                            style: GoogleFonts.poppins(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: Responsive.sp(11),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms),

            // CLOCK IN/OUT SECTION
            todayAsync.when(
              data: (status) {
                final isClockedIn = status.isClockedIn;

                return Padding(
                  padding: EdgeInsets.all(Responsive.horizontalPadding),
                  child: Column(
                    children: [
                      // Timer Card with glass effect
                      GlassCard(
                        blur: 15,
                        opacity: 0.15,
                        borderRadius: Responsive.cardRadius,
                        padding: EdgeInsets.symmetric(
                          horizontal: Responsive.horizontalPadding,
                          vertical: Responsive.value(mobile: 28.0, tablet: 36.0),
                        ),
                        child: Column(
                          children: [
                            // Total hours - live display when clocked in
                            Text(
                              isClockedIn && status.clockInTime != null
                                  ? _computeElapsed(status.clockInTime!)
                                  : status.totalHours,
                              style: GoogleFonts.poppins(
                                fontSize: Responsive.sp(48),
                                fontWeight: FontWeight.bold,
                                color: context.textPrimary,
                              ),
                            ).animate().fadeIn(delay: 300.ms),
                            const SizedBox(height: 4),
                            Text(
                              isClockedIn ? 'Clocked In' : 'Not Clocked In',
                              style: GoogleFonts.poppins(
                                fontSize: Responsive.sp(14),
                                color: isClockedIn ? AppColors.success : context.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: Responsive.value(mobile: 28.0, tablet: 36.0)),

                            // Circular Clock In/Out Button
                            GestureDetector(
                              onTap: _isPunching ||
                                  (workModeNotifier.requiresGeofence && !_isInsideGeofence)
                                  ? null
                                  : () => _handlePunchToggle(isClockedIn),
                              child: Container(
                                width: Responsive.value(mobile: 130.0, tablet: 160.0),
                                height: Responsive.value(mobile: 130.0, tablet: 160.0),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: isClockedIn
                                        ? [const Color(0xFFB71C1C), const Color(0xFFE53935)]
                                        : [const Color(0xFF1B3A4B), const Color(0xFF1B8A6B)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isClockedIn ? Colors.red : const Color(0xFF1B8A6B)).withValues(alpha: 0.4),
                                      blurRadius: 24,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: _isPunching
                                    ? const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                          valueColor: AlwaysStoppedAnimation(Colors.white),
                                        ),
                                      )
                                    : Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            isClockedIn ? Icons.logout : Icons.login,
                                            color: Colors.white,
                                            size: Responsive.sp(36),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            isClockedIn ? 'CLOCK OUT' : 'CLOCK IN',
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontSize: Responsive.sp(13),
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ).animate().scale(delay: 400.ms, duration: 500.ms, curve: Curves.easeOutBack),

                            if (workModeNotifier.requiresGeofence && !_isInsideGeofence)
                              Padding(
                                padding: EdgeInsets.only(top: Responsive.value(mobile: 12.0, tablet: 16.0)),
                                child: Text(
                                  "Move closer to office to mark attendance",
                                  style: GoogleFonts.poppins(
                                    color: AppColors.warning,
                                    fontSize: Responsive.sp(12),
                                  ),
                                ),
                              ),

                            SizedBox(height: Responsive.value(mobile: 20.0, tablet: 28.0)),

                            // Biometric sync indicator
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _getLoginMethodIcon(loginMethod),
                                  size: Responsive.sp(16),
                                  color: context.textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Synced with ${loginMethod.displayName}',
                                  style: GoogleFonts.poppins(
                                    fontSize: Responsive.sp(12),
                                    color: context.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

                      SizedBox(height: Responsive.value(mobile: 20.0, tablet: 28.0)),

                      // Inline Work Mode Selector
                      GlassCard(
                        blur: 10,
                        opacity: 0.12,
                        borderRadius: Responsive.cardRadius,
                        padding: EdgeInsets.all(Responsive.value(mobile: 12.0, tablet: 16.0)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Work Mode',
                              style: GoogleFonts.poppins(
                                fontSize: Responsive.sp(12),
                                fontWeight: FontWeight.w600,
                                color: context.textSecondary,
                              ),
                            ),
                            SizedBox(height: Responsive.value(mobile: 8.0, tablet: 10.0)),
                            Row(
                              children: [
                                _buildWorkModeChip('OFFICE', 'Office', Icons.business, Colors.blue, workMode),
                                const SizedBox(width: 6),
                                _buildWorkModeChip('REMOTE', 'Remote', Icons.home, Colors.green, workMode),
                                const SizedBox(width: 6),
                                _buildWorkModeChip('ON_DUTY', 'OD', Icons.directions_car, Colors.orange, workMode),
                                const SizedBox(width: 6),
                                _buildWorkModeChip('HYBRID', 'Hybrid', Icons.swap_horiz, Colors.purple, workMode),
                              ],
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),

                      SizedBox(height: Responsive.value(mobile: 16.0, tablet: 20.0)),

                      // Stats Row with glass cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Clock In',
                              status.clockInTime?.timeOnly ?? '--:--',
                              Icons.login,
                              AppColors.success,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Clock Out',
                              status.clockOutTime?.timeOnly ?? '--:--',
                              Icons.logout,
                              AppColors.error,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Total Hrs',
                              status.totalHours,
                              Icons.access_time_filled,
                              AppColors.primary,
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),

                      SizedBox(height: Responsive.value(mobile: 24.0, tablet: 32.0)),

                      // Attendance History Header with Week/Month Toggle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'History',
                            style: GoogleFonts.poppins(
                              fontSize: Responsive.sp(18),
                              fontWeight: FontWeight.w600,
                              color: context.textPrimary,
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.grey100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildPeriodToggle('week', 'Week'),
                                _buildPeriodToggle('month', 'Month'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: Responsive.value(mobile: 12.0, tablet: 16.0)),

                      // Real attendance history from provider
                      _buildAttendanceHistorySection(),

                      // Bottom padding for nav bar
                      SizedBox(height: Responsive.value(mobile: 80.0, tablet: 100.0)),
                    ],
                  ),
                );
              },
              loading: () => SizedBox(
                height: 300,
                child: const Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SizedBox(
                height: 300,
                child: Center(child: Text("Error: $e")),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapActionButton({
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
    required String tooltip,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 20),
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

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return GlassCard(
      blur: 10,
      opacity: 0.15,
      borderRadius: Responsive.cardRadius,
      padding: EdgeInsets.all(Responsive.value(mobile: 12.0, tablet: 16.0)),
      child: Column(
        children: [
          Icon(icon, color: color, size: Responsive.sp(20)),
          SizedBox(height: Responsive.value(mobile: 8.0, tablet: 10.0)),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: Responsive.sp(16),
              color: context.textPrimary,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: context.textSecondary,
              fontSize: Responsive.sp(11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodToggle(String period, String label) {
    final selectedPeriod = ref.watch(selectedPeriodProvider);
    final isSelected = selectedPeriod == period;
    return GestureDetector(
      onTap: () => ref.read(selectedPeriodProvider.notifier).state = period,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: Responsive.sp(12),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? Colors.white : AppColors.grey600,
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceHistorySection() {
    final selectedPeriod = ref.watch(selectedPeriodProvider);
    final summaryAsync = ref.watch(attendanceSummaryProvider(selectedPeriod));

    return summaryAsync.when(
      data: (summary) {
        if (summary.dailySummary.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No attendance records for this period',
                style: GoogleFonts.poppins(color: AppColors.grey500, fontSize: 13),
              ),
            ),
          );
        }
        return Column(
          children: summary.dailySummary.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final hasClockIn = item.clockIn != null;
            final hasClockOut = item.clockOut != null;
            final clockInStr = hasClockIn ? DateFormat('hh:mm a').format(item.clockIn!) : '--:--';
            final clockOutStr = hasClockOut ? DateFormat('hh:mm a').format(item.clockOut!) : '--:--';
            final isToday = item.date == DateFormat('yyyy-MM-dd').format(DateTime.now());
            final isLeave = !hasClockIn && !hasClockOut && item.totalMinutes == 0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassCard(
                blur: 10,
                opacity: 0.12,
                borderRadius: Responsive.cardRadius,
                padding: EdgeInsets.all(Responsive.value(mobile: 14.0, tablet: 18.0)),
                child: Row(
                  children: [
                    SizedBox(
                      width: Responsive.value(mobile: 50.0, tablet: 60.0),
                      child: Text(
                        isToday ? 'Today' : DateFormat('dd MMM').format(DateTime.parse(item.date)),
                        style: GoogleFonts.poppins(
                          fontSize: Responsive.sp(12),
                          fontWeight: FontWeight.w600,
                          color: context.textSecondary,
                        ),
                      ),
                    ),
                    SizedBox(width: Responsive.value(mobile: 12.0, tablet: 16.0)),
                    Expanded(
                      child: Row(
                        children: [
                          _buildTimeChip(clockInStr, Icons.login, AppColors.success),
                          const SizedBox(width: 8),
                          _buildTimeChip(clockOutStr, Icons.logout, AppColors.error),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isLeave
                            ? AppColors.warning.withOpacity(0.1)
                            : isToday && !hasClockOut
                                ? AppColors.success.withOpacity(0.1)
                                : AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isLeave ? 'Leave' : item.totalHours,
                        style: GoogleFonts.poppins(
                          fontSize: Responsive.sp(11),
                          fontWeight: FontWeight.w600,
                          color: isLeave
                              ? AppColors.warning
                              : isToday && !hasClockOut
                                  ? AppColors.success
                                  : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: (600 + index * 80).ms).slideX(begin: 0.1);
          }).toList(),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text('Error loading history: $e', style: GoogleFonts.poppins(color: AppColors.error, fontSize: 13)),
        ),
      ),
    );
  }

  Widget _buildTimeChip(String time, IconData icon, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          time,
          style: GoogleFonts.poppins(
            fontSize: Responsive.sp(11),
            color: context.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildWorkModeChip(String mode, String label, IconData icon, Color color, String? currentMode) {
    final isSelected = currentMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          ref.read(workModeProvider.notifier).setWorkMode(mode);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            vertical: Responsive.value(mobile: 8.0, tablet: 10.0),
          ),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : AppColors.grey300,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: Responsive.sp(16), color: isSelected ? color : AppColors.grey500),
              SizedBox(height: Responsive.value(mobile: 4.0, tablet: 6.0)),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: Responsive.sp(10),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? color : AppColors.grey600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
