import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SpendWiseLogo extends StatelessWidget {
  final double fontSize;

  const SpendWiseLogo({
    super.key,
    this.fontSize = 52.0, // Default large size for prominence
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        // Applying the base Google Font style
        style: GoogleFonts.poppins(
          fontSize: fontSize,
          fontWeight: FontWeight.w800, // Extra bold for that "brand" look
          letterSpacing: 1.0,
        ),
        children: [
          TextSpan(
            text: 'Spend',
            style: TextStyle(
              color: Colors.blue.shade400, // A vibrant, lighter blue
              shadows: [
                Shadow(
                  color: Colors.blue.withOpacity(0.3),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          TextSpan(
            text: 'Wise',
            style: TextStyle(
              color: Colors.blue.shade900, // A deep, trustworthy navy blue
            ),
          ),
          TextSpan(
            text: '.',
            style: TextStyle(
              color:
                  Colors.blueAccent, // A pop of color for an aesthetic period
            ),
          ),
        ],
      ),
    );
  }
}
