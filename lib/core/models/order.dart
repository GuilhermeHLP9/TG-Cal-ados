enum OrderStatus { novo, emProducao, concluido, recusado }

class Order {
  const Order({
    required this.id,
    required this.clientName,
    required this.productName,
    required this.quantity,
    required this.pricePerPair,
    required this.dueDate,
    required this.status,
    this.notes,
  });

  final String id;
  final String clientName;
  final String productName;
  final int quantity;
  final double pricePerPair;
  final String dueDate;
  final OrderStatus status;
  final String? notes;

  String get statusLabel {
    switch (status) {
      case OrderStatus.novo:
        return 'Novo';
      case OrderStatus.emProducao:
        return 'Em producao';
      case OrderStatus.concluido:
        return 'Concluido';
      case OrderStatus.recusado:
        return 'Recusado';
    }
  }
}
