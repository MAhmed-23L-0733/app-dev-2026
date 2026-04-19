// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'add_transaction.dart';
import 'goals.dart';
import 'home.dart';
import 'profile.dart';
import '../auth/user_profile_service.dart';
import '../theme_controller.dart';
import '../widgets/logo.dart';
import '../widgets/neon_surface.dart';

class MainWrapperScreen extends StatefulWidget {
  const MainWrapperScreen({super.key, this.initialIndex = 0});

  static const String routeName = '/main';
  final int initialIndex;

  @override
  State<MainWrapperScreen> createState() => _MainWrapperScreenState();
}

class _MainWrapperScreenState extends State<MainWrapperScreen> {
  late final _MainWrapperUiState _uiState;

  @override
  void initState() {
    super.initState();
    final int safeInitialIndex =
        widget.initialIndex >= 0 && widget.initialIndex <= 3
        ? widget.initialIndex
        : 0;
    _uiState = _MainWrapperUiState(initialIndex: safeInitialIndex);
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      UserProfileService.instance.loadPreferredCurrencyForUser(user);
    }
  }

  @override
  void dispose() {
    _uiState.dispose();
    super.dispose();
  }

  void _handleTabChanged(int index) {
    _uiState.setSelectedIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    // We only need to check the screen width now; manual bottomInset math is removed.
    final bool isCompactScreen = MediaQuery.sizeOf(context).width < 380;

    return ChangeNotifierProvider<_MainWrapperUiState>.value(
      value: _uiState,
      child: Consumer<_MainWrapperUiState>(
        builder: (BuildContext context, _MainWrapperUiState uiState, _) {
          return Scaffold(
            extendBody: true,
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              automaticallyImplyLeading: false,
              leadingWidth: isCompactScreen ? 172 : 212,
              leading: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SpendWiseLogo(fontSize: isCompactScreen ? 20 : 24),
                ),
              ),
              actions: <Widget>[
                IconButton(
                  tooltip: 'Toggle theme',
                  onPressed: appThemeController.toggleTheme,
                  icon: Icon(
                    Theme.of(context).brightness == Brightness.dark
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: NeonBackground(
              child: SafeArea(
                child: IndexedStack(
                  index: uiState.selectedIndex,
                  children: const <Widget>[
                    HomeView(),
                    AddTransactionView(),
                    GoalsView(),
                    ProfileView(),
                  ],
                ),
              ),
            ),

            // --- MODERNIZED BOTTOM NAVIGATION BAR ---
            bottomNavigationBar: SafeArea(
              // Automatically pads for the gesture bar, but guarantees AT LEAST 12px on older phones
              minimum: const EdgeInsets.only(bottom: 12),
              child: Padding(
                // We leave bottom padding at 0 here because SafeArea handles it now
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BottomNavigationBar(
                    currentIndex: uiState.selectedIndex,
                    onTap: _handleTabChanged,
                    items: const <BottomNavigationBarItem>[
                      BottomNavigationBarItem(
                        icon: Icon(Icons.home_rounded),
                        label: 'Dashboard',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.add_circle_outline_rounded),
                        label: 'Add transaction',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.flag_rounded),
                        label: 'Goals',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.person_rounded),
                        label: 'Profile',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            floatingActionButton: uiState.selectedIndex == 0
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 40, right: 10),
                    child: FloatingActionButton(
                      onPressed: () => Navigator.pushNamed(context, '/chat'),
                      backgroundColor: const Color(0xFF1565C0),
                      tooltip: 'AI Chat',
                      child: const Icon(
                        Icons.smart_toy_rounded,
                        color: Colors.white,
                      ),
                    ),
                  )
                : null,
            floatingActionButtonLocation:
                FloatingActionButtonLocation.endDocked,
          );
        },
      ),
    );
  }
}

class _MainWrapperUiState extends ChangeNotifier {
  _MainWrapperUiState({int initialIndex = 0}) : selectedIndex = initialIndex;

  int selectedIndex;

  void setSelectedIndex(int value) {
    if (selectedIndex == value) {
      return;
    }

    selectedIndex = value;
    notifyListeners();
  }
}
