class OrderItem {
  final String id;
  final String name;
  final double price;
  final int quantity;
  final String? note;

  OrderItem({required this.id, required this.name, required this.price, required this.quantity, this.note});

  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
        id: (j['id'] ?? j['menu_item_id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        price: double.tryParse((j['price'] ?? 0).toString()) ?? 0,
        quantity: int.tryParse((j['quantity'] ?? 0).toString()) ?? 0,
        note: j['note']?.toString(),
      );
}

class Order {
  final String id;
  final String storeId;
  final String customerName;
  final String? customerPhone;
  final String? riderId;
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
    this.riderId,
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
        id: (j['id'] ?? '').toString(),
        storeId: (j['store_id'] ?? j['restaurantId'] ?? '').toString(),
        customerName: (j['customer_name'] ?? j['customerName'] ?? 'Customer').toString(),
        customerPhone: (j['customer_phone'] ?? j['customerPhone'])?.toString(),
        riderId: (j['rider_id'] ?? j['riderId'])?.toString(),
        status: (j['status'] ?? 'pending').toString(),
        totalAmount: double.tryParse((j['total_amount'] ?? j['totalAmount'] ?? 0).toString()) ?? 0,
        deliveryFee: double.tryParse((j['delivery_fee'] ?? j['serviceFee'] ?? j['deliveryFee'] ?? 0).toString()) ?? 0,
        note: (j['note'] ?? j['notes'])?.toString(),
        address: j['address']?.toString(),
        itemsSummary: (j['items_summary'] ?? j['itemsSummary'])?.toString(),
        items: (j['items'] as List<dynamic>? ?? [])
            .whereType<Map>()
            .map((e) => OrderItem.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        createdAt: DateTime.tryParse((j['created_at'] ?? j['createdAt'] ?? '').toString()) ?? DateTime.now(),
      );

  static const statusLabel = {
    'pending':    'รอรับออเดอร์',
    'accepted':   'รับออเดอร์แล้ว',
    'preparing':  'กำลังทำอาหาร',
    'ready':      'อาหารพร้อมแล้ว',
    'delivering': 'กำลังจัดส่ง',
    'completed':  'เสร็จเรียบร้อย',
    'cancelled':  'ยกเลิก',
  };

  static const nextStatus = {
    'pending': 'accepted',
    'accepted': 'preparing',
    'preparing': 'ready',
    // 'ready' has no next — merchant waits for rider to complete delivery
  };

  String get label => statusLabel[status] ?? status;
  String? get next => nextStatus[status];
}
