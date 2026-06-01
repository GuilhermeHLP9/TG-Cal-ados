import 'package:flutter/material.dart';

import '../../../core/services/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({
    super.key,
    required this.apiClient,
    required this.token,
    required this.user,
    required this.onUserChanged,
  });

  final ApiClient apiClient;
  final String token;
  final AuthUser user;
  final ValueChanged<AuthUser> onUserChanged;

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _companyNameController;
  late final TextEditingController _companyCnpjController;
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _companyNameController = TextEditingController(
      text: widget.user.company?.name ?? '',
    );
    _companyCnpjController = TextEditingController(
      text: _formatCnpj(widget.user.company?.cnpj ?? ''),
    );
  }

  @override
  void didUpdateWidget(covariant ProfileSettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user != widget.user) {
      _nameController.text = widget.user.name;
      _companyNameController.text = widget.user.company?.name ?? '';
      _companyCnpjController.text = _formatCnpj(widget.user.company?.cnpj ?? '');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyNameController.dispose();
    _companyCnpjController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: AppCard(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Configuracoes',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 18),
              _InfoLine(label: 'E-mail', value: widget.user.email),
              _InfoLine(
                label: 'Tipo de usuario',
                value: widget.user.isOwner ? 'Proprietario' : 'Cliente',
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (value) {
                  if (value == null || value.trim().length < 2) {
                    return 'Informe um nome valido.';
                  }
                  return null;
                },
              ),
              if (widget.user.isOwner) ...[
                const SizedBox(height: 14),
                TextFormField(
                  controller: _companyNameController,
                  decoration: const InputDecoration(labelText: 'Empresa'),
                  validator: (value) {
                    if (value == null || value.trim().length < 2) {
                      return 'Informe o nome da empresa.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _companyCnpjController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'CNPJ'),
                  validator: (value) {
                    final digits = _onlyDigits(value ?? '');
                    if (digits.length != 14) {
                      return 'Informe um CNPJ com 14 numeros.';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 22),
              Text(
                'Alterar senha',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Senha atual'),
                validator: (value) {
                  if (_newPasswordController.text.isEmpty) {
                    return null;
                  }
                  if (value == null || value.length < 6) {
                    return 'Informe a senha atual.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Nova senha'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return null;
                  }
                  if (value.length < 6) {
                    return 'A senha precisa ter pelo menos 6 caracteres.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_saving ? 'Salvando...' : 'Salvar alteracoes'),
                ),
              ),
              const SizedBox(height: 18),
              const _InfoLine(label: 'Versao do app', value: '0.1.0 MVP'),
              const _InfoLine(label: 'Plataforma', value: 'Flutter'),
              const _InfoLine(label: 'Ambiente', value: 'Desenvolvimento'),
              const _InfoLine(label: 'API', value: 'Backend local conectado'),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _saving = true);

    try {
      final user = await widget.apiClient.updateMe(
        token: widget.token,
        name: _nameController.text,
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
        companyName: widget.user.isOwner ? _companyNameController.text : null,
        companyCnpj: widget.user.isOwner ? _companyCnpjController.text : null,
      );

      _currentPasswordController.clear();
      _newPasswordController.clear();
      widget.onUserChanged(user);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil atualizado.')),
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

String _onlyDigits(String value) {
  return value.replaceAll(RegExp(r'\D'), '');
}

String _formatCnpj(String value) {
  final digits = _onlyDigits(value);
  if (digits.length != 14) {
    return value;
  }

  return '${digits.substring(0, 2)}.${digits.substring(2, 5)}.'
      '${digits.substring(5, 8)}/${digits.substring(8, 12)}-'
      '${digits.substring(12, 14)}';
}
