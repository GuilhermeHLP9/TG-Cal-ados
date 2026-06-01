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
  });

  final OrderStore store;

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
  bool _isSubmitting = false;

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
            Form(
              key: _formKey,
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Field(
                      label: 'Tipo de sola',
                      hint: 'Ex.: Casual, Runner, Street',
                      controller: _soleTypeController,
                      validator: _required,
                    ),
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
                    ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _submit,
                      icon: const Icon(Icons.send),
                      label: Text(_isSubmitting ? 'Enviando...' : 'Enviar pedido'),
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

    setState(() => _isSubmitting = true);

    final quantity = int.parse(_quantityController.text.trim());
    final price = double.parse(
      _priceController.text.trim().replaceAll(',', '.'),
    );

    try {
      await widget.store.addOrder(
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
