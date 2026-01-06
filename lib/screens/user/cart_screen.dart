import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import 'checkout_screen.dart';
import '../../api_client.dart';
import '../../config/api_urls.dart';
import 'dart:convert';
import '../../config/app_colors.dart';
import '../../widgets/cache_product_image.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final ScrollController _scrollController = ScrollController();
  List<dynamic> _cartProducts = [];
  int _currentPage = 1;
  final int _limit = 10;

  bool _isLoadingInitial = true;
  bool _isLoadingMore = false;
  bool _isLastPage = false;

  @override
  void initState() {
    super.initState();
    _fetchCartProducts(isFirstLoad: true);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent * 0.9) {
        if (!_isLoadingMore && !_isLastPage) {
          _fetchCartProducts();
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchCartProducts({bool isFirstLoad = false}) async {
    if (isFirstLoad) {
      setState(() {
        _isLoadingInitial = true;
        _currentPage = 1;
        _isLastPage = false;
        _cartProducts.clear();
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
      debugPrint("Cart Error: $e");
      setState(() {
        _isLoadingInitial = false;
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final Color primaryColor = userProvider.isSellerMode
        ? AppColors.sellerAppColor
        : AppColors.userAppColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Shopping Cart'),
        actions: [
          if (_cartProducts.isNotEmpty)
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear Cart'),
                    content: const Text(
                      'Are you sure you want to remove all items from your cart?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          _cartProducts.clear();
                          Navigator.pop(ctx);
                        },
                        child: const Text(
                          'Clear',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
              child: Text('Clear All', style: TextStyle(color: Colors.white),),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetchCartProducts(isFirstLoad: true),
        color: primaryColor,
        child: _isLoadingInitial
            ? Center(child: CircularProgressIndicator(color: primaryColor))
            : _cartProducts.isEmpty
            ? _buildEmptyCart(context, primaryColor)
            : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _cartProducts.length,
                      itemBuilder: (context, index) {
                        final item = _cartProducts[index];
                        return _buildCartItem(
                          context,
                          item,
                          userProvider,
                          primaryColor,
                        );
                      },
                    ),
                  ),
                  _buildCartSummary(context, userProvider, primaryColor),
                ],
              ),
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context, Color primaryColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add items to get started',
            style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Continue Shopping',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(
    BuildContext context,
    dynamic item,
    UserProvider userProvider,
    Color primaryColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Product Image
            CachedProductImage(
              imageUrl: item['thumbnail'],
              width: 80.0,
              height: 80.0,
              borderRadius: 8,
            ),
            const SizedBox(width: 12),

            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['category'],
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '\$${item['price'].toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const Spacer(),
                      // Quantity Controls
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFD1D5DB)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            _buildQuantityButton(
                              icon: Icons.remove,
                              onPressed: () {
                                if (item['quantity'] > 1) {
                                  // userProvider.updateCartItemQuantity(
                                  //   item.id,
                                  //   item.quantity - 1,
                                  // );
                                }
                              },
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                '${item['quantity']}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF111827),
                                ),
                              ),
                            ),
                            _buildQuantityButton(
                              icon: Icons.add,
                              onPressed: () {
                                // userProvider.updateCartItemQuantity(
                                //   item.id,
                                //   item.quantity + 1,
                                // );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Delete Button
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
              onPressed: () {
                //TODO userProvider.removeFromCart(item.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${item['name']} removed from cart'),
                    duration: const Duration(seconds: 2),
                    action: SnackBarAction(
                      label: 'UNDO',
                      onPressed: () {
                        //TODO userProvider.addToCart(item);
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 16, color: const Color(0xFF6B7280)),
      ),
    );
  }

  Widget _buildCartSummary(
    BuildContext context,
    UserProvider userProvider,
    Color primaryColor,
  ) {
    final subtotal = 1000.00; // TODO userProvider.cartTotal;
    final shipping = subtotal > 50 ? 0.0 : 5.99;
    final tax = subtotal * 0.08; // 8% tax
    final total = subtotal + shipping + tax;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Promo Code Section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_offer_outlined,
                      size: 20,
                      color: Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Have a promo code?',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // TODO: Implement promo code functionality
                      },
                      child: Text(
                        'Apply',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Price Breakdown
              _buildPriceRow('Subtotal', subtotal, false),
              _buildPriceRow('Shipping', shipping, false),
              _buildPriceRow('Tax', tax, false),
              const Divider(height: 24),
              _buildPriceRow('Total', total, true),
              const SizedBox(height: 20),

              // Checkout Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(
                    //     builder: (context) => const CheckoutScreen(),
                    //   ),
                    // );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Proceed to Checkout',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward,
                        size: 20,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, bool isTotal) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal
                  ? const Color(0xFF111827)
                  : const Color(0xFF6B7280),
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 20 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: const Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}
