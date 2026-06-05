import 'package:flutter/material.dart';

import '../../../core/models/order.dart';
import '../../../core/services/api_client.dart';
import 'mock_orders.dart';

class OrderStore extends ChangeNotifier {
  OrderStore.demo()
      : _apiClient = null,
        _token = null,
        _orders = List<Order>.from(mockOrders);

  OrderStore.api({
    required ApiClient apiClient,
    required String token,
  })  : _apiClient = apiClient,
        _token = token,
        _orders = [] {
    loadOrders();
  }

  final List<Order> _orders;
  final ApiClient? _apiClient;
  final String? _token;
  bool _isLoading = false;
  String? _error;

  List<Order> get orders => List.unmodifiable(_orders);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Order? findById(String orderId) {
    for (final order in _orders) {
      if (order.id == orderId) {
        return order;
      }
    }

    return null;
  }

  Future<void> loadOrders() async {
    final apiClient = _apiClient;
    final token = _token;

    if (apiClient == null || token == null) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final orders = await apiClient.listOrders(token);
      _orders
        ..clear()
        ..addAll(orders);
    } on ApiException catch (error) {
      _error = error.message;
    } catch (_) {
      _error = 'Nao foi possivel carregar os pedidos.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addOrder({
    String? customerId,
    required String productName,
    required String sizes,
    required String materials,
    required int quantity,
    required double pricePerPair,
    required String dueDate,
    String? referencePhoto,
    String? notes,
  }) async {
    final apiClient = _apiClient;
    final token = _token;

    if (apiClient != null && token != null) {
      final order = await apiClient.createOrder(
        token: token,
        customerId: customerId,
        productName: productName,
        sizes: sizes,
        materials: materials,
        quantity: quantity,
        pricePerPair: pricePerPair,
        dueDate: dueDate,
        referencePhoto: referencePhoto,
        notes: notes,
      );

      _orders.insert(0, order);
      notifyListeners();
      return;
    }

    final nextId = 'PED-${(_orders.length + 1).toString().padLeft(3, '0')}';

    _orders.insert(
      0,
      Order(
        id: nextId,
        customerId: customerId,
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

  Future<void> updateStatus(String orderId, OrderStatus status) async {
    final apiClient = _apiClient;
    final token = _token;
    final index = _orders.indexWhere((order) => order.id == orderId);

    if (index == -1) {
      return;
    }

    if (apiClient != null && token != null) {
      _orders[index] = await apiClient.updateOrderStatus(
        token: token,
        orderId: orderId,
        status: status,
      );
    } else {
      _orders[index] = _orders[index].copyWith(status: status);
    }

    notifyListeners();
  }

  Future<void> updateFinancial({
    required String orderId,
    required double materialCost,
  }) async {
    final apiClient = _apiClient;
    final token = _token;
    final index = _orders.indexWhere((order) => order.id == orderId);

    if (index == -1) {
      return;
    }

    if (apiClient != null && token != null) {
      _orders[index] = await apiClient.updateOrderFinancial(
        token: token,
        orderId: orderId,
        materialCost: materialCost,
      );
    } else {
      final order = _orders[index];
      _orders[index] = order.copyWith(
        materialCost: materialCost,
        apiTotalPrice: order.totalPrice,
        profit: order.totalPrice - materialCost,
      );
    }

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
