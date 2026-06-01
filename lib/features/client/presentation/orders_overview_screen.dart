import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'create_order_screen.dart';
import '../../orders/data/order_store.dart';
import '../../orders/presentation/order_detail_screen.dart';
import '../../orders/presentation/widgets/order_card.dart';

class OrdersOverviewScreen extends StatelessWidget {
  const OrdersOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = OrderScope.of(context);
    final orders = store.orders;

    if (store.isLoading && orders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (store.error != null && orders.isEmpty) {
      return _OrdersError(
        message: store.error!,
        onRetry: store.loadOrders,
      );
    }

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
                    MaterialPageRoute(
                      builder: (_) => CreateOrderScreen(store: store),
                    ),
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

        final order = orders[index - 1];

        return OrderCard(
          order: order,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => OrderDetailScreen(
                  orderId: order.id,
                  store: store,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _OrdersError extends StatelessWidget {
  const _OrdersError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
