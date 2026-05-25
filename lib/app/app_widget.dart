import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/orders/data/order_store.dart';

class SolexApp extends StatelessWidget {
  const SolexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return OrderScope(
      store: OrderStore(),
      child: MaterialApp(
        title: 'Solex',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const LoginScreen(),
      ),
    );
  }
}
