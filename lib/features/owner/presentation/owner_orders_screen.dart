import 'package:flutter/material.dart';

import '../../../core/models/order.dart';
import '../../../core/theme/app_theme.dart';
import '../../orders/data/order_store.dart';
import '../../orders/presentation/order_detail_screen.dart';
import '../../orders/presentation/widgets/order_card.dart';

enum _OwnerOrderFilter {
  general,
  received,
  newOrders,
  inProduction,
  readyForDelivery,
  refused,
}

class OwnerOrdersScreen extends StatefulWidget {
  const OwnerOrdersScreen({super.key});

  @override
  State<OwnerOrdersScreen> createState() => _OwnerOrdersScreenState();
}

class _OwnerOrdersScreenState extends State<OwnerOrdersScreen> {
  final _searchController = TextEditingController();
  _OwnerOrderFilter _selectedFilter = _OwnerOrderFilter.general;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = OrderScope.of(context);
    final orders = store.orders;
    final filteredOrders = _filterOrders(orders);

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
      itemCount: filteredOrders.length + 1,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pedidos',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _FilterButton(
                    label: 'Geral',
                    count: orders.length,
                    selected: _selectedFilter == _OwnerOrderFilter.general,
                    onTap: () => _select(_OwnerOrderFilter.general),
                  ),
                  _FilterButton(
                    label: 'Pedidos recebidos',
                    count: _countByStatus(orders, OrderStatus.recebido),
                    selected: _selectedFilter == _OwnerOrderFilter.received,
                    onTap: () => _select(_OwnerOrderFilter.received),
                  ),
                  _FilterButton(
                    label: 'Pedidos novos',
                    count: _countByStatus(orders, OrderStatus.novo),
                    selected: _selectedFilter == _OwnerOrderFilter.newOrders,
                    onTap: () => _select(_OwnerOrderFilter.newOrders),
                  ),
                  _FilterButton(
                    label: 'Em producao',
                    count: _countByStatus(orders, OrderStatus.emProducao),
                    selected: _selectedFilter == _OwnerOrderFilter.inProduction,
                    onTap: () => _select(_OwnerOrderFilter.inProduction),
                  ),
                  _FilterButton(
                    label: 'Pedido para entrega',
                    count: _countByStatus(orders, OrderStatus.paraEntrega),
                    selected:
                        _selectedFilter == _OwnerOrderFilter.readyForDelivery,
                    onTap: () => _select(_OwnerOrderFilter.readyForDelivery),
                  ),
                  _FilterButton(
                    label: 'Pedidos recusados',
                    count: _countByStatus(orders, OrderStatus.recusado),
                    selected: _selectedFilter == _OwnerOrderFilter.refused,
                    onTap: () => _select(_OwnerOrderFilter.refused),
                  ),
                ],
              ),
              if (_selectedFilter == _OwnerOrderFilter.general) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Procurar por ID do pedido',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ],
              if (filteredOrders.isEmpty) ...[
                const SizedBox(height: 20),
                const Text('Nenhum pedido encontrado para este filtro.'),
              ],
            ],
          );
        }

        final order = filteredOrders[index - 1];

        return OrderCard(
          order: order,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => OrderDetailScreen(
                  orderId: order.id,
                  store: store,
                  canManage: true,
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _select(_OwnerOrderFilter filter) {
    setState(() {
      _selectedFilter = filter;
      if (filter != _OwnerOrderFilter.general) {
        _searchController.clear();
      }
    });
  }

  List<Order> _filterOrders(List<Order> orders) {
    final baseOrders = switch (_selectedFilter) {
      _OwnerOrderFilter.general => orders,
      _OwnerOrderFilter.received =>
        orders.where((order) => order.status == OrderStatus.recebido).toList(),
      _OwnerOrderFilter.newOrders =>
        orders.where((order) => order.status == OrderStatus.novo).toList(),
      _OwnerOrderFilter.inProduction => orders
          .where((order) => order.status == OrderStatus.emProducao)
          .toList(),
      _OwnerOrderFilter.readyForDelivery => orders
          .where((order) => order.status == OrderStatus.paraEntrega)
          .toList(),
      _OwnerOrderFilter.refused =>
        orders.where((order) => order.status == OrderStatus.recusado).toList(),
    };

    final search = _searchController.text.trim().toLowerCase();

    if (_selectedFilter != _OwnerOrderFilter.general || search.isEmpty) {
      return baseOrders;
    }

    return baseOrders
        .where((order) => order.id.toLowerCase().contains(search))
        .toList();
  }

  int _countByStatus(List<Order> orders, OrderStatus status) {
    return orders.where((order) => order.status == status).length;
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

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          width: 154,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count.toString(),
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.primaryDark,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
