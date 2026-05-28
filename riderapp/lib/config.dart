import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:http/http.dart' as http;

final String kBackendUrl = kIsWeb
    ? 'http://localhost:3001'
    : 'http://10.0.2.2:3001';

// เปิด true เพื่อใช้ location ร้านแทน GPS จริงตอน dev
const bool kDevMockLocation = kDebugMode;

const Map<String, String> kHeaders = {
  'Content-Type': 'application/json',
};

Future<http.Response> apiGet(String url) =>
    http.get(Uri.parse(url));

Future<http.Response> apiPost(String url, String body) =>
    http.post(Uri.parse(url), headers: kHeaders, body: body);

Future<http.Response> apiPut(String url, String body) =>
    http.put(Uri.parse(url), headers: kHeaders, body: body);
