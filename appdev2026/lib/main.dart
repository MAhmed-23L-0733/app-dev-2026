// ignore_for_file: deprecated_member_use

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth/signin.dart';
import 'auth/signup.dart';
import 'firebase_options.dart';
import 'screens/main_wrapper.dart';
import 'theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Widget _buildInitialScreen() {
    final User? user = FirebaseAuth.instance.currentUser;
    final String? uid = user?.uid;

    if (uid == null || uid.isEmpty) {
      return const SignInScreen();
    }

    return const MainWrapperScreen();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeController,
      builder: (context, themeMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Hackathon Firebase App',
          themeMode: themeMode,
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),
          home: _buildInitialScreen(),
          routes: <String, WidgetBuilder>{
            SignInScreen.routeName: (_) => const SignInScreen(),
            SignUpScreen.routeName: (_) => const SignUpScreen(),
            MainWrapperScreen.routeName: (_) => const MainWrapperScreen(),
          },
        );
      },
    );
  }
}

ThemeData _buildTheme(Brightness brightness) {
  final bool isDark = brightness == Brightness.dark;

  // Clean Black and White surfaces
  final Color surface = isDark
      ? const Color(0xFF121212)
      : const Color(0xFFFFFFFF);
  final Color onSurface = isDark
      ? const Color(0xFFFFFFFF)
      : const Color(0xFF000000);

  // Blue accents
  final Color primary = isDark
      ? const Color(0xFF64B5F6)
      : const Color(0xFF1976D2);
  final Color secondary = isDark
      ? const Color(0xFF42A5F5)
      : const Color(0xFF1565C0);

  final Color appBarBackground = surface.withOpacity(isDark ? 0.90 : 0.95);
  final Color cardBackground = surface.withOpacity(isDark ? 0.40 : 0.95);
  final Color fieldBackground = isDark
      ? Colors.white.withOpacity(0.08)
      : const Color(0xFFF0F4F8);
  final Color navBackground = surface.withOpacity(isDark ? 0.90 : 0.95);

  final ColorScheme colorScheme = ColorScheme(
    brightness: brightness,
    primary: primary,
    onPrimary: Colors.white,
    secondary: secondary,
    onSecondary: Colors.white,
    error: const Color(0xFFFF6B93),
    onError: Colors.white,
    surface: surface,
    onSurface: onSurface,
    surfaceContainerHighest: surface.withOpacity(isDark ? 0.24 : 0.96),
    onSurfaceVariant: onSurface.withOpacity(0.74),
    outline: primary.withOpacity(0.35),
    shadow: Colors.black,
    inverseSurface: isDark ? const Color(0xFFFFFFFF) : const Color(0xFF121212),
    onInverseSurface: isDark
        ? const Color(0xFF121212)
        : const Color(0xFFFFFFFF),
    tertiary: const Color(0xFF00B0FF),
    onTertiary: Colors.black,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: Colors.transparent,
    appBarTheme: AppBarTheme(
      backgroundColor: appBarBackground,
      foregroundColor: onSurface,
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: onSurface,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      iconTheme: IconThemeData(color: onSurface),
    ),
    cardTheme: CardThemeData(
      color: cardBackground,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: primary.withOpacity(0.18)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: fieldBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      labelStyle: TextStyle(color: onSurface.withOpacity(0.72)),
      hintStyle: TextStyle(color: onSurface.withOpacity(0.46)),
      prefixIconColor: primary,
      suffixIconColor: onSurface.withOpacity(0.64),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: primary.withOpacity(0.16)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: primary, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFFF6B93)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFFF6B93), width: 1.4),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 0,
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    iconTheme: IconThemeData(color: onSurface),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: navBackground,
      selectedItemColor: primary,
      unselectedItemColor: onSurface.withOpacity(0.58),
      showSelectedLabels: true,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
    ),
    dividerTheme: DividerThemeData(
      color: primary.withOpacity(0.12),
      thickness: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: surface.withOpacity(isDark ? 0.96 : 0.98),
      contentTextStyle: TextStyle(color: onSurface),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
