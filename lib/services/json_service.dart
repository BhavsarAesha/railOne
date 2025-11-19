import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// Utility to load JSON lists from bundled assets.
/// Throws if the asset content is not a JSON array.
class JsonService {
  static Future<List<dynamic>> loadJsonList(String assetPath) async {
    final String raw = await rootBundle.loadString(assetPath);
    final dynamic decoded = jsonDecode(raw);
    if (decoded is List<dynamic>) {
      return decoded;
    }
    throw Exception('Expected a JSON list at $assetPath');
  }
}

