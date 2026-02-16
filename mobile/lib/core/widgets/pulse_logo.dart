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
        // Icon Section
        Container(
          width: 40 * size,
          height: 40 * size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF8B5CF6), // Purple
                const Color(0xFF6366F1), // Indigo
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.person, // Or Icons.person_rounded
            color: Colors.white,
            size: 24 * size,
          ),
        ),
        SizedBox(width: 12 * size),
        
        // Text Section
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'p',
                style: GoogleFonts.playfairDisplay(
                  color: textColor,
                  fontSize: 36 * size,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                ),
              ),
              TextSpan(
                text: 'PULSE',
                style: GoogleFonts.outfit(
                  color: textColor,
                  fontSize: 32 * size,
                  fontWeight: FontWeight.w300, 
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
