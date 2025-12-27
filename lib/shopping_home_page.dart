import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'profile_screen.dart';
import 'api_client.dart';
import 'config/constants.dart';
import 'user_provider.dart';
import 'product_detail_screen.dart';
import 'wishlist_screen.dart';
import 'widgets/favorite_heart.dart';

class Product {
  final String id;
  final String name;
  final double price;
  final String image;
  final String category;
  bool isFavorite;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
    required this.category,
    this.isFavorite = false,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    String imageUrl = (json['thumbnail'] ?? json['image'] ?? '')
        .toString()
        .trim();
    return Product(
      id: json['id'].toString(),
      name: json['name'] ?? 'Unknown Product',
      price: (json['price'] ?? 0.0).toDouble(),
      image: imageUrl,
      category: json['category'] ?? 'General',
      isFavorite: json['favorite'] ?? false,
    );
  }
}

class ShoppingHomePage extends StatefulWidget {
  const ShoppingHomePage({Key? key}) : super(key: key);

  @override
  State<ShoppingHomePage> createState() => _ShoppingHomePageState();
}

class _ShoppingHomePageState extends State<ShoppingHomePage> {
  final ScrollController _scrollController = ScrollController();
  List<Product> _allProducts = [];
  int _currentPage = 1;
  final int _perPageLimit = 10;

  bool _isLoadingInitial = true;
  bool _isLoadingMore = false;
  bool _isLastPage = false;

  @override
  void initState() {
    super.initState();
    _initialLoad();

    // Infinite Scroll Listener
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent * 0.8) {
        if (!_isLoadingMore && !_isLastPage) {
          _loadMoreProducts();
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initialLoad() async {
    setState(() => _isLoadingInitial = true);
    final products = await _fetchProducts(page: 1);
    setState(() {
      _allProducts = products;
      _isLoadingInitial = false;
    });
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _currentPage = 1;
      _isLastPage = false;
    });
    final products = await _fetchProducts(page: 1);
    setState(() {
      _allProducts = products;
    });
  }

  Future<void> _loadMoreProducts() async {
    setState(() => _isLoadingMore = true);
    _currentPage++;
    final nextPage = await _fetchProducts(page: _currentPage);
    setState(() {
      _allProducts.addAll(nextPage);
      _isLoadingMore = false;
    });
  }

  Future<List<Product>> _fetchProducts({int page = 1}) async {
    try {
      final response = await ApiClient.post(Constants.getHomePageList, {
        'page': page,
        'limit': _perPageLimit,
      });

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final List<dynamic> productData = body['products'] ?? [];

        // Update the Provider with initial favorite states from API
        final favoriteIdsFromApi = productData
            .where((item) => item['favorite'] == true)
            .map((item) => item['id'].toString())
            .toList();

        Provider.of<UserProvider>(
          context,
          listen: false,
        ).setInitialFavorites(favoriteIdsFromApi);

        if (productData.length < _perPageLimit) {
          _isLastPage = true;
        }
        return productData.map((item) => Product.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching products: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final bool isSellerMode = userProvider.isSellerMode;
    final Color primaryColor = isSellerMode
        ? const Color(0xFF0F766E)
        : const Color(0xFF4F46E5);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: primaryColor,
        child: Column(
          children: [
            _buildHeader(context, primaryColor, isSellerMode),
            Expanded(
              child: _isLoadingInitial
                  ? Center(
                      child: CircularProgressIndicator(color: primaryColor),
                    )
                  : SingleChildScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          _buildHeroBanner(primaryColor, isSellerMode),
                          _buildProductsSection(isSellerMode),
                          if (_isLoadingMore)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: CircularProgressIndicator(
                                color: primaryColor,
                              ),
                            ),
                          if (_isLastPage && _allProducts.isNotEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Text(
                                "You've seen it all!",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    Color primaryColor,
    bool isSellerMode,
  ) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.shopping_cart,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isSellerMode ? 'SellerHub' : 'ShopHub',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (!isSellerMode)
                    IconButton(
                      icon: const Icon(Icons.favorite_outline),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WishlistScreen(),
                        ),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.person_outline),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    ),
                  ),
                  if (!isSellerMode)
                    IconButton(
                      icon: const Icon(Icons.shopping_cart_outlined),
                      onPressed: () {},
                    ),
                ],
              ),
            ),
            _buildSearchBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search products...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          fillColor: Colors.grey[100],
          filled: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildHeroBanner(Color primaryColor, bool isSellerMode) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withOpacity(0.7)],
        ),
      ),
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isSellerMode ? 'Seller Dashboard' : 'Winter Sale 2025',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            isSellerMode
                ? 'Manage your business inventory'
                : 'Exclusive deals just for you',
            style: const TextStyle(fontSize: 16, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsSection(bool isSellerMode) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Featured Products',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _allProducts.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text("No products found."),
                  ),
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: _allProducts.length,
                  itemBuilder: (context, index) => _ProductCard(
                    product: _allProducts[index],
                    isSellerMode: isSellerMode,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF111827),
      padding: const EdgeInsets.all(16),
      child: const Center(
        child: Text('© 2025 ShopHub', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

// --- Optimized Product Card Widget using Common Heart Widget ---
class _ProductCard extends StatelessWidget {
  final Product product;
  final bool isSellerMode;

  const _ProductCard({required this.product, required this.isSellerMode});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetailScreen(
            productId: product.id,
            productName: product.name,
            price: product.price,
            image: product.image,
            category: product.category,
          ),
        ),
      ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: Image.network(
                        product.image,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => Container(
                          color: Colors.grey[100],
                          child: const Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Use the common FavoriteHeart widget here
                  Positioned(
                    top: 8,
                    right: 8,
                    child: FavoriteHeart(productId: product.id),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: isSellerMode
                          ? const Color(0xFF0F766E)
                          : const Color(0xFF4F46E5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
