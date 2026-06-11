import 'package:flutter/material.dart';

class AppSettingsController {
  AppSettingsController._();

  static final themeMode = ValueNotifier<ThemeMode>(ThemeMode.light);

  static void setDarkMode(bool enabled) {
    themeMode.value = enabled ? ThemeMode.dark : ThemeMode.light;
  }
}
