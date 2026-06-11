import 'package:flutter/material.dart';

import '../../../core/models/order.dart';
import '../../../core/services/api_client.dart';
import '../../../core/theme/app_theme.dart';
import 'create_order_screen.dart';
import '../../orders/data/order_store.dart';
import '../../orders/presentation/order_detail_screen.dart';

enum _ClientOrderFilter {
  all,
  open,
  production,
  delivery,
  refused,
}

class OrdersOverviewScreen extends StatefulWidget {
  const OrdersOverviewScreen({
    super.key,
    required this.user,
  });

  final AuthUser user;

  @override
  State<OrdersOverviewScreen> createState() => _OrdersOverviewScreenState();
}

class _OrdersOverviewScreenState extends State<OrdersOverviewScreen> {
  final _searchController = TextEditingController();
  _ClientOrderFilter _filter = _ClientOrderFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = OrderScope.of(context);
    final orders = store.orders;
    final visibleOrders = _filterOrders(orders);

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
          _ClientOrdersHeader(
            totalOrders: orders.length,
            visibleOrders: visibleOrders.length,
            canCreate: widget.user.canCreateOrders,
            onCreate: () => _openCreateOrder(store),
          ),
          if (!widget.user.canCreateOrders) ...[
            const SizedBox(height: 12),
            _ApprovalPendingNotice(status: widget.user.customer?.status),
          ],
          if (store.error != null) ...[
            const SizedBox(height: 12),
            _InlineError(message: store.error!),
          ],
          const SizedBox(height: 16),
          _FilterStrip(
            selected: _filter,
            orders: orders,
            onSelected: (filter) => setState(() => _filter = filter),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Buscar por produto, material ou ID',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 18),
          if (visibleOrders.isEmpty)
            _EmptyOrders(
              hasOrders: orders.isNotEmpty,
              onClear: _clearFilters,
            )
          else
            ...visibleOrders.map(
              (order) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _ClientOrderCard(
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
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _filter = _ClientOrderFilter.all;
      _searchController.clear();
    });
  }

  void _openCreateOrder(OrderStore store) {
    if (!widget.user.canCreateOrders) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aguarde o proprietario aceitar seu cadastro.'),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateOrderScreen(store: store),
      ),
    );
  }

  List<Order> _filterOrders(List<Order> orders) {
    final search = _searchController.text.trim().toLowerCase();

    return orders.where((order) {
      final matchesFilter = switch (_filter) {
        _ClientOrderFilter.all => true,
        _ClientOrderFilter.open =>
          order.status == OrderStatus.recebido || order.status == OrderStatus.novo,
        _ClientOrderFilter.production => order.status == OrderStatus.emProducao,
        _ClientOrderFilter.delivery => order.status == OrderStatus.paraEntrega,
        _ClientOrderFilter.refused => order.status == OrderStatus.recusado,
      };

      if (!matchesFilter) {
        return false;
      }

      if (search.isEmpty) {
        return true;
      }

      return order.id.toLowerCase().contains(search) ||
          order.productName.toLowerCase().contains(search) ||
          order.materials.toLowerCase().contains(search);
    }).toList();
  }
}

class _ClientOrdersHeader extends StatelessWidget {
  const _ClientOrdersHeader({
    required this.totalOrders,
    required this.visibleOrders,
    required this.canCreate,
    required this.onCreate,
  });

  final int totalOrders;
  final int visibleOrders;
  final bool canCreate;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Meus pedidos',
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$visibleOrders exibidos de $totalOrders pedidos',
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        IconButton.filled(
          tooltip: 'Criar pedido',
          onPressed: canCreate ? onCreate : null,
          style: IconButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}

class _FilterStrip extends StatelessWidget {
  const _FilterStrip({
    required this.selected,
    required this.orders,
    required this.onSelected,
  });

  final _ClientOrderFilter selected;
  final List<Order> orders;
  final ValueChanged<_ClientOrderFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final items = [
      (_ClientOrderFilter.all, 'Todos', orders.length),
      (_ClientOrderFilter.open, 'Abertos', _countOpen()),
      (_ClientOrderFilter.production, 'Producao', _count(OrderStatus.emProducao)),
      (_ClientOrderFilter.delivery, 'Entrega', _count(OrderStatus.paraEntrega)),
      (_ClientOrderFilter.refused, 'Recusados', _count(OrderStatus.recusado)),
    ];

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          final isSelected = selected == item.$1;

          return ChoiceChip(
            selected: isSelected,
            label: Text('${item.$2} (${item.$3})'),
            onSelected: (_) => onSelected(item.$1),
            selectedColor: colors.primary,
            labelStyle: TextStyle(
              color: isSelected ? colors.onPrimary : colors.primary,
              fontWeight: FontWeight.w800,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
              side: BorderSide(
                color: isSelected ? colors.primary : colors.outlineVariant,
              ),
            ),
          );
        },
      ),
    );
  }

  int _count(OrderStatus status) {
    return orders.where((order) => order.status == status).length;
  }

  int _countOpen() {
    return orders
        .where(
          (order) =>
              order.status == OrderStatus.recebido ||
              order.status == OrderStatus.novo,
        )
        .length;
  }
}

class _ApprovalPendingNotice extends StatelessWidget {
  const _ApprovalPendingNotice({required this.status});

  final String? status;

  @override
  Widget build(BuildContext context) {
    final rejected = status == 'REJECTED';
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: (rejected ? AppColors.danger : colors.primary)
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (rejected ? AppColors.danger : colors.primary)
              .withValues(alpha: 0.24),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            rejected ? Icons.block : Icons.hourglass_top_outlined,
            color: rejected ? AppColors.danger : colors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              rejected
                  ? 'Seu cadastro foi recusado pelo proprietario.'
                  : 'Seu cadastro ainda precisa ser aceito pelo proprietario para criar pedidos.',
              style: TextStyle(
                color: colors.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientOrderCard extends StatelessWidget {
  const _ClientOrderCard({
    required this.order,
    required this.onTap,
  });

  final Order order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      order.productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _StatusBadge(status: order.status),
                ],
              ),
              const SizedBox(height: 12),
              _ProgressLine(status: order.status),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _InfoPill(
                    icon: Icons.confirmation_number_outlined,
                    label: order.displayCode,
                  ),
                  _InfoPill(icon: Icons.inventory_2_outlined, label: '${order.quantity} pares'),
                  _InfoPill(icon: Icons.event_outlined, label: order.dueDate),
                  _InfoPill(
                    icon: Icons.payments_outlined,
                    label: 'R\$ ${order.totalPrice.toStringAsFixed(2)}',
                  ),
                ],
              ),
              if (order.refusalReason != null &&
                  order.refusalReason!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  'Motivo da recusa: ${order.refusalReason!}',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: const [
                  Text(
                    'Acompanhar pedido',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_right, color: AppColors.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final current = _statusStep(status);

    return Row(
      children: List.generate(4, (index) {
        final done = index <= current && status != OrderStatus.recusado;

        return Expanded(
          child: Container(
            height: 5,
            margin: EdgeInsets.only(right: index == 3 ? 0 : 5),
            decoration: BoxDecoration(
              color: done ? AppColors.primary : AppColors.border,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      }),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: colors.primary, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: colors.primary,
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
    final color = status == OrderStatus.recusado ? AppColors.danger : AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        orderStatusShortLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders({
    required this.hasOrders,
    required this.onClear,
  });

  final bool hasOrders;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        children: [
          const Icon(Icons.assignment_outlined, color: AppColors.primary, size: 42),
          const SizedBox(height: 12),
          Text(
            hasOrders
                ? 'Nenhum pedido encontrado para os filtros atuais.'
                : 'Voce ainda nao criou nenhum pedido.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          if (hasOrders) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onClear,
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
    return Text(
      message,
      style: const TextStyle(
        color: AppColors.danger,
        fontWeight: FontWeight.w800,
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

int _statusStep(OrderStatus status) {
  switch (status) {
    case OrderStatus.recebido:
      return 0;
    case OrderStatus.novo:
      return 1;
    case OrderStatus.emProducao:
      return 2;
    case OrderStatus.paraEntrega:
      return 3;
    case OrderStatus.recusado:
      return -1;
  }
}
