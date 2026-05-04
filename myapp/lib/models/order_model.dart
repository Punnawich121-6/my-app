class OrderItem {
  final int id;
  final String name;
  final double price;
  final int quantity;
  final String? note;

  OrderItem({required this.id, required this.name, required this.price, required this.quantity, this.note});

  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
        id: j['id'],
        name: j['name'],
        price: double.parse(j['price'].toString()),
        quantity: j['quantity'],
        note: j['note'],
      );
}

class Order {
  final int id;
  final int storeId;
  final String customerName;
  final String? customerPhone;
  final String status;
  final double totalAmount;
  final double deliveryFee;
  final String? note;
  final String? address;
  final String? itemsSummary;
  final List<OrderItem> items;
  final DateTime createdAt;

  Order({
    required this.id,
    required this.storeId,
    required this.customerName,
    this.customerPhone,
    required this.status,
    required this.totalAmount,
    required this.deliveryFee,
    this.note,
    this.address,
    this.itemsSummary,
    this.items = const [],
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> j) => Order(
        id: j['id'],
        storeId: j['store_id'],
        customerName: j['customer_name'] ?? 'Customer',
        customerPhone: j['customer_phone'],
        status: j['status'],
        totalAmount: double.parse(j['total_amount'].toString()),
        deliveryFee: double.parse((j['delivery_fee'] ?? 0).toString()),
        note: j['note'],
        address: j['address'],
        itemsSummary: j['items_summary'],
        items: (j['items'] as List<dynamic>? ?? []).map((e) => OrderItem.fromJson(e)).toList(),
        createdAt: DateTime.parse(j['created_at']),
      );

  static const statusLabel = {
    'pending':    'รอรับออเดอร์',
    'accepted':   'รับแล้ว รอทำ',
    'preparing':  'กำลังทำอาหาร',
    'ready':      'อาหารพร้อม รอส่ง',
    'delivering': 'กำลังจัดส่ง',
    'completed':  'ส่งสำเร็จ',
    'cancelled':  'ยกเลิก',
  };

  static const nextStatus = {
    'pending': 'accepted',
    'accepted': 'preparing',
    'preparing': 'ready',
    'ready': 'delivering',
    'delivering': 'completed',
  };

  String get label => statusLabel[status] ?? status;
  String? get next => nextStatus[status];
}
