import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../widgets/shipping_address.dart';
import 'dart:convert';

import "../../payment/razorpay_service.dart";
import '../../api_client.dart';
import '../../config/api_urls.dart';

class CheckoutScreen extends StatefulWidget {
  final dynamic singleItem;

  const CheckoutScreen({Key? key, this.singleItem}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int _currentStep = 0;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  String _selectedCity = 'Tanuku';
  String _selectedPaymentMethod = 'cod';

  final List<String> _cities = ['Tanuku', 'Velpur', 'Relangi'];

  final Map<String, Map<String, String>> _cityData = {
    'Tanuku': {'pin': '534211', 'state': 'Andhra Pradesh', 'country': 'India'},
    'Velpur': {'pin': '534222', 'state': 'Andhra Pradesh', 'country': 'India'},
    'Relangi': {'pin': '534225', 'state': 'Andhra Pradesh', 'country': 'India'},
  };
  final _zipController = TextEditingController(text: '534211');
  final _stateController = TextEditingController(text: 'Andhra Pradesh');
  final _countryController = TextEditingController(text: 'India');

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  dynamic _getCheckoutItems(UserProvider provider) {
    if (widget.singleItem != null) {
      return [widget.singleItem!];
    }
    return []; // provider.cartIds;
  }

  double _calculateSubtotal(dynamic items) {
    return items.fold(0, (sum, item) => sum + item['totalPrice']);
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final Color primaryColor = userProvider.primaryColor;
    final checkoutItems = _getCheckoutItems(userProvider);
    final subtotal = _calculateSubtotal(checkoutItems);
    final shipping = subtotal > 499 ? 0.0 : 49.0;
    final tax = subtotal * 0.1;
    final total = subtotal + shipping + tax;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Checkout',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Progress Indicator
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStepIndicator(0, 'Shipping', primaryColor),
                _buildStepLine(0 < _currentStep, primaryColor),
                _buildStepIndicator(1, 'Review', primaryColor),
                _buildStepLine(1 < _currentStep, primaryColor),
                _buildStepIndicator(2, 'Payment', primaryColor),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _currentStep == 0
                    ? SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Text(
                                "Select Saved Address",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Consumer<UserProvider>(
                              builder: (context, userProvider, child) {
                                final addresses = userProvider.addresses;
                                if (addresses.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                return SizedBox(
                                  height: 110,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    itemCount: addresses.length,
                                    itemBuilder: (context, index) {
                                      final addr = addresses[index];
                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _nameController.text =
                                                addr['name'] ?? '';
                                            _emailController.text =
                                                addr['email'] ?? '';
                                            _phoneController.text =
                                                addr['phone'] ?? '';
                                            _addressController.text =
                                                addr['streetAddress'] ?? '';
                                            _zipController.text =
                                                addr['pinCode'] ?? '';
                                            _stateController.text =
                                                addr['state'] ?? '';
                                            _countryController.text =
                                                addr['country'] ?? '';
                                            _selectedCity =
                                                addr['city'] ?? _cities.first;
                                          });
                                        },
                                        child: _buildAddressCard(
                                          addr,
                                        ), // Helper for cleaner code
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                            const Divider(),
                            ShippingAddressUI(
                              formKey: _formKey,
                              nameController: _nameController,
                              emailController: _emailController,
                              phoneController: _phoneController,
                              addressController: _addressController,
                              zipController: _zipController,
                              stateController: _stateController,
                              countryController: _countryController,
                              selectedCity: _selectedCity,
                              cities: _cities,
                              onCityChanged: (String? value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedCity = value;
                                    final data = _cityData[value]!;
                                    _zipController.text = data['pin']!;
                                    _stateController.text = data['state']!;
                                    _countryController.text = data['country']!;
                                  });
                                }
                              },
                              primaryColor: primaryColor,
                            ),
                          ],
                        ),
                      )
                    : _currentStep == 2
                    ? _buildPaymentForm(primaryColor)
                    : _buildReviewStep(
                        checkoutItems,
                        subtotal,
                        shipping,
                        tax,
                        total,
                        primaryColor,
                      ),
              ),
            ),
          ),

          // Bottom Action Bar
          _buildBottomBar(checkoutItems, total, userProvider, primaryColor),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label, Color primaryColor) {
    final isActive = step == _currentStep;
    final isCompleted = step < _currentStep;

    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isCompleted || isActive
                ? primaryColor
                : const Color(0xFFE5E7EB),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: isActive ? Colors.white : const Color(0xFF6B7280),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color: isActive ? primaryColor : const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(bool isCompleted, Color primaryColor) {
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.only(bottom: 20),
      color: isCompleted ? primaryColor : const Color(0xFFE5E7EB),
    );
  }

  Widget _buildPaymentForm(Color primaryColor) {
    return Column(
      children: [
        _buildSectionCard(
          title: 'Payment Method',
          child: Column(
            children: [
              _buildPaymentOption(
                'razorpay',
                'Online Payment',
                Icons.payment,
                primaryColor,
              ),
              const SizedBox(height: 12),
              _buildPaymentOption(
                'cod',
                'Cash On Delivery',
                Icons.money,
                primaryColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewStep(
    List<dynamic> items,
    double subtotal,
    double shipping,
    double tax,
    double total,
    Color primaryColor,
  ) {
    return Column(
      children: [
        _buildSectionCard(
          title: 'Order Summary',
          child: Column(
            children: items.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 60,
                        height: 60,
                        color: const Color(0xFFE5E7EB),
                        child: Image.network(
                          item['image'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.image,
                              color: Color(0xFF9CA3AF),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['name'],
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Qty: ${item['quantity']}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '\u20B9${item['totalPrice'].toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: 'Shipping Address',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow(Icons.person_outline, _nameController.text),
              _buildInfoRow(Icons.email_outlined, _emailController.text),
              _buildInfoRow(Icons.phone_outlined, _phoneController.text),
              _buildInfoRow(
                Icons.location_on_outlined,
                '${_addressController.text}, $_selectedCity, ${_zipController.text}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: 'Payment Summary',
          child: Column(
            children: [
              _buildPriceRow('Subtotal', subtotal, false),
              _buildPriceRow('Shipping', shipping, false),
              _buildPriceRow('Tax', tax, false),
              const Divider(height: 24),
              _buildPriceRow('Total', total, true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildPaymentOption(
    String value,
    String label,
    IconData icon,
    Color primaryColor,
  ) {
    final isSelected = _selectedPaymentMethod == value;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? primaryColor : const Color(0xFFD1D5DB),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? primaryColor.withOpacity(0.05)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? primaryColor : const Color(0xFF6B7280),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? primaryColor : const Color(0xFF111827),
              ),
            ),
            const Spacer(),
            if (isSelected) Icon(Icons.check_circle, color: primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF6B7280)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
            ),
          ),
        ],
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
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal
                  ? const Color(0xFF111827)
                  : const Color(0xFF6B7280),
            ),
          ),
          Text(
            '\u20B9${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: const Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(
    List<dynamic> items,
    double total,
    UserProvider userProvider,
    Color primaryColor,
  ) {
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
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (_currentStep > 0)
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _currentStep--;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    side: BorderSide(color: primaryColor),
                  ),
                  child: Text(
                    'Back',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (_currentStep > 0) const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentStep == 0) {
                      if (_formKey.currentState!.validate()) {
                        setState(() {
                          _currentStep = 1;
                        });
                      }
                    } else if (_currentStep == 1) {
                      setState(() {
                        _currentStep = 2;
                      });
                    } else {
                      // Place order
                      _handlePlaceOrder(
                        items,
                        total,
                        userProvider,
                        primaryColor,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _currentStep == 2
                        ? 'Place Order - \u20B9${total.toStringAsFixed(2)}'
                        : 'Continue',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddressCard(Map<String, dynamic> addr) {
    return Container(
      width: 220,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.withOpacity(0.2)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.teal),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  addr['name'] ?? 'Home',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "${addr['streetAddress'] ?? ''}, ${addr['city'] ?? ''}, ${addr['state'] ?? ''}, ${addr['country'] ?? ''}",
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  final razorpayService = RazorpayService();
  Future<void> _handlePlaceOrder(
    dynamic items,
    double total,
    UserProvider userProvider,
    Color primaryColor,
  ) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final response = await ApiClient.post(ApiUrls.createOrder, {
        "user_id": userProvider.user!.userId,
        "items": items,
        "total": total,
        "payment_method": _selectedPaymentMethod,
        "shipping_address": {
          "name": _nameController.text,
          "email": _emailController.text,
          "phone": _phoneController.text,
          "street": _addressController.text,
          "city": _selectedCity,
          "pin": _zipController.text,
          "state": _stateController.text,
          "country": _countryController.text,
        },
      });

      Navigator.pop(context);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (_selectedPaymentMethod == "cod") {
          _showOrderSuccessDialog(items, total, primaryColor);
        } else {
          _startRazorpayFlow(data, total, items, primaryColor);
        }
      } else {
        _showErrorSnackBar("Failed to create order on server");
      }
    } catch (e) {
      Navigator.pop(context);
      _showErrorSnackBar("Error: $e");
    }
  }

  void _startRazorpayFlow(
    Map data,
    double total,
    dynamic items,
    Color primaryColor,
  ) {
    razorpayService.onSuccess = (paymentId, orderId, signature) async {
      final verifyResp = await ApiClient.post(ApiUrls.verifyPayment, {
        "razorpay_payment_id": paymentId,
        "razorpay_order_id": orderId,
        "razorpay_signature": signature,
      });
      if (verifyResp.statusCode == 200) {
        _showOrderSuccessDialog(items, total, primaryColor);
      } else {
        _showErrorSnackBar("Payment verification failed!");
      }
    };

    razorpayService.onFailure = (err) {
      _showErrorSnackBar("Payment Failed: $err");
    };

    razorpayService.openCheckout(
      orderId: data["razorpay_order_id"],
      amount: (total * 100).toInt(),
      name: "ShopHub",
      phone: dotenv.env['NUMBER'] ?? '',
      email: dotenv.env['MAIL'] ?? '',
      primaryColor: primaryColor,
    );
  }

  // Your existing UI code moved into a helper function
  void _showOrderSuccessDialog(
    dynamic items,
    double total,
    Color primaryColor,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline,
                size: 64,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Order Placed Successfully!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Order Total: \u20B9${total.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16,
                color: primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Continue Shopping',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }
}
