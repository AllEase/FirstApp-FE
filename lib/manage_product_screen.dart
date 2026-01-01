import 'dart:convert';
import 'widgets/cache_product_image.dart';
import 'package:flutter/material.dart';
import 'cache_storage.dart';
import 'api_client.dart';
import 'config/api_urls.dart';

class ManageProductsScreen extends StatefulWidget {
  const ManageProductsScreen({Key? key}) : super(key: key);

  @override
  State<ManageProductsScreen> createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends State<ManageProductsScreen> {
  final ScrollController _scrollController = ScrollController();
  List<dynamic> _myProducts = [];
  int _currentPage = 1;
  final int _limit = 10;
  bool _isLoadingInitial = true;
  bool _isLoadingMore = false;
  bool _isLastPage = false;

  @override
  void initState() {
    super.initState();
    _fetchOwnProducts(isFirstLoad: true);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent * 0.9) {
        if (!_isLoadingMore && !_isLastPage) {
          _fetchOwnProducts();
        }
      }
    });
  }

  Future<void> _fetchOwnProducts({bool isFirstLoad = false}) async {
    if (isFirstLoad) {
      setState(() {
        _currentPage = 1;
        _isLoadingInitial = true;
        _isLastPage = false;
        _myProducts.clear();
      });
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      final userData = await CacheStorage.getObj('user_data');
      final userId = userData?['userId'] ?? '';

      // API Call to get products listed by THIS user
      final response = await ApiClient.post(ApiUrls.getOwnProducts, {
        'userId': userId,
        'page': _currentPage,
        'limit': _limit,
      });

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List newProducts = body['products'];

        setState(() {
          _myProducts.addAll(newProducts);
          _isLastPage = newProducts.length < _limit;
          _isLoadingInitial = false;
          _isLoadingMore = false;
          _currentPage++;
        });
      }
    } catch (e) {
      debugPrint("Error fetching own products: $e");
      setState(() {
        _isLoadingInitial = false;
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage My Products'),
        backgroundColor: const Color(0xFF0F766E), // Seller Mode Teal
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetchOwnProducts(isFirstLoad: true),
        child: _isLoadingInitial
            ? const Center(child: CircularProgressIndicator())
            : _myProducts.isEmpty
            ? _buildEmptyState()
            : ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _myProducts.length + (_isLoadingMore ? 1 : 0),
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index == _myProducts.length) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return _buildProductListItem(_myProducts[index]);
                },
              ),
      ),
    );
  }

  Widget _buildProductListItem(Map<String, dynamic> product) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5),
        ],
      ),
      child: Row(
        children: [
          // Product Thumbnail
          CachedProductImage(
            imageUrl: product['thumbnail'] ?? '',
            width: 80.0,
            height: 80.0,
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name'] ?? 'Untitled',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '\$${product['price']}',
                  style: const TextStyle(
                    color: Color(0xFF0F766E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Actions
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.blueGrey),
            onPressed: () {
              // TODO: Navigate to Edit Page
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () {
              // TODO: Implement Delete logic with a confirmation dialog
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text("You haven't listed any products yet."),
          TextButton(
            onPressed: () => _fetchOwnProducts(isFirstLoad: true),
            child: const Text("Refresh"),
          ),
        ],
      ),
    );
  }
}
