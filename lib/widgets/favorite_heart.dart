import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../api_client.dart';
import '../config/api_urls.dart';

class FavoriteHeart extends StatelessWidget {
  final String productId;
  final VoidCallback? onToggle;

  const FavoriteHeart({
    Key? key,
    required this.productId,
    this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    if (userProvider.isSellerMode) return const SizedBox.shrink();

    final bool isFav = userProvider.isProductFavorited(productId);

    return GestureDetector(
      onTap: () async {
        userProvider.toggleFavoriteLocally(productId, !isFav);
        if (onToggle != null) onToggle!();

        try {
          final response = await ApiClient.post(ApiUrls.toggleProduct, {
            'productId': productId,
            'type': "1",
            'status': !isFav,
          });
          if (response.statusCode != 200) throw Exception("API Failed");
        } catch (e) {
          // 5. Rollback on failure
          userProvider.toggleFavoriteLocally(productId, isFav);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to update favorite.")),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
        ),
        child: Icon(
          isFav ? Icons.favorite : Icons.favorite_outline,
          color: isFav ? Colors.red : Colors.grey,
          size: 20,
        ),
      ),
    );
  }
}