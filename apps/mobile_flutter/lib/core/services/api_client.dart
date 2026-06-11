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

  String get baseUrl => _baseUrl;

  Future<bool> checkHealth() async {
    final response = await _get('/health') as Map<String, dynamic>;
    return response['status'] == 'ok';
  }

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
    required String phone,
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
        'phone': phone,
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

  Future<void> requestPasswordReset(String email) async {
    await _post(
      '/auth/forgot-password',
      body: {'email': email.trim().toLowerCase()},
    );
  }

  Future<void> resetPassword({
    required String token,
    required String password,
  }) async {
    await _post(
      '/auth/reset-password',
      body: {
        'token': token.trim(),
        'password': password,
      },
    );
  }

  Future<AuthUser> getMe(String token) async {
    final response = await _get('/me', token: token);
    return AuthUser.fromJson(response as Map<String, dynamic>);
  }

  Future<void> registerNotificationDevice({
    required String token,
    required String deviceToken,
    String? platform,
  }) async {
    await _post(
      '/notifications/device',
      token: token,
      body: {
        'token': deviceToken,
        if (platform != null && platform.isNotEmpty) 'platform': platform,
      },
    );
  }

  Future<NotificationTestResult> testNotification(String token) async {
    final response = await _post(
      '/notifications/test',
      token: token,
      body: {},
    );

    return NotificationTestResult.fromJson(response as Map<String, dynamic>);
  }

  Future<AuthUser> updateMe({
    required String token,
    String? name,
    String? email,
    String? phone,
    String? profileImage,
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
        if (email != null && email.trim().isNotEmpty)
          'email': email.trim().toLowerCase(),
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        ...?profileImage == null ? null : {'profileImage': profileImage},
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
    String? phone,
  }) async {
    final response = await _post(
      '/customers',
      token: token,
      body: {
        'name': name,
        if (cnpj != null && cnpj.trim().isNotEmpty) 'cnpj': cnpj,
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone,
      },
    );

    return CustomerItem.fromJson(response as Map<String, dynamic>);
  }

  Future<int> deleteCustomer({
    required String token,
    required String id,
  }) async {
    final response = await _delete(
      '/customers/$id',
      token: token,
      body: {},
    );
    final json = response as Map<String, dynamic>;
    return json['deleted'] as int;
  }

  Future<CustomerItem> updateCustomerStatus({
    required String token,
    required String id,
    required String status,
  }) async {
    final response = await _patch(
      '/customers/$id/status',
      token: token,
      body: {'status': status},
    );

    return CustomerItem.fromJson(response as Map<String, dynamic>);
  }

  Future<Order> updateOrderStatus({
    required String token,
    required String orderId,
    required OrderStatus status,
    String? refusalReason,
  }) async {
    final response = await _patch(
      '/orders/$orderId/status',
      token: token,
      body: {
        'status': status.toApiValue(),
        if (refusalReason != null && refusalReason.trim().isNotEmpty)
          'refusalReason': refusalReason.trim(),
      },
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
    required this.status,
    this.cnpj,
    this.phone,
  });

  final String id;
  final String name;
  final String status;
  final String? cnpj;
  final String? phone;

  bool get isPending => status == 'PENDING';
  bool get isApproved => status == 'APPROVED';
  bool get isRejected => status == 'REJECTED';

  String get statusLabel {
    switch (status) {
      case 'PENDING':
        return 'Pendente';
      case 'APPROVED':
        return 'Aprovado';
      case 'REJECTED':
        return 'Recusado';
    }

    return 'Indefinido';
  }

  factory CustomerItem.fromJson(Map<String, dynamic> json) {
    return CustomerItem(
      id: json['id'] as String,
      name: json['name'] as String,
      status: json['status'] as String? ?? 'APPROVED',
      cnpj: json['cnpj'] as String?,
      phone: json['phone'] as String?,
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

class NotificationTestResult {
  const NotificationTestResult({
    required this.configured,
    required this.devices,
    required this.sent,
    required this.failed,
  });

  final bool configured;
  final int devices;
  final int sent;
  final int failed;

  bool get hasRegisteredDevice => devices > 0;
  bool get wasSent => sent > 0;

  factory NotificationTestResult.fromJson(Map<String, dynamic> json) {
    return NotificationTestResult(
      configured: json['configured'] == true,
      devices: _jsonToInt(json['devices']),
      sent: _jsonToInt(json['sent']),
      failed: _jsonToInt(json['failed']),
    );
  }

  static int _jsonToInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
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
    this.phone,
    this.profileImage,
    this.company,
    this.customer,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? profileImage;
  final AuthCompany? company;
  final AuthCustomer? customer;

  bool get isOwner => role == 'OWNER';
  bool get canCreateOrders => isOwner || customer?.status == 'APPROVED';

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      phone: json['phone'] as String?,
      profileImage: json['profileImage'] as String?,
      company: json['company'] == null
          ? null
          : AuthCompany.fromJson(json['company'] as Map<String, dynamic>),
      customer: json['customer'] == null
          ? null
          : AuthCustomer.fromJson(json['customer'] as Map<String, dynamic>),
    );
  }
}

class AuthCustomer {
  const AuthCustomer({
    required this.id,
    required this.status,
  });

  final String id;
  final String status;

  factory AuthCustomer.fromJson(Map<String, dynamic> json) {
    return AuthCustomer(
      id: json['id'] as String,
      status: json['status'] as String? ?? 'APPROVED',
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
    required this.number,
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
    this.refusalReason,
    this.notes,
  });

  final String id;
  final int number;
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
  final String? refusalReason;
  final String? notes;

  factory OrderDto.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] as Map<String, dynamic>?;
    final client = json['client'] as Map<String, dynamic>?;

    return OrderDto(
      id: json['id'] as String,
      number: _toInt(json['number']),
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
      refusalReason: json['refusalReason'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Order toOrder() {
    return Order(
      id: id,
      number: number,
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
      refusalReason: refusalReason,
      notes: notes,
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.parse(value.toString());
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.parse(value.toString());
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
