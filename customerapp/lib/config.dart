import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

// Web → localhost, physical device & emulator → ngrok public URL
final String kBackendUrl = kIsWeb
    ? 'http://localhost:3001'
    : 'http://10.0.2.2:3001';

const Map<String, String> kHeaders = {
  'Content-Type': 'application/json',
};

Future<http.Response> apiGet(String url) =>
    http.get(Uri.parse(url));

Future<http.Response> apiPost(String url, String body) =>
    http.post(Uri.parse(url), headers: kHeaders, body: body);

Future<http.Response> apiPut(String url, String body) =>
    http.put(Uri.parse(url), headers: kHeaders, body: body);

Future<http.Response> apiPatch(String url, String body) =>
    http.patch(Uri.parse(url), headers: kHeaders, body: body);
