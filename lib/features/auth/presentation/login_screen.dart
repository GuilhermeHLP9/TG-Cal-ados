import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/section_heading.dart';
import 'auth_navigation.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: 'dono@calcados.com');
  final _passwordController = TextEditingController(text: '123456');
  final _apiClient = ApiClient();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _enterApp() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final session = await _apiClient.login(
        email: _emailController.text.trim().toLowerCase(),
        password: _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      openAuthenticatedHome(
        context,
        apiClient: _apiClient,
        session: session,
      );
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = 'Nao foi possivel conectar com a API.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
                  'Sistema de gestao de pedidos com acesso para clientes e proprietario.',
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
                    onPressed: _isLoading ? null : _enterApp,
                    child: Text(_isLoading ? 'Entrando...' : 'Entrar'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => RegisterScreen(
                                  apiClient: _apiClient,
                                ),
                              ),
                            );
                          },
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('Criar conta de cliente'),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
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
                  Text('Use dono@calcados.com / 123456 para entrar.'),
                  SizedBox(height: 4),
                  Text('Novas contas criadas aqui entram como cliente.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
