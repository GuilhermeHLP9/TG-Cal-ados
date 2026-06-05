import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/services/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../data/customer_store.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({
    super.key,
    required this.store,
  });

  final CustomerStore store;

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_sync);
  }

  @override
  void dispose() {
    widget.store.removeListener(_sync);
    _searchController.dispose();
    super.dispose();
  }

  void _sync() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final search = _searchController.text.trim().toLowerCase();
    final customers = widget.store.customers.where((customer) {
      if (search.isEmpty) {
        return true;
      }

      return customer.name.toLowerCase().contains(search) ||
          (customer.cnpj ?? '').contains(search);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F3F4),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCustomerForm(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Cliente'),
      ),
      body: RefreshIndicator(
        onRefresh: widget.store.loadCustomers,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Clientes',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${customers.length} exibidos de ${widget.store.customers.length} clientes',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Atualizar clientes',
                  onPressed:
                      widget.store.isLoading ? null : widget.store.loadCustomers,
                  icon: widget.store.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                ),
              ],
            ),
            if (widget.store.error != null) ...[
              const SizedBox(height: 12),
              _InlineError(message: widget.store.error!),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Buscar por nome ou CNPJ',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 18),
            if (widget.store.isLoading && widget.store.customers.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (customers.isEmpty)
              AppCard(
                child: Column(
                  children: [
                    const Icon(
                      Icons.people_alt_outlined,
                      color: AppColors.primary,
                      size: 42,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.store.customers.isEmpty
                          ? 'Nenhum cliente cadastrado ainda.'
                          : 'Nenhum cliente encontrado.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _openCustomerForm(),
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('Cadastrar cliente'),
                    ),
                  ],
                ),
              )
            else
              ...customers.map(
                (customer) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _CustomerCard(
                    customer: customer,
                    onEdit: () => _openCustomerForm(customer: customer),
                  ),
                ),
              ),
            const SizedBox(height: 76),
          ],
        ),
      ),
    );
  }

  Future<void> _openCustomerForm({CustomerItem? customer}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return _CustomerFormSheet(
          store: widget.store,
          customer: customer,
        );
      },
    );

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            customer == null
                ? 'Cliente cadastrado com sucesso.'
                : 'Cliente atualizado com sucesso.',
          ),
        ),
      );
    }
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({
    required this.customer,
    required this.onEdit,
  });

  final CustomerItem customer;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onEdit,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.storefront, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatCnpj(customer.cnpj) ?? 'CNPJ nao informado',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Editar cliente',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomerFormSheet extends StatefulWidget {
  const _CustomerFormSheet({
    required this.store,
    this.customer,
  });

  final CustomerStore store;
  final CustomerItem? customer;

  @override
  State<_CustomerFormSheet> createState() => _CustomerFormSheetState();
}

class _CustomerFormSheetState extends State<_CustomerFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _cnpjController;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer?.name ?? '');
    _cnpjController = TextEditingController(text: widget.customer?.cnpj ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cnpjController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.customer == null ? 'Cadastrar cliente' : 'Editar cliente',
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                validator: _required,
                decoration: const InputDecoration(
                  labelText: 'Nome do cliente',
                  hintText: 'Ex.: Calcados Franca Norte',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cnpjController,
                keyboardType: TextInputType.number,
                inputFormatters: const [_CnpjInputFormatter()],
                validator: _optionalCnpj,
                decoration: const InputDecoration(
                  labelText: 'CNPJ',
                  hintText: '00.000.000/0000-00',
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isSaving ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      child: Text(_isSaving ? 'Salvando...' : 'Salvar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final customer = widget.customer;

      if (customer == null) {
        await widget.store.createCustomer(
          name: _nameController.text.trim(),
          cnpj: _cnpjController.text.trim(),
        );
      } else {
        await widget.store.updateCustomer(
          id: customer.id,
          name: _nameController.text.trim(),
          cnpj: _cnpjController.text.trim(),
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on ApiException catch (error) {
      setState(() {
        _error = error.message;
        _isSaving = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Nao foi possivel salvar o cliente.';
        _isSaving = false;
      });
    }
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo obrigatorio.';
    }

    return null;
  }

  String? _optionalCnpj(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.isEmpty || digits.length == 14) {
      return null;
    }

    return 'Informe 14 numeros para o CNPJ.';
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
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

String? _formatCnpj(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }

  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');

  if (digits.length != 14) {
    return value;
  }

  return '${digits.substring(0, 2)}.${digits.substring(2, 5)}.${digits.substring(5, 8)}/${digits.substring(8, 12)}-${digits.substring(12, 14)}';
}
