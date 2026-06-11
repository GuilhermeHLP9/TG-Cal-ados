import 'package:flutter/material.dart';

import '../../../../core/services/api_client.dart';
import '../../../../core/services/session_storage.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';
import 'auth_navigation.dart';
import 'login_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _apiClient = ApiClient();
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  @override
  Widget build(BuildContext context) {
    if (!_checking) {
      return const LoginScreen();
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: AppCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(
                      Icons.factory_outlined,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Entrando no Solex',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const CircularProgressIndicator(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _restoreSession() async {
    final token = await SessionStorage.readToken();

    if (!mounted) {
      return;
    }

    if (token == null || token.isEmpty) {
      setState(() => _checking = false);
      return;
    }

    try {
      final user = await _apiClient.getMe(token);

      if (!mounted) {
        return;
      }

      openAuthenticatedHome(
        context,
        apiClient: _apiClient,
        session: AuthSession(token: token, user: user),
        persistSession: false,
      );
    } catch (_) {
      await SessionStorage.clear();

      if (mounted) {
        setState(() => _checking = false);
      }
    }
  }
}
