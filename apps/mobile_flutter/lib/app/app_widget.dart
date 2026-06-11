import 'package:flutter/material.dart';

import '../core/app_settings/app_settings_controller.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/presentation/auth_gate.dart';

class SolexApp extends StatelessWidget {
  const SolexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppSettingsController.themeMode,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'Solex',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeMode,
          home: const AuthGate(),
        );
      },
    );
  }
}
