import 'package:flutter/material.dart';

import '../../../core/models/order.dart';
import '../../../core/services/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../data/order_store.dart';

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({
    super.key,
    required this.orderId,
    required this.store,
    this.canManage = false,
  });

  final String orderId;
  final OrderStore store;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final order = store.findById(orderId);

    if (order == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF0F3F4),
        appBar: AppBar(
          title: const Text('Pedido'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Pedido nao encontrado.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F3F4),
      appBar: AppBar(
        title: Text(order.id),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          order.productName,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                      const SizedBox(width: 12),
                      _StatusBadge(label: order.statusLabel),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _ProgressTracker(status: order.status),
                  const SizedBox(height: 18),
                  _InfoLine(label: 'Cliente', value: order.clientName),
                  _InfoLine(label: 'Tipo de sola', value: order.productName),
                  _InfoLine(label: 'Tamanhos', value: order.sizes),
                  _InfoLine(label: 'Materiais', value: order.materials),
                  _InfoLine(
                    label: 'Quantidade',
                    value: '${order.quantity} pares',
                  ),
                  _InfoLine(
                    label: 'Preco por par',
                    value: 'R\$ ${order.pricePerPair.toStringAsFixed(2)}',
                  ),
                  _InfoLine(
                    label: 'Total',
                    value: 'R\$ ${order.totalPrice.toStringAsFixed(2)}',
                  ),
                  _InfoLine(label: 'Entrega', value: order.dueDate),
                  if (order.referencePhoto != null &&
                      order.referencePhoto!.isNotEmpty)
                    _ReferenceImage(name: order.referencePhoto!),
                  if (order.notes != null && order.notes!.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Text(
                      'Observacoes',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(order.notes!),
                  ],
                ],
              ),
            ),
            if (canManage) ...[
              const SizedBox(height: 16),
              _FinancialCard(order: order, store: store),
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _buildActions(context, store, order),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActions(
    BuildContext context,
    OrderStore store,
    Order order,
  ) {
    if (order.status == OrderStatus.recebido) {
      return [
        ElevatedButton(
          onPressed: () async {
            await _updateStatus(context, store, order.id, OrderStatus.novo);
          },
          child: const Text('Aceitar pedido'),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: () async {
            await _updateStatus(context, store, order.id, OrderStatus.recusado);
          },
          child: const Text('Recusar pedido'),
        ),
      ];
    }

    if (order.status == OrderStatus.novo) {
      return [
        ElevatedButton(
          onPressed: () async {
            await _updateStatus(
              context,
              store,
              order.id,
              OrderStatus.emProducao,
            );
          },
          child: const Text('Colocar em producao'),
        ),
      ];
    }

    if (order.status == OrderStatus.emProducao) {
      return [
        ElevatedButton(
          onPressed: () async {
            await _updateStatus(
              context,
              store,
              order.id,
              OrderStatus.paraEntrega,
            );
          },
          child: const Text('Terminar pedido'),
        ),
      ];
    }

    return const [
      Text('Nenhuma acao disponivel para este status.'),
    ];
  }

  Future<void> _updateStatus(
    BuildContext context,
    OrderStore store,
    String orderId,
    OrderStatus status,
  ) async {
    try {
      await store.updateStatus(orderId, status);

      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } on ApiException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nao foi possivel atualizar o pedido.')),
        );
      }
    }
  }
}

class _FinancialCard extends StatefulWidget {
  const _FinancialCard({
    required this.order,
    required this.store,
  });

  final Order order;
  final OrderStore store;

  @override
  State<_FinancialCard> createState() => _FinancialCardState();
}

class _FinancialCardState extends State<_FinancialCard> {
  late final TextEditingController _materialCostController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _materialCostController = TextEditingController(
      text: widget.order.materialCost?.toStringAsFixed(2).replaceAll('.', ',') ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant _FinancialCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.order.id != widget.order.id ||
        oldWidget.order.materialCost != widget.order.materialCost) {
      _materialCostController.text =
          widget.order.materialCost?.toStringAsFixed(2).replaceAll('.', ',') ?? '';
    }
  }

  @override
  void dispose() {
    _materialCostController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cost = double.tryParse(
          _materialCostController.text.trim().replaceAll(',', '.'),
        ) ??
        widget.order.materialCost ??
        0;
    final profit = widget.order.totalPrice - cost;
    final margin = widget.order.totalPrice <= 0 ? 0 : profit / widget.order.totalPrice;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Financeiro',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _FinancialMetric(
                  label: 'Total',
                  value: 'R\$ ${widget.order.totalPrice.toStringAsFixed(2)}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FinancialMetric(
                  label: 'Lucro',
                  value: 'R\$ ${profit.toStringAsFixed(2)}',
                  danger: profit < 0,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FinancialMetric(
                  label: 'Margem',
                  value: '${(margin * 100).toStringAsFixed(1)}%',
                  danger: margin < 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _materialCostController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Custo de material',
              prefixText: 'R\$ ',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(_isSaving ? 'Salvando...' : 'Salvar financeiro'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final materialCost = double.tryParse(
      _materialCostController.text.trim().replaceAll(',', '.'),
    );

    if (materialCost == null || materialCost < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um custo valido.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await widget.store.updateFinancial(
        orderId: widget.order.id,
        materialCost: materialCost,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Financeiro atualizado.')),
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
        const SnackBar(content: Text('Nao foi possivel salvar o financeiro.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class _FinancialMetric extends StatelessWidget {
  const _FinancialMetric({
    required this.label,
    required this.value,
    this.danger = false,
  });

  final String label;
  final String value;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: danger
            ? AppColors.danger.withValues(alpha: 0.08)
            : const Color(0xFFEAF3F7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
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
              color: danger ? AppColors.danger : AppColors.primaryDark,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressTracker extends StatelessWidget {
  const _ProgressTracker({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final steps = [
      (OrderStatus.recebido, 'Recebido', Icons.inbox_outlined),
      (OrderStatus.novo, 'Aceito', Icons.playlist_add_check),
      (OrderStatus.emProducao, 'Producao', Icons.precision_manufacturing_outlined),
      (OrderStatus.paraEntrega, 'Entrega', Icons.local_shipping_outlined),
    ];
    final current = _statusStep(status);
    final refused = status == OrderStatus.recusado;

    if (refused) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.24)),
        ),
        child: const Row(
          children: [
            Icon(Icons.block, color: AppColors.danger),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Pedido recusado pelo fornecedor.',
                style: TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final done = index <= current;

        return Expanded(
          child: Column(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: done ? AppColors.primary : AppColors.border,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  step.$3,
                  size: 18,
                  color: done ? Colors.white : AppColors.muted,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                step.$2,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: done ? AppColors.primaryDark : AppColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        );
      }),
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primaryDark,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferenceImage extends StatelessWidget {
  const _ReferenceImage({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3F7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.image_outlined, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
