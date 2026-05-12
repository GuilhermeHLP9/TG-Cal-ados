import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/section_heading.dart';
import '../../client/presentation/client_home_shell.dart';
import '../../owner/presentation/owner_home_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: 'cliente@calcados.com');
  final _passwordController = TextEditingController(text: '123456');

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _enterApp() {
    final email = _emailController.text.trim().toLowerCase();
    final nextPage =
        email.contains('dono') ? const OwnerHomeShell() : const ClientHomeShell();

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => nextPage),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 24),
            Container(
              width: 110,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'MVP Flutter',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 18),
            const SectionHeading(
              title: 'Solex',
              subtitle:
                  'Sistema de gestao de pedidos para empresa calcadista com acesso para cliente e proprietario.',
            ),
            const SizedBox(height: 24),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('E-mail', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  TextField(controller: _emailController),
                  const SizedBox(height: 16),
                  Text('Senha', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _enterApp,
                    child: const Text('Entrar'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Acesso rapido para demo',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 8),
                  Text('Use dono@calcados.com para abrir a area do proprietario.'),
                  SizedBox(height: 4),
                  Text('Qualquer outro e-mail abre a area do cliente.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
