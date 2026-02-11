import 'package:flutter/material.dart';
import 'dart:convert';
import '../../api_client.dart';
import '../../config/api_urls.dart';

import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  bool isLoading = true;
  List orders = [];

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  // Swipe to Refresh logic added for better UX
  Future<void> fetchOrders() async {
    setState(() => isLoading = true);
    try {
      final response = await ApiClient.get(ApiUrls.getUserOrders);
      final data = json.decode(response.body);
      setState(() {
        orders = data["orders"] ?? [];
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error fetching orders: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final Color primaryColor = userProvider.primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Soft professional grey
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: const Text("My Orders"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchOrders,
              child: orders.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: orders.length,
                      itemBuilder: (context, index) =>
                          _orderCard(orders[index]),
                    ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      // ListView allows RefreshIndicator to work on empty screen
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        const Icon(Icons.shopping_bag_outlined, size: 100, color: Colors.grey),
        const SizedBox(height: 20),
        const Center(
          child: Text(
            "No orders found",
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _orderCard(Map order) {
    // Logic for Status Colors
    String status = order['status']?.toString().toUpperCase() ?? "PENDING";
    Color statusColor = (status == "PAID" || status == "DELIVERED")
        ? Colors.green
        : (status == "CANCELLED" ? Colors.red : Colors.orange);

    // Get image of the first product
    String? firstProductImage =
        (order['items'] != null && order['items'].isNotEmpty)
        ? order['items'][0]['image']
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[100],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: firstProductImage != null
                  ? Image.network(
                      firstProductImage,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) =>
                          const Icon(Icons.image, color: Colors.grey),
                    )
                  : const Icon(Icons.shopping_basket, color: Colors.grey),
            ),
          ),
          title: Text(
            order['items'] != null && order['items'].length > 1
                ? "${order['items'][0]['name']} +${order['items'].length - 1} more"
                : "${order['items'][0]['name'] ?? 'Order Item'}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                "₹${order['total']}",
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              _statusBadge(status, statusColor),
            ],
          ),
          children: [
            const Divider(height: 1, indent: 16, endIndent: 16),
            _buildExpandedDetails(order),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildExpandedDetails(Map order) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow(
            Icons.location_on_outlined,
            "Shipping to",
            "${order['shipping_address']?['street']}, ${order['shipping_address']?['city']}",
          ),
          const SizedBox(height: 12),
          _infoRow(
            Icons.payment_outlined,
            "Payment Method",
            "${order['payment_method']}",
          ),
          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.receipt_long, size: 18),
                  label: const Text("Invoice"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text("Track Order"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
