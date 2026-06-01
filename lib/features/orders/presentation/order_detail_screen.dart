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
