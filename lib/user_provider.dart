import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider extends ChangeNotifier {
  bool _isInitialized = false;
  bool _isAuthenticated = false;
  bool _isSellerMode = false;
  String _userName = '';
  Set<String> _favoriteIds = {};

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _isAuthenticated;
  bool get isSellerMode => _isSellerMode;
  String get userName => _userName;
  Set<String> get favoriteIds => _favoriteIds;

  /// Loads saved state from local storage on app startup
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isSellerMode = prefs.getBool('isSellerMode') ?? false;
    _isAuthenticated = prefs.getBool('isAuthenticated') ?? false;
    _userName = prefs.getString('userName') ?? '';

    _isInitialized = true;
    notifyListeners();
  }

  void setInitialFavorites(List<String> ids) {
    _favoriteIds = ids.toSet();
    notifyListeners();
  }

  void toggleFavoriteLocally(String productId, bool isFav) {
    if (isFav) {
      _favoriteIds.add(productId);
    } else {
      _favoriteIds.remove(productId);
    }
    notifyListeners();
  }

  bool isProductFavorited(String productId) {
    return _favoriteIds.contains(productId);
  }

  /// Handles Login and Signup success
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
