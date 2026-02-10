import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme/app_colors.dart';

class EmployeeAttendanceDashboard extends StatefulWidget {
  const EmployeeAttendanceDashboard({super.key});

  @override
  State<EmployeeAttendanceDashboard> createState() => _EmployeeAttendanceDashboardState();
}

class _EmployeeAttendanceDashboardState extends State<EmployeeAttendanceDashboard> {
  String _workMode = 'Work from Office'; 
  bool _isClockedIn = false;
  bool _isPendingApproval = false;
  bool _isSyncing = false;
  bool _geoFenceValidated = false;
  
  // Coordinates for "Olympia Pinnacle" (Approx Chennai OMR/Guindy)
  final LatLng _companyLocation = const LatLng(13.0067, 80.2206); // Guindy approx
  final LatLng _userLocation = const LatLng(13.0065, 80.2208); // Near company
  
  String _filter = 'Day'; 

  @override
  void initState() {
    super.initState();
    _checkLocation();
  }

  void _checkLocation() async {
    // Mock Geofencing logic
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _geoFenceValidated = true;
      });
      _showDynamicNotification("Location Verified: You are at Olympia Pinnacle", isSuccess: true);
    }
  }

  void _showDynamicNotification(String message, {bool isSuccess = true}) {
    // Determine the OverlayState
    final overlay = Overlay.of(context);
    
    late OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 50, // Top area like dynamic island
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(isSuccess ? Icons.check_circle : Icons.info, color: isSuccess ? Colors.green : Colors.amber, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack).fadeIn(),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  void _handleClockAction() async {
    if (_workMode == 'Work from Office' && !_geoFenceValidated) {
      _showDynamicNotification("Not at Office Location!", isSuccess: false);
      return;
    }

    setState(() {
      _isSyncing = true;
    });

    // Simulated API delay
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        _isSyncing = false;
        if (!_isClockedIn) {
          // Clocking In
          _isClockedIn = true;
          // If Office/Field, usually triggers approval, but for demo let's just clock in
          _showDynamicNotification("Clocked In Successfully at ${DateTime.now().hour}:${DateTime.now().minute}");
        } else {
          // Clocking Out
          _isClockedIn = false;
          _showDynamicNotification("Clocked Out Successfully. Worked 04h 23m today.");
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Work Mode Selector
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppColors.grey200),
          ),
          child: Row(
            children: [
              _buildModeBtn('Work from Office', Icons.business),
              _buildModeBtn('Work from Home', Icons.home_work_outlined),
              _buildModeBtn('Field Visit', Icons.place_outlined),
            ],
          ),
        ),

        // Geofencing Map (Only if Office)
        if (_workMode == 'Work from Office')
          Container(
            height: 150,
            margin: const EdgeInsets.only(bottom: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  FlutterMap(
                    options: MapOptions(
                      initialCenter: _companyLocation,
                      initialZoom: 16.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.kaaspro.hrms',
                      ),
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: _companyLocation,
                            color: Colors.blue.withOpacity(0.3),
                            borderStrokeWidth: 2,
                            borderColor: Colors.blue,
                            radius: 100, // 100m radius
                          ),
                        ],
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _userLocation,
                            width: 80,
                            height: 80,
                            child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Positioned(
                    bottom: 10, left: 10, right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                      ),
                      child: Row(
                        children: [
                          Icon(_geoFenceValidated ? Icons.verified : Icons.sync, 
                               size: 16, color: _geoFenceValidated ? Colors.green : Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _geoFenceValidated ? 'Location Verified: Olympia Pinnacle' : 'Verifying Location...',
                              style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),

        // Main Clock In/Out Card
        Card(
          elevation: 4,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                if (_isPendingApproval) ...[
                   Container(
                     padding: const EdgeInsets.all(16),
                     decoration: BoxDecoration(
                       color: Colors.orange.withOpacity(0.1),
                       shape: BoxShape.circle,
                     ),
                     child: const Icon(Icons.hourglass_top, size: 40, color: Colors.orange),
                   ),
                   const SizedBox(height: 16),
                   Text(
                    'Approval Pending', 
                    style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange),
                  ),
                   Text(
                    'Request sent to Manager',
                    style: GoogleFonts.poppins(fontSize: 14, color: AppColors.grey500),
                  ),
                ] else ...[
                  Text(
                    _isClockedIn ? '04h 23m' : '00h 00m', 
                    style: GoogleFonts.poppins(fontSize: 48, fontWeight: FontWeight.bold, color: AppColors.grey900),
                  ),
                   Text(
                    _isClockedIn ? 'Working Since 09:00 AM' : 'Not Clocked In',
                    style: GoogleFonts.poppins(fontSize: 14, color: AppColors.grey500),
                  ),
                  const SizedBox(height: 32),
                  
                  // Big Button
                  GestureDetector(
                    onTap: _isSyncing ? null : _handleClockAction,
                    child: Container(
                      height: 180, width: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: _isClockedIn 
                              ? [const Color(0xFFC62828), const Color(0xFFD32F2F)] 
                              : [AppColors.primary, const Color(0xFF2E7D32)], 
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                           BoxShadow(
                             color: (_isClockedIn ? Colors.red : Colors.green).withOpacity(0.4),
                             blurRadius: 20,
                             offset: const Offset(0, 10),
                           )
                        ]
                      ),
                      child: Center(
                        child: _isSyncing 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(_isClockedIn ? Icons.logout : Icons.login, size: 48, color: Colors.white),
                              const SizedBox(height: 8),
                              Text(_isClockedIn ? 'CLOCK OUT' : 'CLOCK IN', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2)),
                            ],
                          ),
                      ),
                    ),
                  ),
                ],
                
                const SizedBox(height: 24),
                if (_workMode == 'Work from Office' && !_isPendingApproval)
                  Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       const Icon(Icons.fingerprint, size: 16, color: AppColors.grey500),
                       const SizedBox(width: 8),
                       Text('Synced with Biometric', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.grey500)),
                     ],
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),
        
        // Attendance History with Filters
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: AppColors.grey200)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Attendance History', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
                    // Filter Toggles
                    Container(
                      decoration: BoxDecoration(color: AppColors.grey100, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                           _buildFilterBtn('Day'),
                           _buildFilterBtn('Week'),
                           _buildFilterBtn('Month'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildHistoryItem('Today', '09:00 AM', 'In Progress', 'Office', true),
                _buildHistoryItem('Yesterday', '09:15 AM', '06:15 PM', 'Office', false),
                _buildHistoryItem('Mon, 3 Feb', '08:55 AM', '06:00 PM', 'Home', false),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 200.ms),
      ],
    );
  }

  Widget _buildModeBtn(String mode, IconData icon) {
    final isSelected = _workMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _workMode = mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
             children: [
               Icon(icon, color: isSelected ? Colors.white : AppColors.grey500, size: 20),
               const SizedBox(height: 4),
               Text(mode == 'Work from Home' ? 'WFH' : (mode == 'Work from Office' ? 'Office' : 'Field'), 
                 style: GoogleFonts.poppins(fontSize: 10, color: isSelected ? Colors.white : AppColors.grey600, fontWeight: FontWeight.w500)),
             ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildFilterBtn(String text) {
     final isSelected = _filter == text;
     return GestureDetector(
       onTap: () => setState(() => _filter = text),
       child: Container(
         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
         decoration: BoxDecoration(
           color: isSelected ? Colors.white : Colors.transparent,
           borderRadius: BorderRadius.circular(6),
           boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2)] : [],
         ),
         child: Text(text, style: GoogleFonts.poppins(fontSize: 12, color: isSelected ? Colors.black : AppColors.grey500, fontWeight: FontWeight.w500)),
       ),
     );
  }

  Widget _buildHistoryItem(String day, String inTime, String outTime, String location, bool isActive) {
     return Container(
       margin: const EdgeInsets.only(bottom: 12),
       padding: const EdgeInsets.all(12),
       decoration: BoxDecoration(
         color: Colors.white,
         border: Border.all(color: AppColors.grey100),
         borderRadius: BorderRadius.circular(12),
       ),
       child: Row(
         children: [
           Container(
             padding: const EdgeInsets.all(10),
             decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
             child: Icon(location == 'Office' ? Icons.business : Icons.home, color: AppColors.primary, size: 18),
           ),
           const SizedBox(width: 12),
           Expanded(
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(day, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                 Text(location, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.grey500)),
               ],
             ),
           ),
           Column(
             crossAxisAlignment: CrossAxisAlignment.end,
             children: [
               Text(isActive ? 'Clocked In' : '8h 30m', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: isActive ? Colors.green : Colors.black87)),
               Text('$inTime - $outTime', style: GoogleFonts.poppins(fontSize: 10, color: AppColors.grey500)),
             ],
           ),
         ],
       ),
     );
  }
}
