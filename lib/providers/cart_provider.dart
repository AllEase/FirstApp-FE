import 'package:flutter/material.dart';

class CartItem {
  final String productId;
  final String name;
  final double price;
  int quantity;
  final List<Map<String, dynamic>> selectedVariants;

  CartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.selectedVariants,
  });
}

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  double get totalPrice => _items.fold(
      0, (sum, item) => sum + (item.price * item.quantity));

  int get itemCount => _items.length;

  void addItem(CartItem item) {
    final existingIndex = _items.indexWhere((i) => i.productId == item.productId);
    if (existingIndex >= 0) {
      _items[existingIndex].quantity += item.quantity;
    } else {
      _items.add(item);
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.removeWhere((item) => item.productId == productId);
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    final index = _items.indexWhere((i) => i.productId == productId);
    if (index >= 0) {
      if (quantity <= 0) {
        removeItem(productId);
      } else {
        _items[index].quantity = quantity;
        notifyListeners();
      }
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
