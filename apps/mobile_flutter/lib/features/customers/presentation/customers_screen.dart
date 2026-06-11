import 'package:flutter/material.dart';
import '../../../core/services/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../orders/data/order_store.dart';
import '../../orders/presentation/order_detail_screen.dart';
import '../../orders/presentation/widgets/order_card.dart';
import '../data/customer_store.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({
    super.key,
    required this.store,
  });

  final CustomerStore store;

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_sync);
  }

  @override
  void dispose() {
    widget.store.removeListener(_sync);
    _searchController.dispose();
    super.dispose();
  }

  void _sync() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final search = _searchController.text.trim().toLowerCase();
    final customers = widget.store.customers.where((customer) {
      if (search.isEmpty) {
        return true;
      }

      return customer.name.toLowerCase().contains(search) ||
          (customer.cnpj ?? '').contains(search);
    }).toList();
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: widget.store.loadCustomers,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Clientes',
                        style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${customers.length} exibidos de ${widget.store.customers.length} clientes',
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Atualizar clientes',
                  onPressed:
                      widget.store.isLoading ? null : widget.store.loadCustomers,
                  icon: widget.store.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                ),
              ],
            ),
            if (widget.store.error != null) ...[
              const SizedBox(height: 12),
              _InlineError(message: widget.store.error!),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Buscar por nome ou CNPJ',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 18),
            if (widget.store.isLoading && widget.store.customers.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (customers.isEmpty)
              AppCard(
                child: Column(
                  children: [
                    const Icon(
                      Icons.people_alt_outlined,
                      color: AppColors.primary,
                      size: 42,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.store.customers.isEmpty
                          ? 'Nenhum cliente cadastrado ainda.'
                          : 'Nenhum cliente encontrado.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              )
            else
              ...customers.map(
                (customer) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _CustomerCard(
                    customer: customer,
                    onOpen: () => _openCustomerOrders(customer),
                    onApprove: () => _changeStatus(customer, 'APPROVED'),
                    onReject: () => _changeStatus(customer, 'REJECTED'),
                    onDelete: () => _confirmDelete(customer),
                  ),
                ),
              ),
            const SizedBox(height: 76),
          ],
        ),
      ),
    );
  }

  void _openCustomerOrders(CustomerItem customer) {
    final orderStore = OrderScope.of(context);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _CustomerOrdersScreen(
          customer: customer,
          store: orderStore,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(CustomerItem customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir cliente'),
          content: Text(
            'Excluir "${customer.name}"? Clientes com pedidos vinculados nao podem ser excluidos.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await widget.store.deleteCustomer(customer.id);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cliente excluido.')),
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
        const SnackBar(content: Text('Nao foi possivel excluir o cliente.')),
      );
    }
  }

  Future<void> _changeStatus(CustomerItem customer, String status) async {
    try {
      await widget.store.updateStatus(customer.id, status);

      if (!mounted) {
        return;
      }

      final message =
          status == 'APPROVED' ? 'Cliente aprovado.' : 'Cliente recusado.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
        const SnackBar(content: Text('Nao foi possivel atualizar o cliente.')),
      );
    }
  }
}

class _CustomerOrdersScreen extends StatelessWidget {
  const _CustomerOrdersScreen({
    required this.customer,
    required this.store,
  });

  final CustomerItem customer;
  final OrderStore store;

  @override
  Widget build(BuildContext context) {
    final orders = store.orders
        .where((order) => order.customerId == customer.id)
        .toList(growable: false);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(customer.name),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: store.loadOrders,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Pedidos do cliente',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              '${orders.length} pedidos vinculados',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Telefone: ${_formatPhone(customer.phone) ?? 'Nao informado'}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            if (store.isLoading && store.orders.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (orders.isEmpty)
              AppCard(
                child: Column(
                  children: [
                    const Icon(
                      Icons.assignment_outlined,
                      color: AppColors.primary,
                      size: 42,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Nenhum pedido vinculado a este cliente ainda.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: store.loadOrders,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Atualizar'),
                    ),
                  ],
                ),
              )
            else
              ...orders.map(
                (order) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: OrderCard(
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
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({
    required this.customer,
    required this.onOpen,
    required this.onApprove,
    required this.onReject,
    required this.onDelete,
  });

  final CustomerItem customer;
  final VoidCallback onOpen;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.storefront, color: colors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _formatCnpj(customer.cnpj) ?? 'CNPJ nao informado',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _formatPhone(customer.phone) ?? 'Telefone nao informado',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _CustomerStatusBadge(customer: customer),
                  PopupMenuButton<String>(
                    tooltip: 'Acoes do cliente',
                    onSelected: (value) {
                      if (value == 'delete') {
                        onDelete();
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: AppColors.danger),
                            SizedBox(width: 10),
                            Text('Excluir'),
                          ],
                        ),
                      ),
                    ],
                    icon: const Icon(Icons.more_vert),
                  ),
                ],
              ),
              if (customer.isPending) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: FilledButton.icon(
                          onPressed: onApprove,
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Aceitar'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: OutlinedButton.icon(
                          onPressed: onReject,
                          icon: const Icon(Icons.block),
                          label: const Text('Recusar'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomerStatusBadge extends StatelessWidget {
  const _CustomerStatusBadge({required this.customer});

  final CustomerItem customer;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = customer.isApproved
        ? colors.primary
        : customer.isPending
            ? const Color(0xFFE2A800)
            : AppColors.danger;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        customer.statusLabel,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
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

String? _formatCnpj(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }

  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');

  if (digits.length != 14) {
    return value;
  }

  return '${digits.substring(0, 2)}.${digits.substring(2, 5)}.${digits.substring(5, 8)}/${digits.substring(8, 12)}-${digits.substring(12, 14)}';
}

String? _formatPhone(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }

  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length == 10) {
    return '(${digits.substring(0, 2)}) ${digits.substring(2, 6)}-${digits.substring(6, 10)}';
  }
  if (digits.length == 11) {
    return '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-${digits.substring(7, 11)}';
  }

  return value;
}
