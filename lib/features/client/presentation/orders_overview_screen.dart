import 'package:flutter/material.dart';

import '../../../core/widgets/app_card.dart';
import '../../orders/data/mock_orders.dart';
import '../../orders/presentation/widgets/order_card.dart';

class OrdersOverviewScreen extends StatelessWidget {
  const OrdersOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: mockOrders.length + 1,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        if (index == 0) {
          return const AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pedidos',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 6),
                Text(
                  'Aqui vao aparecer os pedidos do cliente com o mesmo clima visual da tela principal.',
                ),
              ],
            ),
          );
        }

        return OrderCard(order: mockOrders[index - 1]);
      },
    );
  }
}
