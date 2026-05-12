import 'package:flutter/material.dart';

import '../../../core/widgets/section_heading.dart';
import '../../orders/data/mock_orders.dart';
import '../../orders/presentation/widgets/order_card.dart';

class OwnerOrdersScreen extends StatelessWidget {
  const OwnerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: mockOrders.length + 1,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        if (index == 0) {
          return const SectionHeading(
            title: 'Pedidos recebidos',
            subtitle: 'Fluxo inicial para aceitar, recusar ou concluir pedidos.',
          );
        }

        return OrderCard(
          order: mockOrders[index - 1],
          actions: [
            ElevatedButton(
              onPressed: () {},
              child: const Text('Aceitar pedido'),
            ),
            OutlinedButton(
              onPressed: () {},
              child: const Text('Recusar pedido'),
            ),
          ],
        );
      },
    );
  }
}
