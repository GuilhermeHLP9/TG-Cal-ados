import 'package:flutter/material.dart';

import '../../../core/models/order.dart';
import 'mock_orders.dart';

class OrderStore extends ChangeNotifier {
  OrderStore() : _orders = List<Order>.from(mockOrders);

  final List<Order> _orders;

  List<Order> get orders => List.unmodifiable(_orders);

  void addOrder({
    required String productName,
    required String sizes,
    required String materials,
    required int quantity,
    required double pricePerPair,
    required String dueDate,
    String? referencePhoto,
    String? notes,
  }) {
    final nextId = 'PED-${(_orders.length + 1).toString().padLeft(3, '0')}';

    _orders.insert(
      0,
      Order(
        id: nextId,
        clientName: 'Cliente',
        productName: productName,
        sizes: sizes,
        materials: materials,
        quantity: quantity,
        pricePerPair: pricePerPair,
        dueDate: dueDate,
        status: OrderStatus.recebido,
        referencePhoto: referencePhoto,
        notes: notes,
      ),
    );

    notifyListeners();
  }

  void updateStatus(String orderId, OrderStatus status) {
    final index = _orders.indexWhere((order) => order.id == orderId);

    if (index == -1) {
      return;
    }

    _orders[index] = _orders[index].copyWith(status: status);
    notifyListeners();
  }
}

class OrderScope extends InheritedNotifier<OrderStore> {
  const OrderScope({
    super.key,
    required OrderStore store,
    required super.child,
  }) : super(notifier: store);

  static OrderStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<OrderScope>();

    assert(scope != null, 'OrderScope nao encontrado na arvore de widgets.');

    return scope!.notifier!;
  }
}
