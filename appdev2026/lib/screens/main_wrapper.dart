// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'add_transaction.dart';
import 'goals.dart';
import 'home.dart';
import 'profile.dart';
import '../auth/user_profile_service.dart';
import '../theme_controller.dart';
import '../widgets/neon_surface.dart';

class MainWrapperScreen extends StatefulWidget {
  const MainWrapperScreen({super.key});

  static const String routeName = '/main';

  @override
  State<MainWrapperScreen> createState() => _MainWrapperScreenState();
}

class _MainWrapperScreenState extends State<MainWrapperScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      UserProfileService.instance.loadPreferredCurrencyForUser(user);
    }
  }

  void _handleTabChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<String> titles = <String>[
      'Dashboard',
      'Add transaction',
      'Goals',
      'Profile',
    ];

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(titles[_selectedIndex]),
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
            index: _selectedIndex,
            children: const <Widget>[
              HomeView(),
              AddTransactionView(),
              GoalsView(),
              ProfileView(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: MediaQuery.removePadding(
            context: context,
            removeBottom: true,
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
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
    );
  }
}
