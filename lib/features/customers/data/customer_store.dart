import 'package:flutter/material.dart';

import '../../../core/services/api_client.dart';

class CustomerStore extends ChangeNotifier {
  CustomerStore({
    required ApiClient apiClient,
    required String token,
  })  : _apiClient = apiClient,
        _token = token {
    loadCustomers();
  }

  final ApiClient _apiClient;
  final String _token;
  final List<CustomerItem> _customers = [];
  bool _isLoading = false;
  String? _error;

  List<CustomerItem> get customers => List.unmodifiable(_customers);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadCustomers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final customers = await _apiClient.listCustomers(_token);
      _customers
        ..clear()
        ..addAll(customers);
    } on ApiException catch (error) {
      _error = error.message;
    } catch (_) {
      _error = 'Nao foi possivel carregar os clientes.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createCustomer({
    required String name,
    String? cnpj,
  }) async {
    final customer = await _apiClient.createCustomer(
      token: _token,
      name: name,
      cnpj: cnpj,
    );

    _customers.add(customer);
    _customers.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    notifyListeners();
  }

  Future<void> deleteCustomer(String id) async {
    await _apiClient.deleteCustomer(
      token: _token,
      id: id,
    );

    _customers.removeWhere((customer) => customer.id == id);
    notifyListeners();
  }

  Future<void> updateStatus(String id, String status) async {
    final customer = await _apiClient.updateCustomerStatus(
      token: _token,
      id: id,
      status: status,
    );

    final index = _customers.indexWhere((item) => item.id == id);
    if (index == -1) {
      _customers.add(customer);
    } else {
      _customers[index] = customer;
    }
    _customers.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    notifyListeners();
  }
}
