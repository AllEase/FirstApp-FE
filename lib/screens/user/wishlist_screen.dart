import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vora/config/app_colors.dart';
import '../../api_client.dart';
import '../../config/api_urls.dart';
import 'product_detail_screen.dart';
import '../../providers/user_provider.dart';
import '../../widgets/favorite_heart.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({Key? key}) : super(key: key);

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final ScrollController _scrollController = ScrollController();
  List<dynamic> _favoriteProducts = [];
  int _currentPage = 1;
  final int _limit = 10;

  bool _isLoadingInitial = true;
  bool _isLoadingMore = false;
  bool _isLastPage = false;

  @override
  void initState() {
    super.initState();
    _fetchFavorites(isFirstLoad: true);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent * 0.9) {
        if (!_isLoadingMore && !_isLastPage) {
          _fetchFavorites();
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchFavorites({bool isFirstLoad = false}) async {
    if (isFirstLoad) {
      setState(() {
        _isLoadingInitial = true;
        _currentPage = 1;
        _isLastPage = false;
        _favoriteProducts.clear();
      });
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      final response = await ApiClient.post(ApiUrls.getSavedlist, {
        'page': _currentPage,
        'limit': _limit,
        'type': '1'
      });

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List newItems = body['products'] ?? [];

        setState(() {
          _favoriteProducts.addAll(newItems);
          _isLoadingInitial = false;
          _isLoadingMore = false;
          _isLastPage = newItems.length < _limit;
          _currentPage++;
        });
      }
    } catch (e) {
      debugPrint("Wishlist Error: $e");
      setState(() {
        _isLoadingInitial = false;
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access theme based on persistent Seller Mode
    final userProvider = Provider.of<UserProvider>(context);
    final bool isSellerMode = userProvider.isSellerMode;
    final Color primaryColor = userProvider.primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(isSellerMode ? "Merchant Favorites" : "My Wishlist"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetchFavorites(isFirstLoad: true),
        color: primaryColor,
        child: _isLoadingInitial
            ? Center(child: CircularProgressIndicator(color: primaryColor))
            : _favoriteProducts.isEmpty
            ? _buildEmptyState()
            : GridView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.72,
                ),
                itemCount: _favoriteProducts.length + (_isLoadingMore ? 2 : 0),
                itemBuilder: (context, index) {
                  if (index >= _favoriteProducts.length) {
                    return Center(
                      child: CircularProgressIndicator(color: primaryColor),
                    );
                  }
                  return _buildFavoriteCard(
                    _favoriteProducts[index],
                    index,
                    primaryColor,
                  );
                },
              ),
      ),
    );
  }

  Widget _buildFavoriteCard(dynamic item, int index, Color primaryColor) {
    final String productId = item['id'].toString();

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetailScreen(
            productId: productId,
            productName: item['name']
          ),
        ),
      ),
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
                        item['thumbnail'] ?? '',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) =>
                            const Icon(Icons.broken_image),
                      ),
                    ),
                  ),
                  // Common Heart Widget replacing the delete button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: FavoriteHeart(
                      productId: productId,
                      onToggle: () {
                        // Immediate UI feedback: remove from list when heart is clicked
                        setState(() {
                          _favoriteProducts.removeAt(index);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "${item['name']} removed from wishlist",
                            ),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
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
                    item['name'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '\$${item['price']}',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
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

  Widget _buildEmptyState() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
        const Icon(Icons.favorite_border, size: 80, color: Colors.grey),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            "Your wishlist is empty",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      ],
    );
  }
}
