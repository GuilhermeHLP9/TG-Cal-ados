import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/services/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../orders/data/order_store.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({
    super.key,
    required this.store,
    this.customers = const [],
  });

  final OrderStore store;
  final List<CustomerItem> customers;

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _soleTypeController = TextEditingController();
  final _sizesController = TextEditingController();
  final _quantityController = TextEditingController();
  final _materialsController = TextEditingController();
  final _referencePhotoController = TextEditingController();
  final _priceController = TextEditingController();
  final _dateController = TextEditingController();
  final _notesController = TextEditingController();
  String? _selectedCustomerId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedCustomerId =
        widget.customers.isEmpty ? null : widget.customers.first.id;
  }

  @override
  void dispose() {
    _soleTypeController.dispose();
    _sizesController.dispose();
    _quantityController.dispose();
    _materialsController.dispose();
    _referencePhotoController.dispose();
    _priceController.dispose();
    _dateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F3F4),
      appBar: AppBar(
        title: const Text('Novo pedido'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const _CreateOrderHeader(),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.customers.isNotEmpty) ...[
                      _CustomerSelector(
                        customers: widget.customers,
                        value: _selectedCustomerId,
                        onChanged: (value) {
                          setState(() => _selectedCustomerId = value);
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    _Field(
                      label: 'Tipo de sola',
                      hint: 'Ex.: Casual, Runner, Street',
                      controller: _soleTypeController,
                      validator: _required,
                    ),
                    _QuickSizeChips(
                      onSelected: (value) => _sizesController.text = value,
                    ),
                    const SizedBox(height: 4),
                    _Field(
                      label: 'Tamanhos / numeracao',
                      hint: 'Ex.: 34 ao 40, grade 36/37/38',
                      controller: _sizesController,
                      validator: _required,
                    ),
                    _Field(
                      label: 'Quantidade de pares',
                      hint: 'Ex.: 120',
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      validator: _positiveInt,
                    ),
                    _Field(
                      label: 'Materiais',
                      hint: 'Ex.: Borracha preta, EVA branco',
                      controller: _materialsController,
                      maxLines: 2,
                      validator: _required,
                    ),
                    _Field(
                      label: 'Foto de referencia',
                      controller: _referencePhotoController,
                      customField: _ReferenceImageField(
                        controller: _referencePhotoController,
                      ),
                    ),
                    _Field(
                      label: 'Preco por par',
                      hint: 'Ex.: 18.50',
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      validator: _positiveMoney,
                    ),
                    _OrderTotalPreview(
                      quantityController: _quantityController,
                      priceController: _priceController,
                    ),
                    const SizedBox(height: 10),
                    _Field(
                      label: 'Data de entrega desejada',
                      hint: 'Ex.: 20/06/2026',
                      controller: _dateController,
                      keyboardType: TextInputType.number,
                      inputFormatters: const [_DateInputFormatter()],
                      validator: _date,
                    ),
                    _Field(
                      label: 'Observacoes e avisos',
                      hint: 'Detalhes importantes do pedido',
                      controller: _notesController,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submit,
                        icon: const Icon(Icons.send),
                        label: Text(
                          _isSubmitting ? 'Enviando...' : 'Revisar e enviar',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final customerId = _selectedCustomerId;

    if (widget.customers.isNotEmpty && customerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um cliente para o pedido.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final quantity = int.parse(_quantityController.text.trim());
    final price = double.parse(
      _priceController.text.trim().replaceAll(',', '.'),
    );
    final shouldSubmit = await _showReview(quantity: quantity, price: price);

    if (!shouldSubmit || !mounted) {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
      return;
    }

    try {
      await widget.store.addOrder(
        customerId: customerId,
        productName: _soleTypeController.text.trim(),
        sizes: _sizesController.text.trim(),
        materials: _materialsController.text.trim(),
        quantity: quantity,
        pricePerPair: price,
        dueDate: _dateController.text.trim(),
        referencePhoto: _referencePhotoController.text.trim(),
        notes: _notesController.text.trim(),
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
      setState(() => _isSubmitting = false);
      return;
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nao foi possivel criar o pedido.')),
      );
      setState(() => _isSubmitting = false);
      return;
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pedido criado com sucesso.')),
    );

    Navigator.of(context).pop();
  }

  Future<bool> _showReview({
    required int quantity,
    required double price,
  }) async {
    final total = quantity * price;

    return await showModalBottomSheet<bool>(
          context: context,
          showDragHandle: true,
          builder: (context) {
            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Revisar pedido',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (widget.customers.isNotEmpty)
                      _ReviewLine(
                        label: 'Cliente',
                        value: _selectedCustomer?.name ?? 'Cliente',
                      ),
                    _ReviewLine(label: 'Tipo de sola', value: _soleTypeController.text),
                    _ReviewLine(label: 'Tamanhos', value: _sizesController.text),
                    _ReviewLine(label: 'Materiais', value: _materialsController.text),
                    _ReviewLine(label: 'Quantidade', value: '$quantity pares'),
                    _ReviewLine(label: 'Preco por par', value: 'R\$ ${price.toStringAsFixed(2)}'),
                    _ReviewLine(label: 'Total estimado', value: 'R\$ ${total.toStringAsFixed(2)}'),
                    _ReviewLine(label: 'Entrega', value: _dateController.text),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Editar'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Confirmar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ) ??
        false;
  }

  CustomerItem? get _selectedCustomer {
    final id = _selectedCustomerId;

    if (id == null) {
      return null;
    }

    for (final customer in widget.customers) {
      if (customer.id == id) {
        return customer;
      }
    }

    return null;
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo obrigatorio.';
    }

    return null;
  }

  String? _positiveInt(String? value) {
    final number = int.tryParse(value?.trim() ?? '');

    if (number == null || number <= 0) {
      return 'Informe um numero maior que zero.';
    }

    return null;
  }

  String? _positiveMoney(String? value) {
    final number = double.tryParse((value ?? '').trim().replaceAll(',', '.'));

    if (number == null || number <= 0) {
      return 'Informe um valor maior que zero.';
    }

    return null;
  }

  String? _date(String? value) {
    final text = value?.trim() ?? '';
    final match = RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(text);

    if (!match) {
      return 'Use o formato dd/mm/aaaa.';
    }

    final day = int.tryParse(text.substring(0, 2));
    final month = int.tryParse(text.substring(3, 5));
    final year = int.tryParse(text.substring(6, 10));

    if (day == null ||
        month == null ||
        year == null ||
        day < 1 ||
        day > 31 ||
        month < 1 ||
        month > 12 ||
        year < 2026) {
      return 'Informe uma data valida.';
    }

    return null;
  }
}

class _CreateOrderHeader extends StatelessWidget {
  const _CreateOrderHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Criar pedido',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Escolha o cliente e informe os detalhes do solado para producao.',
          style: TextStyle(
            color: AppColors.muted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _CustomerSelector extends StatelessWidget {
  const _CustomerSelector({
    required this.customers,
    required this.value,
    required this.onChanged,
  });

  final List<CustomerItem> customers;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      items: customers
          .map(
            (customer) => DropdownMenuItem(
              value: customer.id,
              child: Text(
                customer.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Selecione um cliente.';
        }

        return null;
      },
      decoration: const InputDecoration(
        labelText: 'Cliente',
        prefixIcon: Icon(Icons.storefront),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.hint = '',
    this.customField,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.maxLines = 1,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final Widget? customField;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          customField ??
              TextFormField(
                controller: controller,
                keyboardType: keyboardType,
                inputFormatters: inputFormatters,
                maxLines: maxLines,
                validator: validator,
                decoration: InputDecoration(hintText: hint),
              ),
        ],
      ),
    );
  }
}

class _QuickSizeChips extends StatelessWidget {
  const _QuickSizeChips({required this.onSelected});

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    const options = ['33 ao 38', '34 ao 40', '36 ao 42', '38 ao 44'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options
            .map(
              (option) => ActionChip(
                label: Text(option),
                onPressed: () => onSelected(option),
                avatar: const Icon(Icons.straighten, size: 18),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _OrderTotalPreview extends StatefulWidget {
  const _OrderTotalPreview({
    required this.quantityController,
    required this.priceController,
  });

  final TextEditingController quantityController;
  final TextEditingController priceController;

  @override
  State<_OrderTotalPreview> createState() => _OrderTotalPreviewState();
}

class _OrderTotalPreviewState extends State<_OrderTotalPreview> {
  @override
  void initState() {
    super.initState();
    widget.quantityController.addListener(_sync);
    widget.priceController.addListener(_sync);
  }

  @override
  void dispose() {
    widget.quantityController.removeListener(_sync);
    widget.priceController.removeListener(_sync);
    super.dispose();
  }

  void _sync() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final quantity = int.tryParse(widget.quantityController.text.trim()) ?? 0;
    final price = double.tryParse(
          widget.priceController.text.trim().replaceAll(',', '.'),
        ) ??
        0;
    final total = quantity * price;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3F7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.payments_outlined, color: AppColors.primary),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Total estimado',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Text(
            'R\$ ${total.toStringAsFixed(2)}',
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewLine extends StatelessWidget {
  const _ReviewLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferenceImageField extends StatefulWidget {
  const _ReferenceImageField({
    required this.controller,
  });

  final TextEditingController controller;

  @override
  State<_ReferenceImageField> createState() => _ReferenceImageFieldState();
}

class _ReferenceImageFieldState extends State<_ReferenceImageField> {
  @override
  Widget build(BuildContext context) {
    final hasImage = widget.controller.text.isNotEmpty;

    return OutlinedButton.icon(
      onPressed: () {
        setState(() {
          widget.controller.text = 'referencia_solado.jpg';
        });
      },
      icon: Icon(hasImage ? Icons.check_circle : Icons.image_outlined),
      label: Text(hasImage ? widget.controller.text : 'Selecionar imagem'),
    );
  }
}

class _DateInputFormatter extends TextInputFormatter {
  const _DateInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final limited = digits.length > 8 ? digits.substring(0, 8) : digits;
    final buffer = StringBuffer();

    for (var i = 0; i < limited.length; i++) {
      if (i == 2 || i == 4) {
        buffer.write('/');
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
