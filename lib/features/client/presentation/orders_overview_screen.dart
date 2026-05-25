import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'create_order_screen.dart';
import '../../orders/data/order_store.dart';
import '../../orders/presentation/widgets/order_card.dart';

class OrdersOverviewScreen extends StatelessWidget {
  const OrdersOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = OrderScope.of(context).orders;

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: orders.length + 1,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Row(
            children: [
              const Expanded(
                child: Text(
                  'Pedidos',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                ),
              ),
              IconButton.filled(
                tooltip: 'Criar pedido',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CreateOrderScreen()),
                  );
                },
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.add),
              ),
            ],
          );
        }

        return OrderCard(order: orders[index - 1]);
      },
    );
  }
}
