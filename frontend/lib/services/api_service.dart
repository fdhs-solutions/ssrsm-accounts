import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class ApiService {
  static String get _base => ApiConfig.baseUrl;

  // ── Login ──
  static Future<bool> login(String username, String password) async {
    try {
      final uri = Uri.parse(
          '$_base/login?username=${Uri.encodeComponent(username)}&password=${Uri.encodeComponent(password)}');
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      final body = json.decode(res.body);
      return body['success'] == true;
    } catch (e) {
      return false;
    }
  }

  // ── Dashboard ──
  static Future<Map<String, dynamic>> getDashboard({
    String? date,
    String? startDate,
    String? endDate,
    String? productId,
  }) async {
    final params = <String, String>{};
    if (date != null) params['date'] = date;
    if (startDate != null) params['startDate'] = startDate;
    if (endDate != null) params['endDate'] = endDate;
    if (productId != null) params['productId'] = productId;
    final uri = Uri.parse('$_base/dashboard')
        .replace(queryParameters: params.isNotEmpty ? params : null);
    final res = await http.get(uri).timeout(const Duration(seconds: 15));
    return json.decode(res.body);
  }

  // ── Salesmen ──
  static Future<List<dynamic>> getSalesmen({String? productId}) async {
    final params = <String, String>{};
    if (productId != null) params['productId'] = productId;
    final uri = Uri.parse('$_base/salesmen')
        .replace(queryParameters: params.isNotEmpty ? params : null);
    final res = await http.get(uri).timeout(const Duration(seconds: 10));
    final body = json.decode(res.body);
    return body['success'] == true ? List.from(body['data'] ?? []) : [];
  }

  static Future<Map<String, dynamic>?> addSalesman(
      String name, String productId) async {
    final uri = Uri.parse('$_base/salesmen');
    final res = await http
        .post(uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'name': name, 'productId': productId}))
        .timeout(const Duration(seconds: 10));
    final body = json.decode(res.body);
    return body['success'] == true ? body['data'] : null;
  }

  static Future<bool> updateSalesman(String id,
      {String? name, String? productId}) async {
    final uri = Uri.parse('$_base/salesmen/$id');
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (productId != null) data['productId'] = productId;
    final res = await http
        .put(uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(data))
        .timeout(const Duration(seconds: 10));
    final body = json.decode(res.body);
    return body['success'] == true;
  }

  static Future<bool> deleteSalesman(String id) async {
    final uri = Uri.parse('$_base/salesmen/$id');
    final res = await http.delete(uri).timeout(const Duration(seconds: 10));
    final body = json.decode(res.body);
    return body['success'] == true;
  }

  // ── Stock Entries ──
  static Future<Map<String, dynamic>> getOpeningStockInfo({required String productId, String? date}) async {
    try {
      final params = <String, String>{'productId': productId};
      if (date != null) params['date'] = date;
      final uri = Uri.parse('$_base/entries/opening-stock').replace(queryParameters: params);
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      final body = json.decode(res.body);
      if (body['success'] == true) {
        return {
          'openingStock': (body['openingStock'] ?? 0).toDouble(),
          'sameDayEntry': body['sameDayEntry'],
        };
      }
      return {'openingStock': 0.0, 'sameDayEntry': null};
    } catch (_) {
      return {'openingStock': 0.0, 'sameDayEntry': null};
    }
  }

  static Future<double> getOpeningStock({required String productId, String? date}) async {
    final info = await getOpeningStockInfo(productId: productId, date: date);
    return info['openingStock'] as double;
  }

  static Future<List<dynamic>> getEntries({
    String? productId,
    String? startDate,
    String? endDate,
  }) async {
    final params = <String, String>{};
    if (productId != null) params['productId'] = productId;
    if (startDate != null) params['startDate'] = startDate;
    if (endDate != null) params['endDate'] = endDate;
    final uri = Uri.parse('$_base/entries')
        .replace(queryParameters: params.isNotEmpty ? params : null);
    final res = await http.get(uri).timeout(const Duration(seconds: 10));
    final body = json.decode(res.body);
    return body['success'] == true ? List.from(body['data'] ?? []) : [];
  }

  static Future<Map<String, dynamic>?> createEntry(
      Map<String, dynamic> data) async {
    final uri = Uri.parse('$_base/entries');
    final res = await http
        .post(uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(data))
        .timeout(const Duration(seconds: 10));
    final body = json.decode(res.body);
    return body['success'] == true ? body['data'] : null;
  }

  static Future<bool> updateEntry(
      String id, Map<String, dynamic> data) async {
    final uri = Uri.parse('$_base/entries/$id');
    final res = await http
        .put(uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(data))
        .timeout(const Duration(seconds: 10));
    final body = json.decode(res.body);
    return body['success'] == true;
  }

  static Future<bool> deleteEntry(String id) async {
    final uri = Uri.parse('$_base/entries/$id');
    final res = await http.delete(uri).timeout(const Duration(seconds: 10));
    final body = json.decode(res.body);
    return body['success'] == true;
  }
}
