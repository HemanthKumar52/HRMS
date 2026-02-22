import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PulseLogo extends StatelessWidget {
  final Color textColor;
  final double size;

  const PulseLogo({
    super.key,
    this.textColor = Colors.black,
    this.size = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Purple user icon from assets (no clipping)
        Image.asset(
          'assets/images/purple-user-icon.png',
          width: 56 * size,
          height: 56 * size,
          fit: BoxFit.contain,
        ),
        SizedBox(width: 12 * size),

        // pPULSE text in white pill
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 20 * size,
            vertical: 10 * size,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'p',
                style: GoogleFonts.inter(
                  fontSize: 26 * size,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: const Color(0xFF1E1E2E),
                ),
              ),
              Text(
                'PULSE',
                style: GoogleFonts.inter(
                  fontSize: 28 * size,
                  fontWeight: FontWeight.w300,
                  fontStyle: FontStyle.italic,
                  color: const Color(0xFF1E1E2E),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
