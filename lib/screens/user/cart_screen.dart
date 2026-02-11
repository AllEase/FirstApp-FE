import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../api_client.dart';
import '../../config/api_urls.dart';
import 'dart:convert';
import '../../widgets/cache_product_image.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final ScrollController _scrollController = ScrollController();
  List<dynamic> _cartProducts = [];
  final Set<String> _selectedProductIds = {}; // Track selected items by ID

  int _currentPage = 1;
  final int _limit = 10;
  bool _isLoadingInitial = true;
  bool _isLoadingMore = false;
  bool _isLastPage = false;

  @override
  void initState() {
    super.initState();
    _fetchCartProducts(isFirstLoad: true);
    _scrollController.addListener(_onScroll);
  }

  // Calculate dynamic total for selected items
  double get _selectedTotal {
    double total = 0;
    for (var product in _cartProducts) {
      if (_selectedProductIds.contains(product['id'].toString())) {
        total += double.tryParse(product['price'].toString()) ?? 0.0;
      }
    }
    return total;
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9) {
      if (!_isLoadingMore && !_isLastPage) {
        _fetchCartProducts();
      }
    }
  }

  Future<void> _fetchCartProducts({bool isFirstLoad = false}) async {
    if (isFirstLoad) {
      setState(() {
        _isLoadingInitial = true;
        _currentPage = 1;
        _isLastPage = false;
        _cartProducts.clear();
        _selectedProductIds.clear();
      });
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      final response = await ApiClient.post(ApiUrls.getSavedlist, {
        'page': _currentPage,
        'limit': _limit,
        'type': '2'
      });

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List newItems = body['products'] ?? [];

        setState(() {
          _cartProducts.addAll(newItems);
          _isLoadingInitial = false;
          _isLoadingMore = false;
          _isLastPage = newItems.length < _limit;
          _currentPage++;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingInitial = false;
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final Color primaryColor = userProvider.primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: _buildAppBar(primaryColor),
      body: RefreshIndicator(
        onRefresh: () => _fetchCartProducts(isFirstLoad: true),
        color: primaryColor,
        child: _isLoadingInitial
            ? Center(child: CircularProgressIndicator(color: primaryColor, strokeWidth: 2))
            : _cartProducts.isEmpty
                ? _buildEmptyCart(context, primaryColor)
                : Column(
                    children: [
                      _buildSelectAllBar(primaryColor),
                      Expanded(
                        child: Stack(
                          children: [
                            _buildCartContent(primaryColor, userProvider),
                            _buildBottomCheckoutPanel(primaryColor),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  // --- Selection Logic Widgets ---

  Widget _buildSelectAllBar(Color primaryColor) {
    bool isAllSelected = _selectedProductIds.length == _cartProducts.length && _cartProducts.isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          Checkbox(
            activeColor: primaryColor,
            value: isAllSelected,
            onChanged: (val) {
              setState(() {
                if (val == true) {
                  for (var p in _cartProducts) {
                    _selectedProductIds.add(p['id'].toString());
                  }
                } else {
                  _selectedProductIds.clear();
                }
              });
            },
          ),
          const Text("Select All", style: TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          if (_selectedProductIds.isNotEmpty)
            Text("${_selectedProductIds.length} items selected", 
                style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildCartContent(Color primaryColor, UserProvider userProvider) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 280),
      itemCount: _cartProducts.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _cartProducts.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        return _buildModernCartCard(_cartProducts[index], primaryColor);
      },
    );
  }

  Widget _buildModernCartCard(dynamic item, Color primaryColor) {
    String itemId = item['id'].toString();
    bool isSelected = _selectedProductIds.contains(itemId);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isSelected ? Border.all(color: primaryColor.withOpacity(0.5), width: 1.5) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Left Side: Selection Checkbox
            Checkbox(
              activeColor: primaryColor,
              value: isSelected,
              onChanged: (val) {
                setState(() {
                  if (val == true) {
                    _selectedProductIds.add(itemId);
                  } else {
                    _selectedProductIds.remove(itemId);
                  }
                });
              },
            ),
            // Image Section
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: CachedProductImage(
                imageUrl: item['thumbnail'],
                width: 80,
                height: 90,
                borderRadius: 12,
              ),
            ),
            // Details Section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, height: 1.2),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(item['category'] ?? "General", style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                    const Spacer(),
                    Text(
                      '₹${item['price']}',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: primaryColor),
                    ),
                  ],
                ),
              ),
            ),
            // Delete Action
            IconButton(
              onPressed: () {}, 
              icon: const Icon(Icons.close, color: Colors.grey, size: 20)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomCheckoutPanel(Color primaryColor) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 40, offset: const Offset(0, -10)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _priceRow("Selected Items", "${_selectedProductIds.length}", isTotal: false),
            const SizedBox(height: 8),
            _priceRow("Delivery", "FREE", isTotal: false, valueColor: Colors.green),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Divider(),
            ),
            _priceRow("Grand Total", "₹${_selectedTotal.toStringAsFixed(2)}", isTotal: true),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _selectedProductIds.isEmpty ? null : () {
                  // Proceed with selected IDs
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 0,
                ),
                child: Text(
                  _selectedProductIds.isEmpty ? "Select Items" : "Checkout Now",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Reuse your existing AppBar, PriceRow, and Empty state methods ---
  PreferredSizeWidget _buildAppBar(Color primaryColor) {
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0.5,
      title: const Text('My Cart', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
      actions: [
        if (_cartProducts.isNotEmpty)
          IconButton(onPressed: _confirmClearCart, icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent)),
      ],
    );
  }

  Widget _priceRow(String label, String value, {required bool isTotal, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: isTotal ? 18 : 14, fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500)),
        Text(value, style: TextStyle(fontSize: isTotal ? 22 : 14, fontWeight: isTotal ? FontWeight.w900 : FontWeight.w700, color: valueColor ?? Colors.black)),
      ],
    );
  }

  void _confirmClearCart() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Cart?'),
        content: const Text('This will remove all items.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () { setState(() => _cartProducts.clear()); Navigator.pop(ctx); }, child: const Text('Clear', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context, Color primaryColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[300]),
          const Text("Your cart is empty", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}