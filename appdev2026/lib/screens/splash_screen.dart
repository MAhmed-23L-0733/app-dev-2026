import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../auth/signin.dart';
import 'main_wrapper.dart';
import '../widgets/neon_surface.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late List<Offset> _startOffsets;

  // Replicating the SpendWiseLogo styling on a per-character basis
  final List<Map<String, dynamic>> _logoChars = [
    {'char': 'S', 'color': Colors.blue.shade400, 'shadow': true},
    {'char': 'p', 'color': Colors.blue.shade400, 'shadow': true},
    {'char': 'e', 'color': Colors.blue.shade400, 'shadow': true},
    {'char': 'n', 'color': Colors.blue.shade400, 'shadow': true},
    {'char': 'd', 'color': Colors.blue.shade400, 'shadow': true},
    {'char': 'W', 'color': Colors.blue.shade900, 'shadow': false},
    {'char': 'i', 'color': Colors.blue.shade900, 'shadow': false},
    {'char': 's', 'color': Colors.blue.shade900, 'shadow': false},
    {'char': 'e', 'color': Colors.blue.shade900, 'shadow': false},
    {'char': '.', 'color': Colors.blueAccent, 'shadow': false},
  ];

  @override
  void initState() {
    super.initState();

    // Fixed seed ensures the "random" positions are consistent on every launch
    final Random random = Random(42);

    // Generate a scattered starting offset for each character
    _startOffsets = List.generate(_logoChars.length, (index) {
      final double dx = (random.nextDouble() - 0.5) * 800;
      final double dy = (random.nextDouble() - 0.5) * 800;
      return Offset(dx, dy);
    });

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // easeOutCubic makes the letters start moving fast, then smoothly decelerate into place
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    // Start the animation, pause briefly to let the user see the formed logo, then route
    _controller.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 600), _checkAuthAndNavigate);
    });
  }

  void _checkAuthAndNavigate() {
    if (!mounted) return;

    // Auth check replacing the logic previously handled in main.dart
    final User? user = FirebaseAuth.instance.currentUser;
    final String? uid = user?.uid;

    if (uid == null || uid.isEmpty) {
      Navigator.of(context).pushReplacementNamed(SignInScreen.routeName);
    } else {
      Navigator.of(context).pushReplacementNamed(MainWrapperScreen.routeName);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Wrapped in your existing NeonBackground for thematic consistency
    return Scaffold(
      body: NeonBackground(
        child: Center(
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(_logoChars.length, (index) {
                  // Interpolate from the random scattered position to their natural (0,0) position
                  final Offset currentOffset = Offset.lerp(
                    _startOffsets[index],
                    Offset.zero,
                    _animation.value,
                  )!;

                  final double opacity = _animation.value.clamp(0.0, 1.0);
                  final charData = _logoChars[index];

                  return Transform.translate(
                    offset: currentOffset,
                    child: Opacity(
                      opacity: opacity,
                      child: Text(
                        charData['char'],
                        style: GoogleFonts.poppins(
                          fontSize: 42.0,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          color: charData['color'],
                          shadows: charData['shadow']
                              ? [
                                  Shadow(
                                    color: Colors.blue.withOpacity(0.3),
                                    offset: const Offset(0, 2),
                                    blurRadius: 4,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ),
      ),
    );
  }
}
