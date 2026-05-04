import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/order_model.dart';
import '../models/menu_model.dart';
import '../models/store_model.dart';

class ApiService {
  static const _base = 'http://localhost:3000/api';
  static const storeId = 1;

  static Future<Map<String, dynamic>> _get(String path) async {
    final res = await http.get(Uri.parse('$_base$path'));
    return jsonDecode(utf8.decode(res.bodyBytes));
  }

  static Future<Map<String, dynamic>> _put(String path, Map<String, dynamic> body) async {
    final res = await http.put(
      Uri.parse('$_base$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return jsonDecode(utf8.decode(res.bodyBytes));
  }

  static Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$_base$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return jsonDecode(utf8.decode(res.bodyBytes));
  }

  static Future<dynamic> _delete(String path) async {
    final res = await http.delete(Uri.parse('$_base$path'));
    return jsonDecode(utf8.decode(res.bodyBytes));
  }

  // Dashboard
  static Future<DashboardData> getDashboard() async {
    final data = await _get('/dashboard/$storeId');
    return DashboardData.fromJson(data);
  }

  static Future<bool> toggleStoreOpen() async {
    final data = await _put('/dashboard/$storeId/toggle', {});
    return data['is_open'] == 1;
  }

  // Orders
  static Future<List<Order>> getOrders({String status = 'all'}) async {
    final res = await http.get(Uri.parse('$_base/orders/$storeId?status=$status'));
    final data = jsonDecode(utf8.decode(res.bodyBytes)) as List;
    return data.map((e) => Order.fromJson(e)).toList();
  }

  static Future<Order> getOrderDetail(int orderId) async {
    final data = await _get('/orders/detail/$orderId');
    return Order.fromJson(data);
  }

  static Future<Map<String, dynamic>> getOrderDetailMap(int orderId) async {
    return await _get('/orders/detail/$orderId');
  }

  static Future<void> updateOrderStatus(int orderId, String status) async {
    await _put('/orders/$orderId/status', {'status': status});
  }

  // Menu
  static Future<Map<String, dynamic>> getMenu() async {
    final data = await _get('/menu/$storeId');
    return {
      'categories': (data['categories'] as List).map((e) => MenuCategory.fromJson(e)).toList(),
      'items': (data['items'] as List).map((e) => MenuItem.fromJson(e)).toList(),
    };
  }

  static Future<MenuCategory> addCategory(String name) async {
    final data = await _post('/menu/category', {'store_id': storeId, 'name': name});
    return MenuCategory.fromJson(data);
  }

  static Future<void> deleteCategory(int id) async {
    await _delete('/menu/category/$id');
  }

  static Future<MenuItem> addMenuItem(Map<String, dynamic> body) async {
    final data = await _post('/menu/item', {...body, 'store_id': storeId});
    return MenuItem.fromJson(data);
  }

  static Future<void> updateMenuItem(int id, Map<String, dynamic> body) async {
    await _put('/menu/item/$id', body);
  }

  static Future<bool> toggleMenuItem(int id) async {
    final data = await _put('/menu/item/$id/toggle', {});
    return data['is_available'] == 1;
  }

  static Future<void> deleteMenuItem(int id) async {
    await _delete('/menu/item/$id');
  }

  static Future<Map<String, dynamic>> createTestOrder(List<Map<String, dynamic>> items) async {
    return await _post('/orders/test-order', {
      'store_id': storeId,
      'items': items,
    });
  }

  // Earnings
  static Future<Map<String, dynamic>> getEarnings({String period = 'day'}) async {
    return await _get('/earnings/$storeId?period=$period');
  }

  // Store
  static Future<Store> getStore() async {
    final data = await _get('/store/$storeId');
    return Store.fromJson(data);
  }

  static Future<void> updateStore(Map<String, dynamic> body) async {
    await _put('/store/$storeId', body);
  }

  static Future<Map<String, dynamic>> getReviews() async {
    return await _get('/store/$storeId/reviews');
  }
}
