import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider extends ChangeNotifier {
  bool _isInitialized = false;
  bool _isAuthenticated = false;
  bool _isSellerMode = false;
  String _userName = '';
  Set<String> _favoriteIds = {};
  Set<String> _cartIds = {};
  List<Map<String, dynamic>> _addresses = [];

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _isAuthenticated;
  bool get isSellerMode => _isSellerMode;
  String get userName => _userName;
  Set<String> get favoriteIds => _favoriteIds;
  Set<String> get cartIds => _cartIds;
  List<Map<String, dynamic>> get addresses => _addresses;

  /// Loads saved state from local storage on app startup
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isSellerMode = prefs.getBool('isSellerMode') ?? false;
    _isAuthenticated = prefs.getBool('isAuthenticated') ?? false;
    _userName = prefs.getString('userName') ?? '';
    _favoriteIds = (prefs.getStringList('favoriteIds') ?? []).toSet();
    _cartIds = (prefs.getStringList('cartIds') ?? []).toSet();
    String? savedAddressJson = prefs.getString('addresses');
    if (savedAddressJson != null && savedAddressJson.isNotEmpty) {
      try {
        final List<dynamic> decodedList = jsonDecode(savedAddressJson);
        _addresses = List<Map<String, dynamic>>.from(decodedList);
      } catch (e) {
        _addresses = [];
      }
    } else {
      _addresses = [];
    }

    _isInitialized = true;
    notifyListeners();
  }

  void setInitialFavorites(List<String> ids, {bool isFirstPage = false}) async {
    if (isFirstPage) {
      _favoriteIds.clear();
    }
    _favoriteIds.addAll(ids);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favoriteIds', _favoriteIds.toList());
    notifyListeners();
  }

  void setInitialCart(List<String> ids) async {
    _cartIds = ids.toSet();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('cartIds', _cartIds.toList());
    notifyListeners();
  }

  void toggleFavoriteLocally(String productId, bool isFav) async {
    if (isFav) {
      _favoriteIds.add(productId);
    } else {
      _favoriteIds.remove(productId);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favoriteIds', _favoriteIds.toList());
    notifyListeners();
  }

  void toggleCartLocally(String productId, bool add) async {
    if (add) {
      _cartIds.add(productId);
    } else {
      _cartIds.remove(productId);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('cartIds', _cartIds.toList());
    notifyListeners();
  }

  bool isProductFavorited(String productId) {
    return _favoriteIds.contains(productId);
  }

  bool isProductInCart(String productId) {
    return _cartIds.contains(productId);
  }

  Future<void> setAddresses(List<dynamic> newAddresses) async {
    _addresses = List<Map<String, dynamic>>.from(newAddresses);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('addresses', jsonEncode(_addresses));
    notifyListeners();
  }

  Future<void> addAddress(Map<String, dynamic> newAddress) async {
    _addresses.add(newAddress);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('addresses', jsonEncode(_addresses));
    notifyListeners();
  }

  Future<void> updateAddress(
    int index,
    Map<String, dynamic> updatedAddress,
  ) async {
    if (index >= 0 && index < _addresses.length) {
      _addresses[index] = updatedAddress;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('addresses', jsonEncode(_addresses));
      notifyListeners();
    }
  }

  Future<void> removeAddress(int index) async {
    if (index >= 0 && index < _addresses.length) {
      _addresses.removeAt(index);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('addresses', jsonEncode(_addresses));
      notifyListeners();
    }
  }

  Future<void> setAuthenticated(bool status, String name) async {
    _isAuthenticated = status;
    _userName = name;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAuthenticated', status);
    await prefs.setString('userName', name);
    notifyListeners();
  }

  /// Toggles Seller Mode and persists it until manually turned off
  Future<void> toggleSellerMode() async {
    _isSellerMode = !_isSellerMode;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isSellerMode', _isSellerMode);
    notifyListeners();
  }

  /// Clears all local data on logout
  Future<void> logout() async {
    _isAuthenticated = false;
    _isSellerMode = false; // Optional: Reset seller mode on logout
    _userName = '';

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }
}
