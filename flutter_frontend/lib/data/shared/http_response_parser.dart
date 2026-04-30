import 'dart:convert';

import 'package:http/http.dart' as http;

class HttpResponseParser {
  /// Decodes a BC OData response that wraps a JSON array in a "value" string.
  static List<dynamic> parseList(
    http.Response response, {
    String label = 'request',
  }) {
    _assertSuccess(response, label);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final valueString = data['value'] as String? ?? '[]';
    return jsonDecode(valueString) as List<dynamic>;
  }

  /// Decodes a BC OData response that wraps a JSON object in a "value" string.
  static Map<String, dynamic> parseObject(
    http.Response response, {
    String label = 'request',
  }) {
    _assertSuccess(response, label);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return jsonDecode(data['value'] as String? ?? '{}') as Map<String, dynamic>;
  }

  /// Decodes a BC OData response that wraps a write result:
  /// { "value": true/false, "message": "..." }
  /// Throws with the backend message on failure.
  static bool parseWriteResult(
    http.Response response, {
    String label = 'request',
  }) {
    _assertSuccess(response, label);
    final outer = jsonDecode(response.body) as Map<String, dynamic>;
    final inner =
        jsonDecode(outer['value'] as String? ?? '{}') as Map<String, dynamic>;
    if (inner['value'] == true) return true;
    throw Exception(inner['message'] ?? 'Unknown error from $label');
  }

  /// Returns true when the status code indicates success (200 or 201).
  /// Throws a descriptive exception otherwise.
  ///
  /// Use this in service methods that don't return a typed payload — it
  /// removes the repeated `if (response.statusCode == 200 || 201)` blocks.
  static bool parseSuccess(http.Response response, {String label = 'request'}) {
    _assertSuccess(response, label);
    return true;
  }

  static void _assertSuccess(http.Response response, String label) {
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('$label failed: ${response.statusCode} ${response.body}');
    }
  }
  
}
