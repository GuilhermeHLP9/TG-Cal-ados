import 'package:flutter/material.dart';

import '../../../../core/services/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({
    super.key,
    required this.apiClient,
    this.initialEmail = '',
  });

  final ApiClient apiClient;
  final String initialEmail;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _sending = false;
  bool _saving = false;
  bool _codeSent = false;
  String? _message;
  String? _error;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recuperar senha'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Redefina seu acesso',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Informe seu e-mail para receber um codigo e cadastrar uma nova senha.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            AppCard(
              child: _codeSent ? _buildResetForm() : _buildEmailForm(),
            ),
            if (_message != null) ...[
              const SizedBox(height: 14),
              _StatusBanner(
                icon: Icons.mark_email_read_outlined,
                text: _message!,
                isError: false,
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 14),
              _StatusBanner(
                icon: Icons.error_outline,
                text: _error!,
                isError: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmailForm() {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('E-mail', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.mail_outline),
              hintText: 'voce@email.com',
            ),
            validator: _emailValidator,
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _sending ? null : _requestReset,
              icon: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_outlined),
              label: Text(_sending ? 'Enviando...' : 'Enviar codigo'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetForm() {
    return Form(
      key: _resetFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Codigo recebido', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextFormField(
            controller: _tokenController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.key_outlined),
              hintText: 'Cole o codigo do e-mail',
            ),
            validator: (value) {
              if ((value ?? '').trim().length < 20) {
                return 'Informe o codigo recebido.';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          Text('Nova senha', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.lock_outline)),
            validator: (value) {
              if ((value ?? '').length < 6) {
                return 'A senha precisa ter pelo menos 6 caracteres.';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          Text('Confirmar senha', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.lock_reset_outlined),
            ),
            validator: (value) {
              if (value != _passwordController.text) {
                return 'As senhas precisam ser iguais.';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saving ? null : _resetPassword,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(_saving ? 'Salvando...' : 'Salvar nova senha'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _saving ? null : () => setState(() => _codeSent = false),
              child: const Text('Usar outro e-mail'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _requestReset() async {
    if (!(_emailFormKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _sending = true;
      _message = null;
      _error = null;
    });

    try {
      await widget.apiClient.requestPasswordReset(_emailController.text);

      if (mounted) {
        setState(() {
          _codeSent = true;
          _message = 'Se este e-mail estiver cadastrado, o codigo foi enviado.';
        });
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Nao foi possivel solicitar a recuperacao.');
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<void> _resetPassword() async {
    if (!(_resetFormKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _saving = true;
      _message = null;
      _error = null;
    });

    try {
      await widget.apiClient.resetPassword(
        token: _tokenController.text,
        password: _passwordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Senha redefinida. Entre novamente.')),
        );
        Navigator.of(context).pop();
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Nao foi possivel redefinir a senha.');
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String? _emailValidator(String? value) {
    final email = (value ?? '').trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Informe um e-mail valido.';
    }
    return null;
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.icon,
    required this.text,
    required this.isError,
  });

  final IconData icon;
  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = isError ? colors.error : colors.primary;
    final background = foreground.withValues(alpha: 0.1);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: foreground.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foreground),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: colors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
