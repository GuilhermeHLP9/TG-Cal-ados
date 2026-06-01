import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/services/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/section_heading.dart';
import 'auth_navigation.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    required this.apiClient,
  });

  final ApiClient apiClient;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _userFormKey = GlobalKey<FormState>();
  final _companyFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _companyCnpjController = TextEditingController();
  String _role = 'CLIENT';
  int _step = 0;
  bool _isLoading = false;
  bool _isCheckingEmail = false;
  String? _emailError;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _companyNameController.dispose();
    _companyCnpjController.dispose();
    super.dispose();
  }

  Future<void> _goToCompanyStep() async {
    setState(() => _emailError = null);

    if (!(_userFormKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isCheckingEmail = true);

    try {
      final available = await widget.apiClient.isEmailAvailable(
        _emailController.text.trim().toLowerCase(),
      );

      if (!available) {
        setState(() {
          _emailError = 'E-mail ja cadastrado.';
          _isCheckingEmail = false;
        });
        _userFormKey.currentState?.validate();
        return;
      }
    } catch (_) {
      setState(() {
        _emailError = 'Nao foi possivel verificar este e-mail.';
        _isCheckingEmail = false;
      });
      _userFormKey.currentState?.validate();
      return;
    }

    setState(() {
      _step = 1;
      _error = null;
      _isCheckingEmail = false;
    });
  }

  Future<void> _register() async {
    if (!(_companyFormKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final session = await widget.apiClient.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim().toLowerCase(),
        password: _passwordController.text,
        companyName: _companyNameController.text.trim(),
        companyCnpj: _companyCnpjController.text.trim(),
        role: _role,
      );

      if (!mounted) {
        return;
      }

      openAuthenticatedHome(
        context,
        apiClient: widget.apiClient,
        session: session,
      );
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = 'Nao foi possivel criar a conta.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F3F4),
      appBar: AppBar(
        title: const Text('Criar conta'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SectionHeading(
              title: _step == 0 ? 'Dados de acesso' : 'Vinculacao de empresa',
              subtitle: _step == 0
                  ? 'Crie o acesso do usuario ao sistema.'
                  : _companySubtitle,
            ),
            const SizedBox(height: 20),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StepIndicator(currentStep: _step),
                  const SizedBox(height: 20),
                  _step == 0
                      ? _buildUserStep(formKey: _userFormKey)
                      : _buildCompanyStep(formKey: _companyFormKey),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _companySubtitle {
    if (_role == 'OWNER') {
      return 'Informe os dados da empresa que sera criada ou atualizada.';
    }

    return 'Informe os dados da empresa ja cadastrada para vincular o cliente.';
  }

  Widget _buildUserStep({required GlobalKey<FormState> formKey}) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nome', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameController,
            textInputAction: TextInputAction.next,
            validator: _nameValidator,
          ),
          const SizedBox(height: 16),
          Text('E-mail', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            onChanged: (_) {
              if (_emailError != null) {
                setState(() => _emailError = null);
              }
            },
            validator: _emailValidator,
          ),
          const SizedBox(height: 16),
          Text('Senha', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            textInputAction: TextInputAction.next,
            validator: _passwordValidator,
          ),
          const SizedBox(height: 16),
          Text('Confirmar senha', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: true,
            validator: _confirmPasswordValidator,
          ),
          const SizedBox(height: 18),
          Text('Tipo de acesso', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'CLIENT',
                label: Text('Cliente'),
                icon: Icon(Icons.person_outline),
              ),
              ButtonSegment(
                value: 'OWNER',
                label: Text('Proprietario'),
                icon: Icon(Icons.factory_outlined),
              ),
            ],
            selected: {_role},
            onSelectionChanged: (selection) {
              setState(() => _role = selection.first);
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _isCheckingEmail ? null : _goToCompanyStep,
            icon: const Icon(Icons.arrow_forward),
            label: Text(_isCheckingEmail ? 'Verificando...' : 'Continuar'),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyStep({required GlobalKey<FormState> formKey}) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CompanyHelp(role: _role),
          const SizedBox(height: 18),
          Text('Nome da empresa', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextFormField(
            controller: _companyNameController,
            decoration: const InputDecoration(
              hintText: 'Ex.: Solex Demo',
            ),
            textInputAction: TextInputAction.next,
            validator: _companyNameValidator,
          ),
          const SizedBox(height: 16),
          Text('CNPJ', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextFormField(
            controller: _companyCnpjController,
            keyboardType: TextInputType.number,
            inputFormatters: const [_CnpjInputFormatter()],
            decoration: const InputDecoration(
              hintText: '00.000.000/0000-00',
            ),
            validator: _cnpjValidator,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _register,
              icon: const Icon(Icons.person_add_alt_1),
              label: Text(_isLoading ? 'Criando...' : 'Criar conta'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isLoading ? null : () => setState(() => _step = 0),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Voltar para dados de acesso'),
            ),
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
    );
  }

  String? _nameValidator(String? value) {
    if ((value ?? '').trim().length < 3) {
      return 'Informe pelo menos 3 caracteres.';
    }

    return null;
  }

  String? _emailValidator(String? value) {
    final text = (value ?? '').trim();

    if (!text.contains('@') || !text.contains('.')) {
      return 'Informe um e-mail valido.';
    }

    if (_emailError != null) {
      return _emailError;
    }

    return null;
  }

  String? _passwordValidator(String? value) {
    if ((value ?? '').length < 6) {
      return 'A senha precisa ter pelo menos 6 caracteres.';
    }

    return null;
  }

  String? _confirmPasswordValidator(String? value) {
    if (value != _passwordController.text) {
      return 'As senhas precisam ser iguais.';
    }

    return null;
  }

  String? _companyNameValidator(String? value) {
    if ((value ?? '').trim().length < 2) {
      return 'Informe o nome da empresa.';
    }

    return null;
  }

  String? _cnpjValidator(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.length != 14) {
      return 'Informe um CNPJ com 14 numeros.';
    }

    return null;
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StepPill(
          label: '1. Acesso',
          selected: currentStep == 0,
        ),
        const SizedBox(width: 8),
        _StepPill(
          label: '2. Empresa',
          selected: currentStep == 1,
        ),
      ],
    );
  }
}

class _StepPill extends StatelessWidget {
  const _StepPill({
    required this.label,
    required this.selected,
  });

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : const Color(0xFFEAF3F7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.primaryDark,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _CompanyHelp extends StatelessWidget {
  const _CompanyHelp({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final text = role == 'OWNER'
        ? 'Como proprietario, voce cria ou atualiza a empresa usando o CNPJ.'
        : 'Como cliente, a empresa ja precisa existir. Use o CNPJ informado pelo proprietario.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3F7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.primaryDark,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CnpjInputFormatter extends TextInputFormatter {
  const _CnpjInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final limited = digits.length > 14 ? digits.substring(0, 14) : digits;
    final buffer = StringBuffer();

    for (var i = 0; i < limited.length; i++) {
      if (i == 2 || i == 5) {
        buffer.write('.');
      }
      if (i == 8) {
        buffer.write('/');
      }
      if (i == 12) {
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
