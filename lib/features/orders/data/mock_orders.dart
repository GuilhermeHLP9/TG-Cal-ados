import '../../../core/models/order.dart';

const mockOrders = [
  Order(
    id: 'PED-001',
    clientName: 'Calcados Franca Norte',
    productName: 'Solado Runner',
    quantity: 120,
    pricePerPair: 18.5,
    dueDate: '2026-03-20',
    status: OrderStatus.novo,
    notes: 'Cor preta e branca',
  ),
  Order(
    id: 'PED-002',
    clientName: 'Atelie Couro Fino',
    productName: 'Solado Casual',
    quantity: 80,
    pricePerPair: 22.0,
    dueDate: '2026-03-18',
    status: OrderStatus.emProducao,
  ),
  Order(
    id: 'PED-003',
    clientName: 'Linha Urbana',
    productName: 'Solado Street',
    quantity: 60,
    pricePerPair: 25.0,
    dueDate: '2026-03-15',
    status: OrderStatus.concluido,
  ),
];
