import 'package:flutter/material.dart';

import '../../../core/models/order.dart';
import '../../../core/services/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../client/presentation/create_order_screen.dart';
import '../../customers/data/customer_store.dart';
import '../../orders/data/order_store.dart';
import '../../orders/presentation/order_detail_screen.dart';

enum _OwnerOrderFilter {
  general,
  received,
  newOrders,
  inProduction,
  readyForDelivery,
  refused,
}

enum _OrderSort {
  recent,
  dueDate,
  client,
  totalValue,
}

class OwnerOrdersScreen extends StatefulWidget {
  const OwnerOrdersScreen({
    super.key,
    required this.customerStore,
  });

  final CustomerStore customerStore;

  @override
  State<OwnerOrdersScreen> createState() => _OwnerOrdersScreenState();
}

class _OwnerOrdersScreenState extends State<OwnerOrdersScreen> {
  final _searchController = TextEditingController();
  _OwnerOrderFilter _selectedFilter = _OwnerOrderFilter.general;
  _OrderSort _sort = _OrderSort.recent;

  @override
  void initState() {
    super.initState();
    widget.customerStore.addListener(_syncCustomers);
  }

  @override
  void dispose() {
    widget.customerStore.removeListener(_syncCustomers);
    _searchController.dispose();
    super.dispose();
  }

  void _syncCustomers() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final store = OrderScope.of(context);
    final orders = store.orders;
    final filteredOrders = _filterAndSortOrders(orders);

    if (store.isLoading && orders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (store.error != null && orders.isEmpty) {
      return _OrdersError(
        message: store.error!,
        onRetry: store.loadOrders,
      );
    }

    return RefreshIndicator(
      onRefresh: store.loadOrders,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _OrdersHeader(
            totalOrders: orders.length,
            visibleOrders: filteredOrders.length,
            isLoading: store.isLoading,
            onRefresh: store.loadOrders,
            onCreate: () => _openCreateOrder(store),
          ),
          if (store.error != null) ...[
            const SizedBox(height: 12),
            _InlineError(message: store.error!),
          ],
          const SizedBox(height: 16),
          _FinancialSummary(orders: orders),
          const SizedBox(height: 16),
          _StatusOverview(
            selectedFilter: _selectedFilter,
            orders: orders,
            onSelect: _select,
          ),
          const SizedBox(height: 16),
          _SearchAndSortBar(
            controller: _searchController,
            sort: _sort,
            onSearchChanged: (_) => setState(() {}),
            onSortChanged: (sort) => setState(() => _sort = sort),
          ),
          const SizedBox(height: 18),
          if (filteredOrders.isEmpty)
            _EmptyOrders(
              hasOrders: orders.isNotEmpty,
              onClearFilters: _clearFilters,
            )
          else
            ...filteredOrders.map(
              (order) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _OwnerOrderCard(
                  order: order,
                  onOpen: () => _openDetail(store, order),
                  onAdvance: _nextStatus(order) == null
                      ? null
                      : () => _advanceOrder(store, order),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _select(_OwnerOrderFilter filter) {
    setState(() => _selectedFilter = filter);
  }

  void _clearFilters() {
    setState(() {
      _selectedFilter = _OwnerOrderFilter.general;
      _sort = _OrderSort.recent;
      _searchController.clear();
    });
  }

  void _openDetail(OrderStore store, Order order) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderDetailScreen(
          orderId: order.id,
          store: store,
          canManage: true,
        ),
      ),
    );
  }

  Future<void> _openCreateOrder(OrderStore store) async {
    if (widget.customerStore.customers.isEmpty &&
        !widget.customerStore.isLoading) {
      await widget.customerStore.loadCustomers();
    }

    if (!mounted) {
      return;
    }

    if (widget.customerStore.customers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cadastre um cliente antes de criar pedidos.'),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateOrderScreen(
          store: store,
          customers: widget.customerStore.customers,
        ),
      ),
    );
  }

  Future<void> _advanceOrder(OrderStore store, Order order) async {
    final nextStatus = _nextStatus(order);

    if (nextStatus == null) {
      return;
    }

    try {
      await store.updateStatus(order.id, nextStatus);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pedido atualizado para ${_statusLabel(nextStatus)}.')),
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nao foi possivel atualizar o pedido.')),
      );
    }
  }

  List<Order> _filterAndSortOrders(List<Order> orders) {
    final search = _searchController.text.trim().toLowerCase();

    final filtered = orders.where((order) {
      final matchesStatus = switch (_selectedFilter) {
        _OwnerOrderFilter.general => true,
        _OwnerOrderFilter.received => order.status == OrderStatus.recebido,
        _OwnerOrderFilter.newOrders => order.status == OrderStatus.novo,
        _OwnerOrderFilter.inProduction =>
          order.status == OrderStatus.emProducao,
        _OwnerOrderFilter.readyForDelivery =>
          order.status == OrderStatus.paraEntrega,
        _OwnerOrderFilter.refused => order.status == OrderStatus.recusado,
      };

      if (!matchesStatus) {
        return false;
      }

      if (search.isEmpty) {
        return true;
      }

      return order.id.toLowerCase().contains(search) ||
          order.clientName.toLowerCase().contains(search) ||
          order.productName.toLowerCase().contains(search);
    }).toList();

    filtered.sort((a, b) {
      switch (_sort) {
        case _OrderSort.recent:
          return 0;
        case _OrderSort.dueDate:
          return _dateValue(a.dueDate).compareTo(_dateValue(b.dueDate));
        case _OrderSort.client:
          return a.clientName.toLowerCase().compareTo(b.clientName.toLowerCase());
        case _OrderSort.totalValue:
          return b.totalPrice.compareTo(a.totalPrice);
      }
    });

    return filtered;
  }

  OrderStatus? _nextStatus(Order order) {
    switch (order.status) {
      case OrderStatus.recebido:
        return OrderStatus.novo;
      case OrderStatus.novo:
        return OrderStatus.emProducao;
      case OrderStatus.emProducao:
        return OrderStatus.paraEntrega;
      case OrderStatus.paraEntrega:
      case OrderStatus.recusado:
        return null;
    }
  }
}

class _FinancialSummary extends StatelessWidget {
  const _FinancialSummary({required this.orders});

  final List<Order> orders;

  @override
  Widget build(BuildContext context) {
    final revenue = orders.fold<double>(
      0,
      (total, order) => total + order.totalPrice,
    );
    final costs = orders.fold<double>(
      0,
      (total, order) => total + (order.materialCost ?? 0),
    );
    final profit = revenue - costs;
    final margin = revenue <= 0 ? 0 : profit / revenue;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.95,
      children: [
        _FinancialSummaryCard(
          label: 'Faturamento',
          value: 'R\$ ${revenue.toStringAsFixed(2)}',
          icon: Icons.payments_outlined,
        ),
        _FinancialSummaryCard(
          label: 'Custos',
          value: 'R\$ ${costs.toStringAsFixed(2)}',
          icon: Icons.receipt_long_outlined,
        ),
        _FinancialSummaryCard(
          label: 'Lucro',
          value: 'R\$ ${profit.toStringAsFixed(2)}',
          icon: Icons.trending_up,
          danger: profit < 0,
        ),
        _FinancialSummaryCard(
          label: 'Margem',
          value: '${(margin * 100).toStringAsFixed(1)}%',
          icon: Icons.percent,
          danger: margin < 0,
        ),
      ],
    );
  }
}

class _FinancialSummaryCard extends StatelessWidget {
  const _FinancialSummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    this.danger = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.danger : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: danger ? AppColors.danger : AppColors.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrdersHeader extends StatelessWidget {
  const _OrdersHeader({
    required this.totalOrders,
    required this.visibleOrders,
    required this.isLoading,
    required this.onRefresh,
    required this.onCreate,
  });

  final int totalOrders;
  final int visibleOrders;
  final bool isLoading;
  final VoidCallback onRefresh;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pedidos',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$visibleOrders exibidos de $totalOrders pedidos',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Column(
          children: [
            IconButton.filled(
              tooltip: 'Criar pedido',
              onPressed: onCreate,
              icon: const Icon(Icons.add),
            ),
            const SizedBox(height: 8),
            IconButton.filledTonal(
              tooltip: 'Atualizar pedidos',
              onPressed: isLoading ? null : onRefresh,
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatusOverview extends StatelessWidget {
  const _StatusOverview({
    required this.selectedFilter,
    required this.orders,
    required this.onSelect,
  });

  final _OwnerOrderFilter selectedFilter;
  final List<Order> orders;
  final ValueChanged<_OwnerOrderFilter> onSelect;

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatusFilterItem(
        filter: _OwnerOrderFilter.general,
        label: 'Geral',
        icon: Icons.grid_view_outlined,
        count: orders.length,
      ),
      _StatusFilterItem(
        filter: _OwnerOrderFilter.received,
        label: 'Recebidos',
        icon: Icons.inbox_outlined,
        count: _countByStatus(OrderStatus.recebido),
      ),
      _StatusFilterItem(
        filter: _OwnerOrderFilter.newOrders,
        label: 'Novos',
        icon: Icons.playlist_add_check,
        count: _countByStatus(OrderStatus.novo),
      ),
      _StatusFilterItem(
        filter: _OwnerOrderFilter.inProduction,
        label: 'Producao',
        icon: Icons.precision_manufacturing_outlined,
        count: _countByStatus(OrderStatus.emProducao),
      ),
      _StatusFilterItem(
        filter: _OwnerOrderFilter.readyForDelivery,
        label: 'Entrega',
        icon: Icons.local_shipping_outlined,
        count: _countByStatus(OrderStatus.paraEntrega),
      ),
      _StatusFilterItem(
        filter: _OwnerOrderFilter.refused,
        label: 'Recusados',
        icon: Icons.block,
        count: _countByStatus(OrderStatus.recusado),
      ),
    ];

    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          return _StatusFilterCard(
            item: item,
            selected: selectedFilter == item.filter,
            onTap: () => onSelect(item.filter),
          );
        },
      ),
    );
  }

  int _countByStatus(OrderStatus status) {
    return orders.where((order) => order.status == status).length;
  }
}

class _SearchAndSortBar extends StatelessWidget {
  const _SearchAndSortBar({
    required this.controller,
    required this.sort,
    required this.onSearchChanged,
    required this.onSortChanged,
  });

  final TextEditingController controller;
  final _OrderSort sort;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<_OrderSort> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onSearchChanged,
            decoration: const InputDecoration(
              hintText: 'Buscar por cliente, produto ou ID',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        const SizedBox(width: 10),
        PopupMenuButton<_OrderSort>(
          tooltip: 'Ordenar pedidos',
          onSelected: onSortChanged,
          itemBuilder: (context) => const [
            PopupMenuItem(value: _OrderSort.recent, child: Text('Mais recentes')),
            PopupMenuItem(value: _OrderSort.dueDate, child: Text('Entrega proxima')),
            PopupMenuItem(value: _OrderSort.client, child: Text('Cliente A-Z')),
            PopupMenuItem(value: _OrderSort.totalValue, child: Text('Maior valor')),
          ],
          child: Container(
            height: 54,
            width: 54,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.sort, color: AppColors.primary),
          ),
        ),
      ],
    );
  }
}

class _OwnerOrderCard extends StatelessWidget {
  const _OwnerOrderCard({
    required this.order,
    required this.onOpen,
    required this.onAdvance,
  });

  final Order order;
  final VoidCallback onOpen;
  final VoidCallback? onAdvance;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.productName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.clientName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _StatusBadge(status: order.status),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _MetricPill(
                    icon: Icons.confirmation_number_outlined,
                    label: _shortId(order.id),
                  ),
                  _MetricPill(
                    icon: Icons.inventory_2_outlined,
                    label: '${order.quantity} pares',
                  ),
                  _MetricPill(
                    icon: Icons.event_outlined,
                    label: order.dueDate,
                  ),
                  _MetricPill(
                    icon: Icons.payments_outlined,
                    label: 'R\$ ${order.totalPrice.toStringAsFixed(2)}',
                  ),
                ],
              ),
              if (order.notes != null && order.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  order.notes!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: onOpen,
                    icon: const Icon(Icons.visibility_outlined),
                    label: const Text('Detalhes'),
                  ),
                  const Spacer(),
                  if (onAdvance != null)
                    FilledButton.tonalIcon(
                      onPressed: onAdvance,
                      icon: const Icon(Icons.arrow_forward),
                      label: Text(_advanceLabel(order.status)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3F7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _StatusFilterCard extends StatelessWidget {
  const _StatusFilterCard({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _StatusFilterItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 132,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    item.icon,
                    color: selected ? Colors.white : AppColors.primary,
                    size: 22,
                  ),
                  const Spacer(),
                  Text(
                    item.count.toString(),
                    style: TextStyle(
                      color: selected ? Colors.white : AppColors.primaryDark,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusFilterItem {
  const _StatusFilterItem({
    required this.filter,
    required this.label,
    required this.icon,
    required this.count,
  });

  final _OwnerOrderFilter filter;
  final String label;
  final IconData icon;
  final int count;
}

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders({
    required this.hasOrders,
    required this.onClearFilters,
  });

  final bool hasOrders;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.assignment_outlined, color: AppColors.primary, size: 42),
          const SizedBox(height: 12),
          Text(
            hasOrders
                ? 'Nenhum pedido encontrado para os filtros atuais.'
                : 'Nenhum pedido cadastrado ainda.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          if (hasOrders) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onClearFilters,
              icon: const Icon(Icons.filter_alt_off_outlined),
              label: const Text('Limpar filtros'),
            ),
          ],
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
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

String _shortId(String id) {
  if (id.length <= 8) {
    return id;
  }

  return id.substring(0, 8);
}

String _statusLabel(OrderStatus status) {
  switch (status) {
    case OrderStatus.recebido:
      return 'Recebido';
    case OrderStatus.novo:
      return 'Novo';
    case OrderStatus.emProducao:
      return 'Producao';
    case OrderStatus.paraEntrega:
      return 'Entrega';
    case OrderStatus.recusado:
      return 'Recusado';
  }
}

String _advanceLabel(OrderStatus status) {
  switch (status) {
    case OrderStatus.recebido:
      return 'Aceitar';
    case OrderStatus.novo:
      return 'Produzir';
    case OrderStatus.emProducao:
      return 'Finalizar';
    case OrderStatus.paraEntrega:
    case OrderStatus.recusado:
      return '';
  }
}

Color _statusColor(OrderStatus status) {
  switch (status) {
    case OrderStatus.recebido:
      return AppColors.accent;
    case OrderStatus.novo:
      return AppColors.primary;
    case OrderStatus.emProducao:
      return const Color(0xFF9A6B00);
    case OrderStatus.paraEntrega:
      return const Color(0xFF1D7A36);
    case OrderStatus.recusado:
      return AppColors.danger;
  }
}

int _dateValue(String value) {
  final parts = value.split('/');

  if (parts.length != 3) {
    return 99999999;
  }

  final day = int.tryParse(parts[0]) ?? 31;
  final month = int.tryParse(parts[1]) ?? 12;
  final year = int.tryParse(parts[2]) ?? 9999;

  return year * 10000 + month * 100 + day;
}
