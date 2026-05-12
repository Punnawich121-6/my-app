import 'dart:convert';
import 'package:http/http.dart' as http;

class RiderService {
  static const _base = 'http://localhost:3000/api/rider';

  static Future<Map<String, dynamic>?> register({
    required String phone,
    required String name,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone, 'name': name}),
      );
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>?> getByPhone(String phone) async {
    try {
      final normalized = phone.startsWith('0') ? phone : '0$phone';
      final res = await http.get(Uri.parse('$_base/by-phone/$normalized'));
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>?> getProfile(String riderId) async {
    try {
      final res = await http.get(Uri.parse('$_base/profile/$riderId'));
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (_) {}
    return null;
  }

  static Future<List<Map<String, dynamic>>> getAvailableOrders() async {
    try {
      final res = await http.get(Uri.parse('$_base/orders/available'));
      if (res.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(res.body));
      }
    } catch (_) {}
    return [];
  }

  static Future<Map<String, dynamic>?> getActiveDelivery(String riderId) async {
    try {
      final res = await http.get(Uri.parse('$_base/orders/active/$riderId'));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return body != null ? Map<String, dynamic>.from(body) : null;
      }
    } catch (_) {}
    return null;
  }

  static Future<bool> acceptOrder(String orderId, String riderId) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/orders/$orderId/accept'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'rider_id': riderId}),
      );
      return res.statusCode == 200;
    } catch (_) {}
    return false;
  }

  static Future<bool> completeDelivery(String orderId, String riderId) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/orders/$orderId/complete'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'rider_id': riderId}),
      );
      return res.statusCode == 200;
    } catch (_) {}
    return false;
  }

  static Future<List<Map<String, dynamic>>> getHistory(String riderId) async {
    try {
      final res = await http.get(Uri.parse('$_base/history/$riderId'));
      if (res.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(res.body));
      }
    } catch (_) {}
    return [];
  }

  static Future<Map<String, dynamic>?> getEarnings(String riderId) async {
    try {
      final res = await http.get(Uri.parse('$_base/earnings/$riderId'));
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (_) {}
    return null;
  }

  static Future<void> updateLocation(String riderId, double lat, double lng) async {
    try {
      await http.patch(
        Uri.parse('$_base/$riderId/location'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'latitude': lat, 'longitude': lng}),
      );
    } catch (_) {}
  }

  static Future<bool> updateOrderStep(
    String orderId,
    String riderId,
    String step, {
    double? lat,
    double? lng,
  }) async {
    try {
      final res = await http.patch(
        Uri.parse('$_base/orders/$orderId/step'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'rider_id': riderId,
          'step': step,
          if (lat != null) 'latitude': lat,
          if (lng != null) 'longitude': lng,
        }),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
