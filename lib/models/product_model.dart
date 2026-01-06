class Product {
  final String id;
  final String sellerId;
  final String name;
  final String? description;
  final double basePrice;
  final String category;
  final List<String> images;
  final List<Map<String, dynamic>> variants;
  final double rating;
  final int reviewsCount;
  final bool isActive;

  Product({
    required this.id,
    required this.sellerId,
    required this.name,
    this.description,
    required this.basePrice,
    required this.category,
    required this.images,
    required this.variants,
    required this.rating,
    required this.reviewsCount,
    required this.isActive,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? '',
      sellerId: json['seller_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      basePrice: (json['base_price'] ?? 0).toDouble(),
      category: json['category'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      variants: List<Map<String, dynamic>>.from(json['variants'] ?? []),
      rating: (json['rating'] ?? 0).toDouble(),
      reviewsCount: json['reviews_count'] ?? 0,
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'base_price': basePrice,
    'category': category,
    'images': images,
    'variants': variants,
  };
}
