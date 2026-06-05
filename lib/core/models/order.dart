enum OrderStatus { recebido, novo, emProducao, paraEntrega, recusado }

class Order {
  const Order({
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
    this.apiTotalPrice,
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
  final double? apiTotalPrice;
  final double? profit;
  final String? referencePhoto;
  final String? notes;

  double get totalPrice => apiTotalPrice ?? quantity * pricePerPair;
  double get estimatedProfit => profit ?? totalPrice - (materialCost ?? 0);
  double get profitMargin => totalPrice <= 0 ? 0 : estimatedProfit / totalPrice;

  Order copyWith({
    String? id,
    String? customerId,
    String? clientName,
    String? productName,
    String? sizes,
    String? materials,
    int? quantity,
    double? pricePerPair,
    String? dueDate,
    OrderStatus? status,
    double? materialCost,
    double? apiTotalPrice,
    double? profit,
    String? referencePhoto,
    String? notes,
  }) {
    return Order(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      clientName: clientName ?? this.clientName,
      productName: productName ?? this.productName,
      sizes: sizes ?? this.sizes,
      materials: materials ?? this.materials,
      quantity: quantity ?? this.quantity,
      pricePerPair: pricePerPair ?? this.pricePerPair,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      materialCost: materialCost ?? this.materialCost,
      apiTotalPrice: apiTotalPrice ?? this.apiTotalPrice,
      profit: profit ?? this.profit,
      referencePhoto: referencePhoto ?? this.referencePhoto,
      notes: notes ?? this.notes,
    );
  }

  String get statusLabel {
    switch (status) {
      case OrderStatus.recebido:
        return 'Recebido';
      case OrderStatus.novo:
        return 'Pedido novo';
      case OrderStatus.emProducao:
        return 'Em producao';
      case OrderStatus.paraEntrega:
        return 'Pedido para entrega';
      case OrderStatus.recusado:
        return 'Recusado';
    }
  }
}

String orderStatusShortLabel(OrderStatus status) {
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
