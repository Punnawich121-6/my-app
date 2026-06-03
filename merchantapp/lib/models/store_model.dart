class Store {
  final String id;
  final String userId;
  String name;
  String type;
  String address;
  double? lat;
  double? lng;
  String openTime;
  String closeTime;
  bool isOpen;
  String? imageUrl;
  double rating;
  int reviewCount;
  String? bankName;
  String? accountName;
  String? accountNo;
  final String status;
  String description;

  Store({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.address,
    this.lat,
    this.lng,
    required this.openTime,
    required this.closeTime,
    required this.isOpen,
    this.imageUrl,
    this.rating = 0,
    this.reviewCount = 0,
    this.bankName,
    this.accountName,
    this.accountNo,
    this.status = 'pending',
    this.description = '',
  });

  factory Store.fromJson(Map<String, dynamic> j) => Store(
        id: j['id'].toString(),
        userId: (j['user_id'] ?? '').toString(),
        name: j['name'],
        type: j['type'] ?? '',
        address: j['address'] ?? '',
        lat: j['lat'] != null ? double.parse(j['lat'].toString()) : null,
        lng: j['lng'] != null ? double.parse(j['lng'].toString()) : null,
        openTime: j['open_time'] ?? '',
        closeTime: j['close_time'] ?? '',
        isOpen: (j['is_open'] == 1 || j['is_open'] == true),
        imageUrl: j['image_url'],
        rating: double.parse((j['rating'] ?? 0).toString()),
        reviewCount: j['review_count'] ?? 0,
        bankName: j['bank_name'],
        accountName: j['account_name'],
        accountNo: j['account_no'],
        status: j['status'] ?? 'pending',
        description: j['description']?.toString() ?? '',
      );
}

class DashboardData {
  final Store store;
  final int todayOrders;
  final double todayRevenue;
  final int pendingOrders;
  final int readyOrders;
  final List<Map<String, dynamic>> weekSales;
  final List<Map<String, dynamic>> recentOrders;
  final List<Map<String, dynamic>> popularItems;

  DashboardData({
    required this.store,
    required this.todayOrders,
    required this.todayRevenue,
    required this.pendingOrders,
    required this.readyOrders,
    required this.weekSales,
    required this.recentOrders,
    required this.popularItems,
  });

  factory DashboardData.fromJson(Map<String, dynamic> j) => DashboardData(
        store: Store.fromJson(j['store']),
        todayOrders: j['today_orders'],
        todayRevenue: double.parse((j['today_revenue'] ?? 0).toString()),
        pendingOrders: j['pending_orders'],
        readyOrders: j['ready_orders'] ?? 0,
        weekSales: List<Map<String, dynamic>>.from(j['week_sales'] ?? []),
        recentOrders: List<Map<String, dynamic>>.from(j['recent_orders'] ?? []),
        popularItems: List<Map<String, dynamic>>.from(j['popular_items'] ?? []),
      );
}
