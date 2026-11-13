import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../config.dart';
import '../models/category.dart';
import '../models/product.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class ApiService {
  static const String _base = AppConfig.apiUrl;
  // Some browsers/emulators can cache a GET even when the list is refreshed.
  // Explicitly disable caching so the list always reflects the latest save.
  static const _json = {
    'Accept': 'application/json',
    'Cache-Control': 'no-cache, no-store',
    'Pragma': 'no-cache',
  };
  static const _timeout = Duration(seconds: 15);

  // ---------- PRODUCTS ----------
  static Future<List<Product>> getProducts() async {
    final res = await _get('products');
    return (jsonDecode(res.body) as List)
        .map((e) => Product.fromJson(e))
        .toList();
  }

  static Future<void> saveProduct(Map<String, String> fields,
      {int? id, XFile? image}) {
    return _multipart('products', fields,
        id: id, fileField: 'ProductImage', file: image);
  }

  static Future<void> deleteProduct(int id) => _delete('products', id);

  // ---------- CATEGORIES ----------
  static Future<List<Category>> getCategories() async {
    final res = await _get('categories');
    return (jsonDecode(res.body) as List)
        .map((e) => Category.fromJson(e))
        .toList();
  }

  static Future<void> saveCategory(Map<String, String> fields,
      {int? id, XFile? image}) {
    return _multipart('categories', fields,
        id: id, fileField: 'image', file: image);
  }

  static Future<void> deleteCategory(int id) => _delete('categories', id);

  // ---------- HELPERS ----------
  static Future<http.Response> _get(String path) async {
    try {
      final uri = Uri.parse('$_base/$path').replace(queryParameters: {
        '_refresh': DateTime.now().millisecondsSinceEpoch.toString(),
      });
      final res = await http.get(uri, headers: _json).timeout(_timeout);
      if (res.statusCode != 200) throw ApiException(_errorMessage(res));
      return res;
    } on TimeoutException {
      throw ApiException('The server took too long to respond. Is Laravel running?');
    } on http.ClientException {
      throw ApiException('Cannot connect to server. Is Laravel running?');
    }
  }

  // POST for create, POST + _method=PUT for update (needed for file upload)
  static Future<void> _multipart(
    String path,
    Map<String, String> fields, {
    int? id,
    required String fileField,
    XFile? file,
  }) async {
    try {
      final uri =
          Uri.parse(id == null ? '$_base/$path' : '$_base/$path/$id');
      final req = http.MultipartRequest('POST', uri)
        ..headers.addAll(_json)
        ..fields.addAll(fields);
      if (id != null) req.fields['_method'] = 'PUT';
      if (file != null) {
        req.files.add(http.MultipartFile.fromBytes(
          fileField,
          await file.readAsBytes(),
          filename: file.name,
        ));
      }
      final res = await http.Response.fromStream(
        await req.send().timeout(_timeout),
      );
      if (res.statusCode != 200 && res.statusCode != 201) {
        throw ApiException(_errorMessage(res));
      }
    } on TimeoutException {
      throw ApiException('The server took too long to respond. Is Laravel running?');
    } on http.ClientException {
      throw ApiException('Cannot connect to server. Is Laravel running?');
    }
  }

  static Future<void> _delete(String path, int id) async {
    try {
      final res = await http
          .delete(Uri.parse('$_base/$path/$id'), headers: _json)
          .timeout(_timeout);
      if (res.statusCode != 200) throw ApiException(_errorMessage(res));
    } on TimeoutException {
      throw ApiException('The server took too long to respond. Is Laravel running?');
    } on http.ClientException {
      throw ApiException('Cannot connect to server. Is Laravel running?');
    }
  }

  static String _errorMessage(http.Response res) {
    try {
      final body = jsonDecode(res.body);
      if (body['errors'] != null) {
        return (body['errors'] as Map)
            .values
            .map((e) => (e as List).first.toString())
            .join('\n');
      }
      return body['message']?.toString() ?? 'Error ${res.statusCode}';
    } catch (_) {
      return 'Error ${res.statusCode}';
    }
  }
}
