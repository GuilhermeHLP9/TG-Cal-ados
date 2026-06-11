import 'package:flutter/material.dart';

import '../../../../core/models/order.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';

class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.order,
    this.onTap,
  });

  final Order order;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pedido ${order.displayCode}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  order.statusLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.primary,
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
            if (order.notes != null && order.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                order.notes!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            ],
            if (order.refusalReason != null &&
                order.refusalReason!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Motivo da recusa: ${order.refusalReason!}',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            if (onTap != null) ...[
              const SizedBox(height: 12),
              Row(
                children: const [
                  Text(
                    'Ver detalhes',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_right, color: AppColors.primary),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
