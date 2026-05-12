import 'dart:convert';
import 'package:http/http.dart' as http;

const _base = 'http://localhost:3000/api/customer';

class CustomerService {
  static Future<Map<String, dynamic>?> getByPhone(String phone) async {
    try {
      final res = await http.get(Uri.parse('$_base/by-phone/$phone'));
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body);
      if (data is! Map || data['id'] == null) return null;
      return Map<String, dynamic>.from(data);
    } catch (_) { return null; }
  }

  static Future<Map<String, dynamic>?> register({required String phone, required String name}) async {
    try {
      final res = await http.post(Uri.parse('$_base/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'phone': phone, 'name': name}));
      final data = jsonDecode(res.body);
      if (data is! Map || data['user_id'] == null) return null;
      return Map<String, dynamic>.from(data);
    } catch (_) { return null; }
  }

  static Future<List<Map<String, dynamic>>> getStores() async {
    try {
      final res = await http.get(Uri.parse('$_base/stores'));
      final data = jsonDecode(res.body) as List;
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) { return []; }
  }

  static Future<Map<String, dynamic>?> getMenu(dynamic storeId) async {
    try {
      final res = await http.get(Uri.parse('http://localhost:3000/api/menu/$storeId'));
      return jsonDecode(res.body);
    } catch (_) { return null; }
  }

  static Future<Map<String, dynamic>?> placeOrder({
    required String? customerId,
    required String customerName,
    required String customerPhone,
    required dynamic storeId,
    required List<Map<String, dynamic>> items,
    required String address,
    double? latitude,
    double? longitude,
    String note = '',
  }) async {
    try {
      final res = await http.post(Uri.parse('$_base/orders'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'customer_id': customerId,
            'customer_name': customerName,
            'customer_phone': customerPhone,
            'store_id': storeId,
            'items': items,
            'address': address,
            'latitude': latitude,
            'longitude': longitude,
            'note': note,
          }));
      return jsonDecode(res.body);
    } catch (_) { return null; }
  }

  static Future<List<Map<String, dynamic>>> getOrders(String customerId) async {
    try {
      final res = await http.get(Uri.parse('$_base/orders/$customerId'));
      final data = jsonDecode(res.body) as List;
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) { return []; }
  }

  static Future<Map<String, dynamic>?> getOrderDetail(String orderId) async {
    try {
      final res = await http.get(Uri.parse('$_base/orders/detail/$orderId'));
      return jsonDecode(res.body);
    } catch (_) { return null; }
  }

  static Future<bool> updateProfile(String customerId, String name) async {
    try {
      final res = await http.put(
        Uri.parse('$_base/profile/$customerId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name}),
      );
      return res.statusCode == 200;
    } catch (_) { return false; }
  }
}
