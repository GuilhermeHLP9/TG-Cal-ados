import 'package:flutter/material.dart';

import '../../../../core/models/order.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';

class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.order,
    this.actions = const [],
  });

  final Order order;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order.id,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Text(
                order.statusLabel,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(order.productName, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Cliente: ${order.clientName}'),
          Text('Quantidade: ${order.quantity} pares'),
          Text('Entrega: ${order.dueDate}'),
          Text('Preco por par: R\$ ${order.pricePerPair.toStringAsFixed(2)}'),
          if (order.notes != null) ...[
            const SizedBox(height: 8),
            Text('Obs: ${order.notes!}'),
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Column(
              children: actions
                  .map((action) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: action,
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}
