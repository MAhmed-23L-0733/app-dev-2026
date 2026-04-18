// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import 'add_transaction.dart';
import 'goals.dart';
import 'home.dart';
import 'profile.dart';
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
    ];

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(titles[_selectedIndex]),
        actions: <Widget>[
          IconButton(
            tooltip: 'Profile',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ProfileView()),
              );
            },
            icon: const Icon(Icons.person_rounded),
          ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
