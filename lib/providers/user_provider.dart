import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_urls.dart';
import '../api_client.dart';
import '../models/user_model.dart';

class UserProvider extends ChangeNotifier {
  bool _isInitialized = false;
  bool _isAuthenticated = false;
  bool _isSellerMode = false;
  Set<String> _favoriteIds = {};
  Set<String> _cartIds = {};
  List<Map<String, dynamic>> _addresses = [];
  String _token = '';
  String _error = '';
  User? _user;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _isAuthenticated;
  bool get isSellerMode => _isSellerMode;
  User? get user => _user;
  Set<String> get favoriteIds => _favoriteIds;
  Set<String> get cartIds => _cartIds;
  List<Map<String, dynamic>> get addresses => _addresses;
  String get token => _token;
  String get error => _error;

  /// Loads saved state from local storage on app startup
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isSellerMode = prefs.getBool('isSellerMode') ?? false;
    _isAuthenticated = prefs.getBool('isAuthenticated') ?? false;
    _favoriteIds = (prefs.getStringList('favoriteIds') ?? []).toSet();
    _cartIds = (prefs.getStringList('cartIds') ?? []).toSet();
    _token = prefs.getString('auth_token') ?? '';
    String? userJson = prefs.getString('user_data');
    if (userJson != null && userJson.isNotEmpty) {
      final userData = jsonDecode(userJson) as Map<String, dynamic>;
      _user = User(
        userId: userData['userId'],
        email: '',
        firstName: userData['firstName'],
        lastName: userData['lastName'],
        number: userData['number'],
        isSeller: false,
      );
    } else {
      _user = null;
    }
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

  Future<void> setAuthenticated(bool status) async {
    _isAuthenticated = status;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAuthenticated', status);
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
    _isSellerMode = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }

  Future<bool> login(String number, String otp, bool otpSent) async {
    try {
      final body = {'number': number, if (otpSent) 'otp': otp};
      final response = await ApiClient.postWithNoToken(
        otpSent ? ApiUrls.verifyOtp : ApiUrls.sendOtp,
        body,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!otpSent) {
          return true;
        } else {
          _token = data['token'];
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', _token);
          final userDetails = await ApiClient.post(ApiUrls.getUserDetails, {
            'userId': data['userId'],
          });
          if (userDetails.statusCode == 200 || userDetails.statusCode == 201) {
            final userData = jsonDecode(userDetails.body);
            _user = User(
              firstName: userData['user']['firstName'],
              lastName: userData['user']['lastName'],
              number: userData['user']['number'],
              userId: userData['user']['userId'],
              email: userData['user']['email'] ?? '',
              isSeller: userData['user']['isSeller'] ?? false,
            );
            await prefs.setString('user_data', jsonEncode(userData['user']));
            await prefs.setBool(
              'is_seller_mode',
              userData['user']['is_seller'] ?? false,
            );
            setAddresses(userData['user']['addresses']);
          }
          return true;
        }
      } else {
        _error = data['error'] ?? 'Something went wrong';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> signUp(
    String number,
    String firstName,
    String lastName,
    String otp,
    bool otpSent,
  ) async {
    print("DEBUG: 1. Entering signUp function");
    try {
      final body = {
        'number': number,
        'firstName': firstName,
        'lastName': lastName,
        if (otpSent) 'otp': otp,
        'signup': true,
      };
      print("DEBUG: 2. Body prepared: $body");
      print(
        "DEBUG: 3. Target URL: ${otpSent ? ApiUrls.verifyOtp : ApiUrls.sendOtp}",
      );

      final response = await ApiClient.postWithNoToken(
        otpSent ? ApiUrls.verifyOtp : ApiUrls.sendOtp,
        body,
      ).timeout(const Duration(seconds: 10));

      print("DEBUG: 4. Response received! Status: ${response.statusCode}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!otpSent) {
          return true;
        } else {
          _token = data['token'];
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', _token);
          final userDetails = await ApiClient.post(ApiUrls.getUserDetails, {
            'userId': data['userId'],
          });
          if (userDetails.statusCode == 200 || userDetails.statusCode == 201) {
            final userData = jsonDecode(userDetails.body);
            _user = User(
              firstName: userData['user']['firstName'],
              lastName: userData['user']['lastName'],
              number: userData['user']['number'],
              userId: userData['user']['userId'],
              email: userData['user']['email'] ?? '',
              isSeller: userData['user']['isSeller'] ?? false,
            );
            await prefs.setString('user_data', jsonEncode(userData['user']));
          }
          return true;
        }
      } else {
        _error = data['error'];
        return false;
      }
    } catch (e, stacktrace) {
      print("DEBUG: ERROR CAUGHT: $e");
      print("DEBUG: STACKTRACE: $stacktrace");
      _error = e.toString();
      return false;
    }
  }
}
