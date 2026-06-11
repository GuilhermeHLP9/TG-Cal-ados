import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/app_settings/app_settings_controller.dart';
import '../../../core/services/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/image_data.dart';
import '../../../core/widgets/app_card.dart';
import '../../auth/presentation/logout.dart';

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
  late AuthUser _user;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Perfil'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _profileCard(context),
          const SizedBox(height: 14),
          if (_user.isOwner) ...[
            _companyCard(context),
            const SizedBox(height: 14),
          ],
          _securityCard(context),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _profileCard(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(icon: Icons.person_outline, title: 'Perfil'),
          const SizedBox(height: 14),
          Center(child: _ProfileImagePreview(image: _user.profileImage, radius: 44)),
          const SizedBox(height: 14),
          _InfoLine(label: 'E-mail', value: _user.email),
          _InfoLine(label: 'Telefone', value: _formatPhone(_user.phone ?? '')),
          _InfoLine(
            label: 'Tipo de usuario',
            value: _user.isOwner ? 'Proprietario' : 'Cliente',
          ),
          _InfoLine(label: 'Nome', value: _user.name),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _openEditProfile(context),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Editar perfil'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _companyCard(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(icon: Icons.storefront_outlined, title: 'Empresa'),
          const SizedBox(height: 14),
          _InfoLine(label: 'Nome da empresa', value: _user.company?.name ?? '-'),
          _InfoLine(label: 'CNPJ', value: _formatCnpj(_user.company?.cnpj ?? '')),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: () => _openEditCompany(context),
              icon: const Icon(Icons.business_outlined),
              label: const Text('Editar empresa'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _securityCard(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(icon: Icons.lock_outline, title: 'Seguranca'),
          const SizedBox(height: 12),
          _SettingsAction(
            icon: Icons.password_outlined,
            title: 'Alterar senha',
            subtitle: 'Atualize sua senha de acesso ao app.',
            onTap: () => _openSecurity(context),
          ),
          const Divider(height: 18),
          _SettingsAction(
            icon: Icons.logout,
            title: 'Sair da conta',
            subtitle: 'Voltar para a tela de login.',
            onTap: () => logout(context),
          ),
        ],
      ),
    );
  }

  void _openEditProfile(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          apiClient: apiClient,
          token: widget.token,
          user: _user,
          onUserChanged: _handleUserChanged,
        ),
      ),
    );
  }

  void _openEditCompany(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditCompanyScreen(
          apiClient: apiClient,
          token: widget.token,
          user: _user,
          onUserChanged: _handleUserChanged,
        ),
      ),
    );
  }

  void _openSecurity(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SecuritySettingsScreen(
          apiClient: apiClient,
          token: widget.token,
          onUserChanged: _handleUserChanged,
        ),
      ),
    );
  }

  ApiClient get apiClient => widget.apiClient;

  void _handleUserChanged(AuthUser user) {
    setState(() => _user = user);
    widget.onUserChanged(user);
  }
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
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
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  String? _profileImage;
  bool _saving = false;
  bool _pickingImage = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(
      text: _formatPhone(widget.user.phone ?? ''),
    );
    _profileImage = widget.user.profileImage;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _EditScaffold(
      title: 'Editar perfil',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(icon: Icons.person_outline, title: 'Perfil'),
            const SizedBox(height: 14),
            Center(
              child: _ProfileImagePreview(image: _profileImage, radius: 50),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickingImage ? null : _pickProfileImage,
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: Text(_pickingImage ? 'Abrindo...' : 'Trocar foto'),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filledTonal(
                  tooltip: 'Remover foto',
                  onPressed: _profileImage == null || _profileImage!.isEmpty
                      ? null
                      : () => setState(() => _profileImage = ''),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _InfoLine(
              label: 'Tipo de usuario',
              value: widget.user.isOwner ? 'Proprietario' : 'Cliente',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'E-mail'),
              validator: (value) {
                final email = value?.trim() ?? '';
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                  return 'Informe um e-mail valido.';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: const [_PhoneInputFormatter()],
              decoration: const InputDecoration(labelText: 'Telefone'),
              validator: (value) {
                final digits = _onlyDigits(value ?? '');
                if (digits.length < 10 || digits.length > 11) {
                  return 'Informe um telefone valido.';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
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
            const SizedBox(height: 18),
            _SaveButton(
              saving: _saving,
              label: 'Salvar perfil',
              onPressed: _save,
            ),
          ],
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
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        profileImage: _profileImage,
      );
      widget.onUserChanged(user);
      if (mounted) {
        Navigator.of(context).pop();
        _showMessage(context, 'Perfil atualizado.');
      }
    } on ApiException catch (error) {
      if (mounted) {
        _showMessage(context, error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _pickProfileImage() async {
    setState(() => _pickingImage = true);

    try {
      final image = await pickImageDataUrl();

      if (!mounted || image == null) {
        return;
      }

      setState(() => _profileImage = image);
    } finally {
      if (mounted) {
        setState(() => _pickingImage = false);
      }
    }
  }
}

class EditCompanyScreen extends StatefulWidget {
  const EditCompanyScreen({
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
  State<EditCompanyScreen> createState() => _EditCompanyScreenState();
}

class _EditCompanyScreenState extends State<EditCompanyScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _cnpjController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.company?.name ?? '');
    _cnpjController = TextEditingController(
      text: _formatCnpj(widget.user.company?.cnpj ?? ''),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cnpjController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _EditScaffold(
      title: 'Editar empresa',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(icon: Icons.storefront_outlined, title: 'Empresa'),
            const SizedBox(height: 14),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nome da empresa'),
              validator: (value) {
                if (value == null || value.trim().length < 2) {
                  return 'Informe o nome da empresa.';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _cnpjController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'CNPJ'),
              validator: (value) {
                if (_onlyDigits(value ?? '').length != 14) {
                  return 'Informe um CNPJ com 14 numeros.';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            _SaveButton(
              saving: _saving,
              label: 'Salvar empresa',
              onPressed: _save,
            ),
          ],
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
        companyName: _nameController.text.trim(),
        companyCnpj: _cnpjController.text,
      );
      widget.onUserChanged(user);
      if (mounted) {
        Navigator.of(context).pop();
        _showMessage(context, 'Empresa atualizada.');
      }
    } on ApiException catch (error) {
      if (mounted) {
        _showMessage(context, error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({
    super.key,
    required this.apiClient,
    required this.token,
    required this.onUserChanged,
  });

  final ApiClient apiClient;
  final String token;
  final ValueChanged<AuthUser> onUserChanged;

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _EditScaffold(
      title: 'Seguranca',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(icon: Icons.lock_outline, title: 'Alterar senha'),
            const SizedBox(height: 14),
            TextFormField(
              controller: _currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Senha atual'),
              validator: (value) {
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
                if (value == null || value.length < 6) {
                  return 'A senha precisa ter pelo menos 6 caracteres.';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            _SaveButton(
              saving: _saving,
              label: 'Alterar senha',
              onPressed: _save,
            ),
          ],
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
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );
      widget.onUserChanged(user);
      if (mounted) {
        Navigator.of(context).pop();
        _showMessage(context, 'Senha alterada.');
      }
    } on ApiException catch (error) {
      if (mounted) {
        _showMessage(context, error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({
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
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  late AuthUser _user;
  bool _refreshing = false;
  bool _testingApi = false;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Configuracoes'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _companySummary(),
          const SizedBox(height: 14),
          _dataCard(),
          const SizedBox(height: 14),
          _themeCard(),
          const SizedBox(height: 14),
          _aboutCard(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _companySummary() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(icon: Icons.factory_outlined, title: 'Solex'),
          const SizedBox(height: 14),
          Text(
            _user.company?.name ?? 'Empresa nao informada',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'O Solex organiza clientes, pedidos, producao, notas internas e dados basicos da empresa em um app simples para a rotina de fabricacao de calcados.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dataCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(icon: Icons.cloud_sync_outlined, title: 'Dados'),
          const SizedBox(height: 8),
          _SettingsAction(
            icon: Icons.refresh,
            title: 'Atualizar dados',
            subtitle: 'Busca novamente seus dados salvos na API.',
            isBusy: _refreshing,
            onTap: _refreshUser,
          ),
          const Divider(height: 18),
          _SettingsAction(
            icon: Icons.wifi_tethering_outlined,
            title: 'Testar conexao',
            subtitle: 'Confere se o app consegue falar com o backend.',
            isBusy: _testingApi,
            onTap: _testApi,
          ),
          const Divider(height: 18),
          _InfoLine(label: 'API atual', value: widget.apiClient.baseUrl),
        ],
      ),
    );
  }

  Widget _themeCard() {
    return AppCard(
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: AppSettingsController.themeMode,
        builder: (context, themeMode, _) {
          final dark = themeMode == ThemeMode.dark;
          return SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: Icon(
              Icons.dark_mode_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text(
              'Tema escuro',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            subtitle: Text(dark ? 'Usando tema escuro' : 'Usando tema claro'),
            value: dark,
            onChanged: AppSettingsController.setDarkMode,
          );
        },
      ),
    );
  }

  Widget _aboutCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(icon: Icons.info_outline, title: 'Sobre'),
          const SizedBox(height: 14),
          _SettingsAction(
            icon: Icons.privacy_tip_outlined,
            title: 'Politica de privacidade',
            subtitle: 'Como o Solex trata os dados do app.',
            onTap: _openPrivacy,
          ),
          const Divider(height: 18),
          const _InfoLine(label: 'App', value: 'Solex'),
          const _InfoLine(label: 'Versao', value: '1.0.0'),
          const _InfoLine(label: 'Plataforma', value: 'Flutter'),
          const _InfoLine(label: 'Ambiente', value: 'Backend local'),
        ],
      ),
    );
  }

  Future<void> _refreshUser() async {
    setState(() => _refreshing = true);

    try {
      final user = await widget.apiClient.getMe(widget.token);
      setState(() => _user = user);
      widget.onUserChanged(user);
      if (mounted) {
        _showMessage(context, 'Dados atualizados da API.');
      }
    } on ApiException catch (error) {
      if (mounted) {
        _showMessage(context, error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _refreshing = false);
      }
    }
  }

  Future<void> _testApi() async {
    setState(() => _testingApi = true);

    try {
      final ok = await widget.apiClient.checkHealth();
      if (mounted) {
        _showMessage(
          context,
          ok ? 'API conectada.' : 'API respondeu fora do esperado.',
        );
      }
    } on ApiException catch (error) {
      if (mounted) {
        _showMessage(context, error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _testingApi = false);
      }
    }
  }

  void _openPrivacy() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
    );
  }
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Politica de privacidade'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacidade',
                ),
                SizedBox(height: 14),
                _PolicyText(
                  title: 'Dados usados',
                  body:
                      'O Solex utiliza dados de login, perfil, empresa, clientes, CNPJ, pedidos, valores, prazos e notas internas para operar a gestao de pedidos de calcados.',
                ),
                _PolicyText(
                  title: 'Finalidade',
                  body:
                      'Esses dados sao usados para autenticar usuarios, organizar clientes, acompanhar pedidos, registrar custos e manter informacoes da empresa acessiveis ao proprietario.',
                ),
                _PolicyText(
                  title: 'Acesso',
                  body:
                      'Clientes visualizam apenas seus proprios pedidos. O proprietario visualiza os dados da empresa, clientes, pedidos e notas internas vinculados ao seu uso do app.',
                ),
                _PolicyText(
                  title: 'Armazenamento',
                  body:
                      'Os dados ficam no banco PostgreSQL configurado para o backend local do projeto. Senhas sao armazenadas de forma protegida por hash.',
                ),
                _PolicyText(
                  title: 'Compartilhamento',
                  body:
                      'O app nao possui compartilhamento automatico com terceiros, notificacoes externas ou chat ativo no escopo atual.',
                ),
                _PolicyText(
                  title: 'Controle',
                  body:
                      'O proprietario pode atualizar dados da empresa, gerenciar clientes e pedidos. Alteracoes sensiveis de senha exigem a senha atual.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditScaffold extends StatelessWidget {
  const _EditScaffold({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AppCard(child: child),
        ],
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.saving,
    required this.label,
    required this.onPressed,
  });

  final bool saving;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: saving ? null : onPressed,
        icon: saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.save_outlined),
        label: Text(saving ? 'Salvando...' : label),
      ),
    );
  }
}

class _ProfileImagePreview extends StatelessWidget {
  const _ProfileImagePreview({
    required this.image,
    required this.radius,
  });

  final String? image;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final bytes = imageBytesFromDataUrl(image);

    if (bytes != null) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: MemoryImage(bytes),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: colors.primary.withValues(alpha: 0.12),
      child: Icon(
        Icons.person,
        color: colors.primary,
        size: radius,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: colors.primary, size: 21),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsAction extends StatelessWidget {
  const _SettingsAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isBusy = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: colors.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: Text(subtitle),
      trailing: isBusy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.chevron_right),
      onTap: isBusy ? null : onTap,
    );
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
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value.isEmpty ? '-' : value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicyText extends StatelessWidget {
  const _PolicyText({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            body,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              height: 1.35,
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

String _formatPhone(String value) {
  final digits = _onlyDigits(value);
  if (digits.length == 10) {
    return '(${digits.substring(0, 2)}) ${digits.substring(2, 6)}-${digits.substring(6, 10)}';
  }
  if (digits.length == 11) {
    return '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-${digits.substring(7, 11)}';
  }
  return value;
}

class _PhoneInputFormatter extends TextInputFormatter {
  const _PhoneInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = _onlyDigits(newValue.text);
    final limited = digits.length > 11 ? digits.substring(0, 11) : digits;
    final buffer = StringBuffer();

    for (var i = 0; i < limited.length; i++) {
      if (i == 0) {
        buffer.write('(');
      }
      if (i == 2) {
        buffer.write(') ');
      }
      if ((limited.length <= 10 && i == 6) || (limited.length == 11 && i == 7)) {
        buffer.write('-');
      }
      buffer.write(limited[i]);
    }

    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
