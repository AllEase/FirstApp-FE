class Order {
  final String id;
  final String userId;
  final List<Map<String, dynamic>> items;
  final double totalAmount;
  final String status;
  final Map<String, dynamic> shippingAddress;
  final String? paymentMethod;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.shippingAddress,
    this.paymentMethod,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      items: List<Map<String, dynamic>>.from(json['items'] ?? []),
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      shippingAddress: json['shipping_address'] ?? {},
      paymentMethod: json['payment_method'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => {
        'items': items,
        'total_amount': totalAmount,
        'shipping_address': shippingAddress,
        'payment_method': paymentMethod,
        'notes': notes,
      };
}
