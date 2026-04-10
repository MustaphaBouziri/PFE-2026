// APPENDED TO: lib/data/shared/http_response_parser.dart

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/app_constants.dart';

class HttpClient {
  static Future<http.Response> post(String url, Map<String, dynamic> body) {
    return http.post(
      Uri.parse(url),
      headers: AppConstants.jsonHeaders,
      body: jsonEncode(body),
    );
  }
}
