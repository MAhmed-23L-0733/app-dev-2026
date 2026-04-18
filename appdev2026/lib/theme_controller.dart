import 'package:flutter/material.dart';

class AppThemeController extends ValueNotifier<ThemeMode> {
  AppThemeController() : super(ThemeMode.system);

  void toggleTheme() {
    final Brightness platformBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;

    if (value == ThemeMode.system) {
      value = platformBrightness == Brightness.dark
          ? ThemeMode.light
          : ThemeMode.dark;
      return;
    }

    value = value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }
}

final AppThemeController appThemeController = AppThemeController();
