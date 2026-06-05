import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/order.dart';

class ApiClient {
  ApiClient({
    http.Client? httpClient,
    String baseUrl = const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:3333/api',
    ),
  })  : _httpClient = httpClient ?? http.Client(),
        _baseUrl = baseUrl;

  final http.Client _httpClient;
  final String _baseUrl;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _post(
      '/auth/login',
      body: {
        'email': email,
        'password': password,
      },
    );

    return AuthSession.fromJson(response);
  }

  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
    required String companyName,
    required String companyCnpj,
    required String role,
  }) async {
    final response = await _post(
      '/auth/register',
      body: {
        'name': name,
        'email': email,
        'password': password,
        'companyName': companyName,
        'companyCnpj': companyCnpj,
        'role': role,
      },
    );

    return AuthSession.fromJson(response);
  }

  Future<bool> isEmailAvailable(String email) async {
    final response = await _get(
      '/auth/email-available?email=${Uri.encodeQueryComponent(email)}',
    );
    final json = response as Map<String, dynamic>;
    return json['available'] == true;
  }

  Future<AuthUser> getMe(String token) async {
    final response = await _get('/me', token: token);
    return AuthUser.fromJson(response as Map<String, dynamic>);
  }

  Future<AuthUser> updateMe({
    required String token,
    String? name,
    String? currentPassword,
    String? newPassword,
    String? companyName,
    String? companyCnpj,
  }) async {
    final response = await _patch(
      '/me',
      token: token,
      body: {
        if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
        if (currentPassword != null && currentPassword.isNotEmpty)
          'currentPassword': currentPassword,
        if (newPassword != null && newPassword.isNotEmpty)
          'newPassword': newPassword,
        if (companyName != null && companyName.trim().isNotEmpty)
          'companyName': companyName.trim(),
        if (companyCnpj != null && companyCnpj.trim().isNotEmpty)
          'companyCnpj': companyCnpj.trim(),
      },
    );

    return AuthUser.fromJson(response as Map<String, dynamic>);
  }

  Future<List<Order>> listOrders(String token) async {
    final response = await _get('/orders', token: token);
    final items = response as List<dynamic>;
    return items
        .map((item) => OrderDto.fromJson(item as Map<String, dynamic>).toOrder())
        .toList();
  }

  Future<Order> createOrder({
    required String token,
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
    final response = await _post(
      '/orders',
      token: token,
      body: {
        if (customerId != null && customerId.isNotEmpty)
          'customerId': customerId,
        'productName': productName,
        'sizes': sizes,
        'materials': materials,
        'quantity': quantity,
        'pricePerPair': pricePerPair,
        'dueDate': dueDate,
        if (referencePhoto != null && referencePhoto.isNotEmpty)
          'referencePhoto': referencePhoto,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );

    return OrderDto.fromJson(response as Map<String, dynamic>).toOrder();
  }

  Future<List<CustomerItem>> listCustomers(String token) async {
    final response = await _get('/customers', token: token);
    final items = response as List<dynamic>;
    return items
        .map((item) => CustomerItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<CustomerItem> createCustomer({
    required String token,
    required String name,
    String? cnpj,
  }) async {
    final response = await _post(
      '/customers',
      token: token,
      body: {
        'name': name,
        if (cnpj != null && cnpj.trim().isNotEmpty) 'cnpj': cnpj,
      },
    );

    return CustomerItem.fromJson(response as Map<String, dynamic>);
  }

  Future<CustomerItem> updateCustomer({
    required String token,
    required String id,
    String? name,
    String? cnpj,
  }) async {
    final response = await _patch(
      '/customers/$id',
      token: token,
      body: {
        ...?name != null && name.trim().isNotEmpty
            ? {'name': name.trim()}
            : null,
        ...?cnpj != null ? {'cnpj': cnpj} : null,
      },
    );

    return CustomerItem.fromJson(response as Map<String, dynamic>);
  }

  Future<Order> updateOrderStatus({
    required String token,
    required String orderId,
    required OrderStatus status,
  }) async {
    final response = await _patch(
      '/orders/$orderId/status',
      token: token,
      body: {'status': status.toApiValue()},
    );

    return OrderDto.fromJson(response as Map<String, dynamic>).toOrder();
  }

  Future<Order> updateOrderFinancial({
    required String token,
    required String orderId,
    required double materialCost,
  }) async {
    final response = await _patch(
      '/orders/$orderId/financial',
      token: token,
      body: {'materialCost': materialCost},
    );

    return OrderDto.fromJson(response as Map<String, dynamic>).toOrder();
  }

  Future<List<NoteItem>> listNotes(String token) async {
    final response = await _get('/notes', token: token);
    final items = response as List<dynamic>;
    return items
        .map((item) => NoteItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<NoteItem> createNote({
    required String token,
    String? title,
    String? content,
  }) async {
    final body = <String, dynamic>{};
    final trimmedTitle = title?.trim();
    if (trimmedTitle != null && trimmedTitle.isNotEmpty) {
      body['title'] = trimmedTitle;
    }
    if (content != null) {
      body['content'] = content;
    }

    final response = await _post(
      '/notes',
      token: token,
      body: body,
    );

    return NoteItem.fromJson(response as Map<String, dynamic>);
  }

  Future<NoteItem> updateNote({
    required String token,
    required String id,
    String? title,
    String? content,
    bool? isFavorite,
  }) async {
    final body = <String, dynamic>{};
    final trimmedTitle = title?.trim();
    if (trimmedTitle != null && trimmedTitle.isNotEmpty) {
      body['title'] = trimmedTitle;
    }
    if (content != null) {
      body['content'] = content;
    }
    if (isFavorite != null) {
      body['isFavorite'] = isFavorite;
    }

    final response = await _patch(
      '/notes/$id',
      token: token,
      body: body,
    );

    return NoteItem.fromJson(response as Map<String, dynamic>);
  }

  Future<int> deleteNotes({
    required String token,
    required List<String> ids,
  }) async {
    final response = await _delete(
      '/notes',
      token: token,
      body: {'ids': ids},
    );
    final json = response as Map<String, dynamic>;
    return json['deleted'] as int;
  }

  Future<dynamic> _get(String path, {String? token}) async {
    final response = await _httpClient.get(
      Uri.parse('$_baseUrl$path'),
      headers: _headers(token),
    );

    return _decode(response);
  }

  Future<dynamic> _post(
    String path, {
    String? token,
    required Map<String, dynamic> body,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('$_baseUrl$path'),
      headers: _headers(token),
      body: jsonEncode(body),
    );

    return _decode(response);
  }

  Future<dynamic> _patch(
    String path, {
    required String token,
    required Map<String, dynamic> body,
  }) async {
    final response = await _httpClient.patch(
      Uri.parse('$_baseUrl$path'),
      headers: _headers(token),
      body: jsonEncode(body),
    );

    return _decode(response);
  }

  Future<dynamic> _delete(
    String path, {
    required String token,
    required Map<String, dynamic> body,
  }) async {
    final response = await _httpClient.delete(
      Uri.parse('$_baseUrl$path'),
      headers: _headers(token),
      body: jsonEncode(body),
    );

    return _decode(response);
  }

  Map<String, String> _headers(String? token) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  dynamic _decode(http.Response response) {
    final body = response.body.isEmpty ? null : jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final message = body is Map<String, dynamic>
        ? body['message']?.toString()
        : 'Erro ao comunicar com a API.';

    throw ApiException(message ?? 'Erro ao comunicar com a API.');
  }
}

class CustomerItem {
  const CustomerItem({
    required this.id,
    required this.name,
    this.cnpj,
  });

  final String id;
  final String name;
  final String? cnpj;

  factory CustomerItem.fromJson(Map<String, dynamic> json) {
    return CustomerItem(
      id: json['id'] as String,
      name: json['name'] as String,
      cnpj: json['cnpj'] as String?,
    );
  }
}

class NoteItem {
  const NoteItem({
    required this.id,
    required this.title,
    required this.content,
    required this.isFavorite,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String content;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory NoteItem.fromJson(Map<String, dynamic> json) {
    return NoteItem(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      isFavorite: json['isFavorite'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updatedAt'] as String).toLocal(),
    );
  }
}

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthSession {
  const AuthSession({
    required this.token,
    required this.user,
  });

  final String token;
  final AuthUser user;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      token: json['token'] as String,
      user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.company,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final AuthCompany? company;

  bool get isOwner => role == 'OWNER';

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      company: json['company'] == null
          ? null
          : AuthCompany.fromJson(json['company'] as Map<String, dynamic>),
    );
  }
}

class AuthCompany {
  const AuthCompany({
    required this.id,
    required this.name,
    this.email,
    this.cnpj,
  });

  final String id;
  final String name;
  final String? email;
  final String? cnpj;

  factory AuthCompany.fromJson(Map<String, dynamic> json) {
    return AuthCompany(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      cnpj: json['cnpj'] as String?,
    );
  }
}

class OrderDto {
  const OrderDto({
    required this.id,
    this.customerId,
    required this.clientName,
    required this.productName,
    required this.sizes,
    required this.materials,
    required this.quantity,
    required this.pricePerPair,
    required this.dueDate,
    required this.status,
    this.materialCost,
    this.totalPrice,
    this.profit,
    this.referencePhoto,
    this.notes,
  });

  final String id;
  final String? customerId;
  final String clientName;
  final String productName;
  final String sizes;
  final String materials;
  final int quantity;
  final double pricePerPair;
  final String dueDate;
  final OrderStatus status;
  final double? materialCost;
  final double? totalPrice;
  final double? profit;
  final String? referencePhoto;
  final String? notes;

  factory OrderDto.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] as Map<String, dynamic>?;
    final client = json['client'] as Map<String, dynamic>?;

    return OrderDto(
      id: json['id'] as String,
      customerId: customer?['id']?.toString(),
      clientName: customer?['name']?.toString() ??
          client?['name']?.toString() ??
          'Cliente',
      productName: json['productName'] as String,
      sizes: json['sizes'] as String,
      materials: json['materials'] as String,
      quantity: json['quantity'] as int,
      pricePerPair: _toDouble(json['pricePerPair']),
      dueDate: _formatApiDate(json['dueDate'] as String),
      status: orderStatusFromApi(json['status'] as String),
      materialCost: _optionalDouble(json['materialCost']),
      totalPrice: _optionalDouble(json['totalPrice']),
      profit: _optionalDouble(json['profit']),
      referencePhoto: json['referencePhoto'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Order toOrder() {
    return Order(
      id: id,
      customerId: customerId,
      clientName: clientName,
      productName: productName,
      sizes: sizes,
      materials: materials,
      quantity: quantity,
      pricePerPair: pricePerPair,
      dueDate: dueDate,
      status: status,
      materialCost: materialCost,
      apiTotalPrice: totalPrice,
      profit: profit,
      referencePhoto: referencePhoto,
      notes: notes,
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.parse(value.toString());
  }

  static double? _optionalDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    return _toDouble(value);
  }

  static String _formatApiDate(String value) {
    final date = DateTime.parse(value).toLocal();
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }
}

OrderStatus orderStatusFromApi(String value) {
  switch (value) {
    case 'RECEBIDO':
      return OrderStatus.recebido;
    case 'NOVO':
      return OrderStatus.novo;
    case 'EM_PRODUCAO':
      return OrderStatus.emProducao;
    case 'PARA_ENTREGA':
      return OrderStatus.paraEntrega;
    case 'RECUSADO':
      return OrderStatus.recusado;
  }

  throw ApiException('Status de pedido desconhecido: $value');
}

extension OrderStatusApiValue on OrderStatus {
  String toApiValue() {
    switch (this) {
      case OrderStatus.recebido:
        return 'RECEBIDO';
      case OrderStatus.novo:
        return 'NOVO';
      case OrderStatus.emProducao:
        return 'EM_PRODUCAO';
      case OrderStatus.paraEntrega:
        return 'PARA_ENTREGA';
      case OrderStatus.recusado:
        return 'RECUSADO';
    }
  }
}
