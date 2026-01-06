import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/product_model.dart';

class ProductProvider extends ChangeNotifier {
  List<Product> _products = [];
  List<Product> _sellerProducts = [];
  bool _isLoading = false;
  String? _error;

  final String _baseUrl = 'http://localhost:8000/api';
  final Dio _dio = Dio();

  List<Product> get products => _products;
  List<Product> get sellerProducts => _sellerProducts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchProducts({String? category, String? search}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String url = '$_baseUrl/products';
      Map<String, dynamic> params = {};
      if (category != null) params['category'] = category;
      if (search != null) params['search'] = search;

      final response = await _dio.get(url, queryParameters: params);
      _products = (response.data as List)
          .map((p) => Product.fromJson(p))
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createProduct({
    required String name,
    required String description,
    required double basePrice,
    required String category,
    required List<String> images,
    required List<Map<String, dynamic>> variants,
    required String token,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/products',
        data: {
          'name': name,
          'description': description,
          'base_price': basePrice,
          'category': category,
          'images': images,
          'variants': variants,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      Product newProduct = Product.fromJson(response.data);
      _sellerProducts.add(newProduct);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProduct({
    required String productId,
    required Map<String, dynamic> data,
    required String token,
  }) async {
    try {
      await _dio.put(
        '$_baseUrl/products/$productId',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final index = _sellerProducts.indexWhere((p) => p.id == productId);
      if (index >= 0) {
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProduct({
    required String productId,
    required String token,
  }) async {
    try {
      await _dio.delete(
        '$_baseUrl/products/$productId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      _sellerProducts.removeWhere((p) => p.id == productId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
