import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'user_provider.dart';
import 'widgets/favorite_heart.dart'; // Ensure correct path

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  final String productName;
  final double price;
  final String image;
  final String category;

  const ProductDetailScreen({
    Key? key,
    required this.productId,
    required this.productName,
    required this.price,
    required this.image,
    required this.category,
  }) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  String _selectedSize = 'M';
  final List<String> _sizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];

  void _incrementQuantity() {
    setState(() => _quantity++);
  }

  void _decrementQuantity() {
    if (_quantity > 1) setState(() => _quantity--);
  }

  void _addToCart(Color themeColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.productName} added to cart (Qty: $_quantity)'),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'VIEW CART',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Access Global Theme via Provider
    final userProvider = Provider.of<UserProvider>(context);
    final bool isSellerMode = userProvider.isSellerMode;
    final Color primaryColor = isSellerMode ? const Color(0xFF0F766E) : const Color(0xFF4F46E5);

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            backgroundColor: primaryColor,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined, color: Colors.white),
                onPressed: () {},
              ),
              // Updated: Replaced local bool with global FavoriteHeart
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: FavoriteHeart(
                  productId: widget.productId// White heart looks better on the image background
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.image,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFFE5E7EB),
                      child: const Icon(Icons.image, size: 150, color: Color(0xFF9CA3AF)),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.3)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.category,
                          style: TextStyle(
                            fontSize: 12,
                            color: primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.productName,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Row(
                        children: [
                          Icon(Icons.star, size: 20, color: Color(0xFFFBBF24)),
                          Icon(Icons.star, size: 20, color: Color(0xFFFBBF24)),
                          Icon(Icons.star, size: 20, color: Color(0xFFFBBF24)),
                          Icon(Icons.star, size: 20, color: Color(0xFFFBBF24)),
                          Icon(Icons.star_half, size: 20, color: Color(0xFFFBBF24)),
                          SizedBox(width: 8),
                          Text('4.5', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '\$${widget.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                if (widget.category == 'Clothing') ...[
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Select Size', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: _sizes.map((size) {
                            final isSelected = size == _selectedSize;
                            return ChoiceChip(
                              label: Text(size),
                              selected: isSelected,
                              selectedColor: primaryColor,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : const Color(0xFF111827),
                              ),
                              onSelected: (val) => setState(() => _selectedSize = size),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                ],
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Description', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      Text(
                        'This high-quality ${widget.category.toLowerCase()} item is designed for comfort and durability. Perfect for daily wear or special occasions.',
                        style: const TextStyle(color: Color(0xFF6B7280), height: 1.6),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildFeatureItem(Icons.local_shipping_outlined, 'Free Shipping', primaryColor),
                      const SizedBox(height: 12),
                      _buildFeatureItem(Icons.verified_user_outlined, 'Secure Payment', primaryColor),
                    ],
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFD1D5DB)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    IconButton(icon: const Icon(Icons.remove), onPressed: _decrementQuantity),
                    Text('$_quantity', style: const TextStyle(fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.add), onPressed: _incrementQuantity),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _addToCart(primaryColor),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    'Add to Cart - \$${(widget.price * _quantity).toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, Color primaryColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: primaryColor.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: primaryColor, size: 24),
        ),
        const SizedBox(width: 12),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}