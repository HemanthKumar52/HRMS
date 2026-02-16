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

import '../../../core/services/biometric_service.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/responsive.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/widgets/check_in_type_dialog.dart';
import '../../../core/widgets/face_verification_dialog.dart';
import '../../../core/widgets/glass_card.dart';
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
    final mapHeight = Responsive.value(mobile: 220.0, tablet: 300.0);

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

            // LOCATION VERIFIED BANNER
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
                child: Row(
                  children: [
                    Icon(
                      showGeofence
                          ? (_isInsideGeofence ? Icons.verified_user : Icons.location_off)
                          : Icons.location_on,
                      color: Colors.white,
                      size: Responsive.sp(18),
                    ),
                    SizedBox(width: Responsive.value(mobile: 10.0, tablet: 14.0)),
                    Expanded(
                      child: Text(
                        showGeofence
                            ? (_isInsideGeofence
                                ? 'Location Verified: Olympia Pinnacle'
                                : 'Outside Office (${(_distanceToOffice / 1000).toStringAsFixed(1)} km away)')
                            : 'Location: ${workMode ?? 'Field'} - GPS Active',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: Responsive.sp(13),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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
                            // Total hours - large display
                            Text(
                              status.totalHours,
                              style: GoogleFonts.poppins(
                                fontSize: Responsive.sp(48),
                                fontWeight: FontWeight.bold,
                                color: AppColors.grey900,
                              ),
                            ).animate().fadeIn(delay: 300.ms),
                            const SizedBox(height: 4),
                            Text(
                              isClockedIn ? 'Clocked In' : 'Not Clocked In',
                              style: GoogleFonts.poppins(
                                fontSize: Responsive.sp(14),
                                color: isClockedIn ? AppColors.success : AppColors.grey500,
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
                                      color: (isClockedIn ? Colors.red : const Color(0xFF1B8A6B)).withOpacity(0.4),
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
                                  color: AppColors.grey500,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Synced with ${loginMethod.displayName}',
                                  style: GoogleFonts.poppins(
                                    fontSize: Responsive.sp(12),
                                    color: AppColors.grey500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

                      SizedBox(height: Responsive.value(mobile: 20.0, tablet: 28.0)),

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

                      // Attendance History
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent History',
                            style: GoogleFonts.poppins(
                              fontSize: Responsive.sp(18),
                              fontWeight: FontWeight.w600,
                              color: AppColors.grey900,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: Responsive.value(mobile: 12.0, tablet: 16.0)),

                      // Mock attendance history
                      ..._buildAttendanceHistory(),

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
              color: Colors.black.withOpacity(0.15),
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
              color: AppColors.grey900,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: AppColors.grey500,
              fontSize: Responsive.sp(11),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAttendanceHistory() {
    final mockHistory = [
      {'date': 'Today', 'in': '09:15 AM', 'out': '--:--', 'hours': '0h 0m', 'status': 'Active'},
      {'date': 'Yesterday', 'in': '09:02 AM', 'out': '06:30 PM', 'hours': '9h 28m', 'status': 'Present'},
      {'date': '14 Feb', 'in': '08:55 AM', 'out': '06:15 PM', 'hours': '9h 20m', 'status': 'Present'},
      {'date': '13 Feb', 'in': '--:--', 'out': '--:--', 'hours': '0h 0m', 'status': 'Leave'},
      {'date': '12 Feb', 'in': '09:30 AM', 'out': '07:00 PM', 'hours': '9h 30m', 'status': 'Present'},
    ];

    return mockHistory.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final isLeave = item['status'] == 'Leave';
      final isActive = item['status'] == 'Active';

      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GlassCard(
          blur: 10,
          opacity: 0.12,
          borderRadius: Responsive.cardRadius,
          padding: EdgeInsets.all(Responsive.value(mobile: 14.0, tablet: 18.0)),
          child: Row(
            children: [
              Container(
                width: Responsive.value(mobile: 50.0, tablet: 60.0),
                child: Text(
                  item['date']!,
                  style: GoogleFonts.poppins(
                    fontSize: Responsive.sp(12),
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey700,
                  ),
                ),
              ),
              SizedBox(width: Responsive.value(mobile: 12.0, tablet: 16.0)),
              Expanded(
                child: Row(
                  children: [
                    _buildTimeChip(item['in']!, Icons.login, AppColors.success),
                    const SizedBox(width: 8),
                    _buildTimeChip(item['out']!, Icons.logout, AppColors.error),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isLeave
                      ? AppColors.warning.withOpacity(0.1)
                      : isActive
                          ? AppColors.success.withOpacity(0.1)
                          : AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isLeave ? 'Leave' : isActive ? item['hours']! : item['hours']!,
                  style: GoogleFonts.poppins(
                    fontSize: Responsive.sp(11),
                    fontWeight: FontWeight.w600,
                    color: isLeave
                        ? AppColors.warning
                        : isActive
                            ? AppColors.success
                            : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(delay: (600 + index * 80).ms).slideX(begin: 0.1);
    }).toList();
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
            color: AppColors.grey600,
          ),
        ),
      ],
    );
  }
}
