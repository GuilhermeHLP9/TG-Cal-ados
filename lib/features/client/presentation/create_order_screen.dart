import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../orders/data/order_store.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _soleTypeController = TextEditingController();
  final _sizesController = TextEditingController();
  final _quantityController = TextEditingController();
  final _materialsController = TextEditingController();
  final _referencePhotoController = TextEditingController();
  final _priceController = TextEditingController();
  final _dateController = TextEditingController();
  final _notesController = TextEditingController();

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
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Field(
                    label: 'Tipo de sola',
                    hint: 'Ex.: Casual, Runner, Street',
                    controller: _soleTypeController,
                  ),
                  _Field(
                    label: 'Tamanhos / numeracao',
                    hint: 'Ex.: 34 ao 40, grade 36/37/38',
                    controller: _sizesController,
                  ),
                  _Field(
                    label: 'Quantidade de pares',
                    hint: 'Ex.: 120',
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                  ),
                  _Field(
                    label: 'Materiais',
                    hint: 'Ex.: Borracha preta, EVA branco',
                    controller: _materialsController,
                    maxLines: 2,
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
                  ),
                  _Field(
                    label: 'Data de entrega desejada',
                    hint: 'Ex.: 20/06/2026',
                    controller: _dateController,
                    keyboardType: TextInputType.number,
                    inputFormatters: const [_DateInputFormatter()],
                  ),
                  _Field(
                    label: 'Observacoes e avisos',
                    hint: 'Detalhes importantes do pedido',
                    controller: _notesController,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.send),
                    label: const Text('Enviar pedido'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final quantity = int.tryParse(_quantityController.text.trim());
    final price = double.tryParse(
      _priceController.text.trim().replaceAll(',', '.'),
    );

    if (_soleTypeController.text.trim().isEmpty ||
        _sizesController.text.trim().isEmpty ||
        _materialsController.text.trim().isEmpty ||
        _dateController.text.trim().isEmpty ||
        quantity == null ||
        price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha os campos obrigatorios do pedido.'),
        ),
      );
      return;
    }

    OrderScope.of(context).addOrder(
      productName: _soleTypeController.text.trim(),
      sizes: _sizesController.text.trim(),
      materials: _materialsController.text.trim(),
      quantity: quantity,
      pricePerPair: price,
      dueDate: _dateController.text.trim(),
      referencePhoto: _referencePhotoController.text.trim(),
      notes: _notesController.text.trim(),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pedido criado com sucesso.')),
    );

    Navigator.of(context).pop();
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
    this.maxLines = 1,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final Widget? customField;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
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
              TextField(
                controller: controller,
                keyboardType: keyboardType,
                inputFormatters: inputFormatters,
                maxLines: maxLines,
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
