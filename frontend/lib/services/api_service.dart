import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class ApiService {
  static String get _base => ApiConfig.baseUrl;

  // Cached products: name -> id and id -> name
  static List<Map<String, dynamic>> _cachedProducts = [];

  static Future<List<Map<String, dynamic>>> getProducts() async {
    if (_cachedProducts.isNotEmpty) return _cachedProducts;
    try {
      final uri = Uri.parse('$_base/products');
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      final body = json.decode(res.body);
      if (body['success'] == true) {
        _cachedProducts = List<Map<String, dynamic>>.from(body['data'] ?? []);
        return _cachedProducts;
      }
    } catch (_) {}
    return [];
  }

  static Future<String?> getProductIdByName(String name) async {
    final prods = await getProducts();
    final matched = prods.firstWhere(
      (p) => p['name'].toString().toLowerCase() == name.toLowerCase(),
      orElse: () => {},
    );
    return matched['id']?.toString();
  }

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
    String? productName,
  }) async {
    final params = <String, String>{};
    if (date != null) params['date'] = date;
    if (startDate != null) params['startDate'] = startDate;
    if (endDate != null) params['endDate'] = endDate;

    // Resolve real UUID if product name passed
    if (productId != null && productId.isNotEmpty) {
      final isUuid = RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(productId);
      if (!isUuid) {
        final realId = await getProductIdByName(productId);
        if (realId != null) {
          params['productId'] = realId;
          params['productName'] = productId;
        } else {
          params['productId'] = productId;
        }
      } else {
        params['productId'] = productId;
        if (productName != null) params['productName'] = productName;
      }
    }

    final uri = Uri.parse('$_base/dashboard')
        .replace(queryParameters: params.isNotEmpty ? params : null);
    final res = await http.get(uri).timeout(const Duration(seconds: 15));
    return json.decode(res.body);
  }

  // ── Salesmen ──
  static Future<List<dynamic>> getSalesmen({String? productId, String? productName}) async {
    final params = <String, String>{};
    if (productId != null && productId.isNotEmpty) {
      final isUuid = RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(productId);
      if (!isUuid) {
        final realId = await getProductIdByName(productId);
        if (realId != null) {
          params['productId'] = realId;
          params['productName'] = productId;
        } else {
          params['productId'] = productId;
        }
      } else {
        params['productId'] = productId;
        if (productName != null) params['productName'] = productName;
      }
    }

    final uri = Uri.parse('$_base/salesmen')
        .replace(queryParameters: params.isNotEmpty ? params : null);
    final res = await http.get(uri).timeout(const Duration(seconds: 10));
    final body = json.decode(res.body);
    return body['success'] == true ? List.from(body['data'] ?? []) : [];
  }

  static Future<(bool, String?)> addSalesman(
      String name, String productId) async {
    String actualId = productId;
    String actualName = productId;
    final isUuid = RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(productId);
    if (!isUuid) {
      final realId = await getProductIdByName(productId);
      if (realId != null) actualId = realId;
    }

    try {
      final uri = Uri.parse('$_base/salesmen');
      final res = await http
          .post(uri,
              headers: {'Content-Type': 'application/json'},
              body: json.encode({
                'name': name,
                'productId': actualId,
                'productName': actualName,
              }))
          .timeout(const Duration(seconds: 10));
      final body = json.decode(res.body);
      if (body['success'] == true) {
        return (true, null);
      } else {
        return (false, body['error']?.toString() ?? 'Failed to add sales man');
      }
    } catch (e) {
      return (false, e.toString());
    }
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
  static Future<Map<String, dynamic>> getOpeningStockInfo({required String productId, String? productName, String? date}) async {
    try {
      final params = <String, String>{};
      if (date != null) params['date'] = date;

      final isUuid = RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(productId);
      if (!isUuid) {
        final realId = await getProductIdByName(productId);
        if (realId != null) {
          params['productId'] = realId;
          params['productName'] = productId;
        } else {
          params['productId'] = productId;
        }
      } else {
        params['productId'] = productId;
        if (productName != null) params['productName'] = productName;
      }

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

  static Future<double> getOpeningStock({required String productId, String? productName, String? date}) async {
    final info = await getOpeningStockInfo(productId: productId, productName: productName, date: date);
    return info['openingStock'] as double;
  }

  static Future<List<dynamic>> getEntries({
    String? productId,
    String? productName,
    String? startDate,
    String? endDate,
  }) async {
    final params = <String, String>{};
    if (productId != null && productId.isNotEmpty) {
      final isUuid = RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(productId);
      if (!isUuid) {
        final realId = await getProductIdByName(productId);
        if (realId != null) {
          params['productId'] = realId;
          params['productName'] = productId;
        } else {
          params['productId'] = productId;
        }
      } else {
        params['productId'] = productId;
        if (productName != null) params['productName'] = productName;
      }
    }
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
    // If productId in data is a brand name, resolve to UUID and keep both productId and productName
    final pId = data['productId']?.toString() ?? '';
    if (pId.isNotEmpty) {
      final isUuid = RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(pId);
      if (!isUuid) {
        final realId = await getProductIdByName(pId);
        if (realId != null) {
          data['productName'] = pId;
          data['productId'] = realId;
        }
      }
    }

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
    try {
      final uri = Uri.parse('$_base/entries/$id');
      final res = await http.delete(uri).timeout(const Duration(seconds: 10));
      final body = json.decode(res.body);
      return body['success'] == true;
    } catch (_) {
      return false;
    }
  }

  // Bulk delete in ONE single API call (POST /api/entries/bulk-delete)
  static Future<int> deleteEntriesBulk(List<String> ids) async {
    if (ids.isEmpty) return 0;
    try {
      final uri = Uri.parse('$_base/entries/bulk-delete');
      final res = await http
          .post(uri,
              headers: {'Content-Type': 'application/json'},
              body: json.encode({'ids': ids}))
          .timeout(const Duration(seconds: 15));
      final body = json.decode(res.body);
      if (body['success'] == true) {
        return (body['data']?['deletedCount'] as int?) ?? ids.length;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  // ── PDF Export URL ──
  static Future<String> getPdfUrl({
    String? productId,
    String? productName,
    String? startDate,
    String? endDate,
    bool download = false,
  }) async {
    final params = <String, String>{};
    if (productId != null && productId.isNotEmpty) {
      final isUuid = RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(productId);
      if (!isUuid) {
        final realId = await getProductIdByName(productId);
        if (realId != null) {
          params['productId'] = realId;
          params['productName'] = productId;
        } else {
          params['productId'] = productId;
        }
      } else {
        params['productId'] = productId;
        if (productName != null) params['productName'] = productName;
      }
    }
    if (startDate != null && startDate.isNotEmpty) {
      params['startDate'] = startDate;
    }
    if (endDate != null && endDate.isNotEmpty) {
      params['endDate'] = endDate;
    }
    if (download) {
      params['download'] = '1';
    }

    final uri = Uri.parse('$_base/entries/pdf')
        .replace(queryParameters: params.isNotEmpty ? params : null);
    return uri.toString();
  }
}
