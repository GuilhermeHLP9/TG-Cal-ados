enum OrderStatus { recebido, novo, emProducao, paraEntrega, recusado }

class Order {
  const Order({
    required this.id,
    required this.clientName,
    required this.productName,
    required this.sizes,
    required this.materials,
    required this.quantity,
    required this.pricePerPair,
    required this.dueDate,
    required this.status,
    this.referencePhoto,
    this.notes,
  });

  final String id;
  final String clientName;
  final String productName;
  final String sizes;
  final String materials;
  final int quantity;
  final double pricePerPair;
  final String dueDate;
  final OrderStatus status;
  final String? referencePhoto;
  final String? notes;

  Order copyWith({
    String? id,
    String? clientName,
    String? productName,
    String? sizes,
    String? materials,
    int? quantity,
    double? pricePerPair,
    String? dueDate,
    OrderStatus? status,
    String? referencePhoto,
    String? notes,
  }) {
    return Order(
      id: id ?? this.id,
      clientName: clientName ?? this.clientName,
      productName: productName ?? this.productName,
      sizes: sizes ?? this.sizes,
      materials: materials ?? this.materials,
      quantity: quantity ?? this.quantity,
      pricePerPair: pricePerPair ?? this.pricePerPair,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
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
