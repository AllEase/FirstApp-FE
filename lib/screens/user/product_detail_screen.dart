import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../providers/user_provider.dart';
import '../../api_client.dart';
import '../../config/api_urls.dart';
import '../../widgets/cache_product_image.dart';
import '../../widgets/favorite_heart.dart';
import 'checkout_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  final String productName;

  const ProductDetailScreen({
    Key? key,
    required this.productId,
    required this.productName,
  }) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _productData;
  
  // Selection State
  String? _selectedColor;
  String? _selectedSize;
  Map<String, dynamic>? _selectedVariant;

  @override
  void initState() {
    super.initState();
    _fetchFullProductDetails();
  }

  Future<void> _fetchFullProductDetails() async {
    try {
      final response = await ApiClient.get("${ApiUrls.getProductDetails}?productId=${widget.productId}");
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _productData = data['data'];
          _isLoading = false;
          if (_productData!['variants'].isNotEmpty) {
            _selectedVariant = _productData!['variants'][0];
            _selectedColor = _selectedVariant!['color'];
            _selectedSize = _selectedVariant!['size'];
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching product: $e");
    }
  }

  void _updateSelection({String? color, String? size}) {
    setState(() {
      if (color != null) _selectedColor = color;
      if (size != null) _selectedSize = size;

      _selectedVariant = _productData!['variants'].firstWhere(
        (v) => v['color'] == _selectedColor && v['size'] == _selectedSize,
        orElse: () => _productData!['variants'].firstWhere((v) => v['color'] == _selectedColor),
      );
      
      _selectedSize = _selectedVariant!['size'];
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final primaryColor = userProvider.isSellerMode ? const Color(0xFF0F766E) : const Color(0xFF4F46E5);

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final List<String> availableColors = (_productData!['variants'] as List)
        .map((v) => v['color'] as String).toSet().toList();
    
    final List<String> availableSizesForColor = (_productData!['variants'] as List)
        .where((v) => v['color'] == _selectedColor)
        .map((v) => v['size'] as String).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(primaryColor),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProductHeader(primaryColor),
                const Divider(),
                _buildColorSelector(availableColors, primaryColor),
                _buildSizeSelector(availableSizesForColor, primaryColor),
                _buildDescription(),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(userProvider, primaryColor),
    );
  }

  Widget _buildAppBar(Color primaryColor) {
    return SliverAppBar(
      expandedHeight: 400,
      pinned: true,
      backgroundColor: primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        background: CachedProductImage(
          imageUrl: _selectedVariant?['image'] ?? "", // Updates when color changes
          width: double.infinity,
          height: 400,
        ),
      ),
      actions: [
        FavoriteHeart(productId: widget.productId),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildProductHeader(Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_productData!['brand'] ?? "Generic", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
          Text(
            _productData!['name'],
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            "\u20B9${_selectedVariant?['price'] ?? '0.00'}",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildColorSelector(List<String> colors, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Select Color", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: colors.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedColor == colors[index];
                return GestureDetector(
                  onTap: () => _updateSelection(color: colors[index]),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? primaryColor : Colors.grey[100],
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: isSelected ? primaryColor : Colors.grey[300]!),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      colors[index],
                      style: TextStyle(color: isSelected ? Colors.white : Colors.black),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSizeSelector(List<String> sizes, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Select Size", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: sizes.map((size) {
              final isSelected = _selectedSize == size;
              return ChoiceChip(
                label: Text(size),
                selected: isSelected,
                onSelected: (val) => _updateSelection(size: size),
                selectedColor: primaryColor,
                labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Description", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(_productData!['longDescription'] ?? "No description available.",
              style: const TextStyle(color: Colors.grey, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildBottomBar(UserProvider userProvider, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: Icon(userProvider.isProductInCart(widget.productId) ? Icons.shopping_cart : Icons.add_shopping_cart, color: primaryColor),
              onPressed: () => _addToCart(userProvider, widget.productId),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor, minimumSize: const Size(0, 56), shape: const StadiumBorder()),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => CheckoutScreen(singleItem: {
                    'id': widget.productId,
                    'name': widget.productName,
                    'totalPrice': double.parse(_selectedVariant!['price']),
                    'image': _selectedVariant!['image'],
                    'color': _selectedColor,
                    'size': _selectedSize,
                    'quantity': 1,
                  })));
                },
                child: const Text("BUY NOW", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addToCart(UserProvider userProvider, String productId) async {
    userProvider.toggleCartLocally(productId, true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final response = await ApiClient.post(ApiUrls.toggleProduct, {
        'productId': productId,
        'type': '2',
        'status': true,
      });
      if (response.statusCode != 200) {
        throw Exception("API Failed");
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text('${widget.productName} added to cart'),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 2),
            // action: SnackBarAction(
            //   label: 'VIEW CART',
            //   textColor: Colors.white,
            //   onPressed: () {},
            // ),
          ),
        );
      }
    } catch (e) {
      userProvider.toggleCartLocally(productId, false);
      messenger.showSnackBar(
        const SnackBar(content: Text("Failed to update cart.")),
      );
    }
  }
}
