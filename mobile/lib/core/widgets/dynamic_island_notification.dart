import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:collection'; // Add queue support

class DynamicIslandManager {
  static final DynamicIslandManager _instance = DynamicIslandManager._internal();
  factory DynamicIslandManager() => _instance;
  DynamicIslandManager._internal();

  OverlayEntry? _overlayEntry;
  Timer? _timer;
  final Queue<_NotificationRequest> _queue = Queue(); // Queue for alerts
  bool _isShowing = false;

  void show(BuildContext context, {required String message, bool isError = false}) {
    // Add to queue
    _queue.add(_NotificationRequest(context, message, isError));
    
    // If not currently showing, process queue
    if (!_isShowing) {
      _processQueue();
    }
  }

  void _processQueue() {
    if (_queue.isEmpty) {
      _isShowing = false;
      return;
    }

    _isShowing = true;
    final request = _queue.removeFirst();
    
    // Remove existing if any (safety)
    _overlayEntry?.remove();

    _overlayEntry = OverlayEntry(
      builder: (context) => _DynamicIslandNotification(
        message: request.message,
        isError: request.isError,
        onDismiss: () => _hide(true), // On manual dismiss, proceed to next
      ),
    );

    // Insert overlay
    try {
       Overlay.of(request.context).insert(_overlayEntry!);
    } catch (e) {
       // Context likely invalid, skip
       _isShowing = false;
       _processQueue();
       return;
    }

    // Auto-hide after duration
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 4), () {
      _hide(true); // Proceed to next after timeout
    });
  }

  void _hide(bool processNext) {
    _timer?.cancel();
    _overlayEntry?.remove();
    _overlayEntry = null;
    
    if (processNext) {
       // Small delay for smooth transition between alerts
       Future.delayed(const Duration(milliseconds: 300), () {
         _processQueue();
       });
    } else {
      _isShowing = false;
    }
  }
  
  // Force clear
  void clear() {
    _queue.clear();
    _hide(false);
  }
}

class _NotificationRequest {
  final BuildContext context;
  final String message;
  final bool isError;
  
  _NotificationRequest(this.context, this.message, this.isError);
}

class _DynamicIslandNotification extends StatefulWidget {
  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  const _DynamicIslandNotification({
    required this.message,
    required this.isError,
    required this.onDismiss,
  });

  @override
  State<_DynamicIslandNotification> createState() => _DynamicIslandNotificationState();
}

class _DynamicIslandNotificationState extends State<_DynamicIslandNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _widthAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _widthAnimation = Tween<double>(begin: 40, end: 340).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Light mode: Grey background, Dark mode: White background
    final backgroundColor = isDark ? Colors.white : const Color(0xFF2C2C2E); // iOS grey
    final textColor = isDark ? Colors.black : Colors.white;
    final shadowColor = isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.3);

    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: _dismiss, // Dismiss on tap
          onVerticalDragEnd: (_) => _dismiss(), // Dismiss on swipe up/down
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Container(
                height: 50,
                width: _widthAnimation.value,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor,
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Opacity(
                  opacity: _opacityAnimation.value,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center, // Center contents
                    mainAxisSize: MainAxisSize.min, // Hug content
                    children: [
                      // Icon/Leading
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: widget.isError ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.isError ? Icons.error_outline : Icons.check_circle_outline,
                          color: widget.isError ? Colors.redAccent : Colors.greenAccent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Message
                      Flexible(
                        child: Text(
                          widget.message,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'SF Pro Display', // Should match app font
                            decoration: TextDecoration.none, // Override overlay default
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
