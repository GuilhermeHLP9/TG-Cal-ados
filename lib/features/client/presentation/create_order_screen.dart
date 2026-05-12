import 'package:flutter/material.dart';

import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/section_heading.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _productController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _dateController = TextEditingController();

  @override
  void dispose() {
    _productController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SectionHeading(
          title: 'Novo pedido',
          subtitle: 'Formulario inicial do MVP para registrar um pedido novo.',
        ),
        const SizedBox(height: 20),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Produto'),
              const SizedBox(height: 8),
              TextField(controller: _productController),
              const SizedBox(height: 16),
              const Text('Quantidade'),
              const SizedBox(height: 8),
              TextField(controller: _quantityController, keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              const Text('Preco por par'),
              const SizedBox(height: 8),
              TextField(controller: _priceController, keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              const Text('Data desejada'),
              const SizedBox(height: 8),
              TextField(controller: _dateController),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fluxo pronto para integrar com a API.')),
                  );
                },
                child: const Text('Enviar pedido'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
