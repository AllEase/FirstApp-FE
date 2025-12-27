// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'user_provider.dart';

// class CheckoutScreen extends StatefulWidget {
//   final CartItem? singleItem; // For "Buy Now" functionality

//   const CheckoutScreen({Key? key, this.singleItem}) : super(key: key);

//   @override
//   State<CheckoutScreen> createState() => _CheckoutScreenState();
// }

// class _CheckoutScreenState extends State<CheckoutScreen> {
//   int _currentStep = 0;

//   // Form controllers
//   final _formKey = GlobalKey<FormState>();
//   final _nameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _addressController = TextEditingController();
//   final _cityController = TextEditingController();
//   final _zipController = TextEditingController();

//   String _selectedCountry = 'United States';
//   String _selectedPaymentMethod = 'credit_card';

//   final List<String> _countries = [
//     'United States',
//     'Canada',
//     'United Kingdom',
//     'Australia',
//     'Germany',
//     'France',
//   ];

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _emailController.dispose();
//     _phoneController.dispose();
//     _addressController.dispose();
//     _cityController.dispose();
//     _zipController.dispose();
//     super.dispose();
//   }

//   List<CartItem> _getCheckoutItems(UserProvider provider) {
//     if (widget.singleItem != null) {
//       return [widget.singleItem!];
//     }
//     return provider.cartItems;
//   }

//   double _calculateSubtotal(List<CartItem> items) {
//     return items.fold(0, (sum, item) => sum + item.totalPrice);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final userProvider = Provider.of<UserProvider>(context);
//     final Color primaryColor = userProvider.isSellerMode
//         ? const Color(0xFF0F766E)
//         : const Color(0xFF4F46E5);
//     final checkoutItems = _getCheckoutItems(userProvider);
//     final subtotal = _calculateSubtotal(checkoutItems);
//     final shipping = subtotal > 50 ? 0.0 : 5.99;
//     final tax = subtotal * 0.08;
//     final total = subtotal + shipping + tax;

//     return Scaffold(
//       backgroundColor: const Color(0xFFF9FAFB),
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: const Text(
//           'Checkout',
//           style: TextStyle(
//             color: Color(0xFF111827),
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ),
//       body: Column(
//         children: [
//           // Progress Indicator
//           Container(
//             color: Colors.white,
//             padding: const EdgeInsets.symmetric(vertical: 16),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 _buildStepIndicator(0, 'Shipping', primaryColor),
//                 _buildStepLine(0 < _currentStep, primaryColor),
//                 _buildStepIndicator(1, 'Payment', primaryColor),
//                 _buildStepLine(1 < _currentStep, primaryColor),
//                 _buildStepIndicator(2, 'Review', primaryColor),
//               ],
//             ),
//           ),

//           Expanded(
//             child: SingleChildScrollView(
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: _currentStep == 0
//                     ? _buildShippingForm(primaryColor)
//                     : _currentStep == 1
//                     ? _buildPaymentForm(primaryColor)
//                     : _buildReviewStep(
//                         checkoutItems,
//                         subtotal,
//                         shipping,
//                         tax,
//                         total,
//                         primaryColor,
//                       ),
//               ),
//             ),
//           ),

//           // Bottom Action Bar
//           _buildBottomBar(checkoutItems, total, primaryColor),
//         ],
//       ),
//     );
//   }

//   Widget _buildStepIndicator(int step, String label, Color primaryColor) {
//     final isActive = step == _currentStep;
//     final isCompleted = step < _currentStep;

//     return Column(
//       children: [
//         Container(
//           width: 40,
//           height: 40,
//           decoration: BoxDecoration(
//             color: isCompleted || isActive
//                 ? primaryColor
//                 : const Color(0xFFE5E7EB),
//             shape: BoxShape.circle,
//           ),
//           child: Center(
//             child: isCompleted
//                 ? const Icon(Icons.check, color: Colors.white, size: 20)
//                 : Text(
//                     '${step + 1}',
//                     style: TextStyle(
//                       color: isActive ? Colors.white : const Color(0xFF6B7280),
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//           ),
//         ),
//         const SizedBox(height: 8),
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: 12,
//             fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
//             color: isActive ? primaryColor : const Color(0xFF6B7280),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildStepLine(bool isCompleted, Color primaryColor) {
//     return Container(
//       width: 40,
//       height: 2,
//       margin: const EdgeInsets.only(bottom: 20),
//       color: isCompleted ? primaryColor : const Color(0xFFE5E7EB),
//     );
//   }

//   Widget _buildShippingForm(Color primaryColor) {
//     return Form(
//       key: _formKey,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _buildSectionCard(
//             title: 'Shipping Information',
//             child: Column(
//               children: [
//                 _buildTextField(
//                   controller: _nameController,
//                   label: 'Full Name',
//                   icon: Icons.person_outline,
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter your name';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 16),
//                 _buildTextField(
//                   controller: _emailController,
//                   label: 'Email',
//                   icon: Icons.email_outlined,
//                   keyboardType: TextInputType.emailAddress,
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter your email';
//                     }
//                     if (!value.contains('@')) {
//                       return 'Please enter a valid email';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 16),
//                 _buildTextField(
//                   controller: _phoneController,
//                   label: 'Phone Number',
//                   icon: Icons.phone_outlined,
//                   keyboardType: TextInputType.phone,
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter your phone number';
//                     }
//                     return null;
//                   },
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 16),
//           _buildSectionCard(
//             title: 'Delivery Address',
//             child: Column(
//               children: [
//                 _buildTextField(
//                   controller: _addressController,
//                   label: 'Street Address',
//                   icon: Icons.location_on_outlined,
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter your address';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 16),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: _buildTextField(
//                         controller: _cityController,
//                         label: 'City',
//                         icon: Icons.location_city_outlined,
//                         validator: (value) {
//                           if (value == null || value.isEmpty) {
//                             return 'Required';
//                           }
//                           return null;
//                         },
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: _buildTextField(
//                         controller: _zipController,
//                         label: 'ZIP Code',
//                         icon: Icons.markunread_mailbox_outlined,
//                         keyboardType: TextInputType.number,
//                         validator: (value) {
//                           if (value == null || value.isEmpty) {
//                             return 'Required';
//                           }
//                           return null;
//                         },
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 16),
//                 DropdownButtonFormField<String>(
//                   value: _selectedCountry,
//                   decoration: InputDecoration(
//                     labelText: 'Country',
//                     prefixIcon: const Icon(Icons.public_outlined),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                   items: _countries.map((country) {
//                     return DropdownMenuItem(
//                       value: country,
//                       child: Text(country),
//                     );
//                   }).toList(),
//                   onChanged: (value) {
//                     setState(() {
//                       _selectedCountry = value!;
//                     });
//                   },
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildPaymentForm(Color primaryColor) {
//     return Column(
//       children: [
//         _buildSectionCard(
//           title: 'Payment Method',
//           child: Column(
//             children: [
//               _buildPaymentOption(
//                 'credit_card',
//                 'Credit Card',
//                 Icons.credit_card,
//                 primaryColor,
//               ),
//               const SizedBox(height: 12),
//               _buildPaymentOption(
//                 'paypal',
//                 'PayPal',
//                 Icons.account_balance_wallet,
//                 primaryColor,
//               ),
//               const SizedBox(height: 12),
//               _buildPaymentOption(
//                 'apple_pay',
//                 'Apple Pay',
//                 Icons.apple,
//                 primaryColor,
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(height: 16),
//         if (_selectedPaymentMethod == 'credit_card')
//           _buildSectionCard(
//             title: 'Card Details',
//             child: Column(
//               children: [
//                 _buildTextField(
//                   controller: TextEditingController(),
//                   label: 'Card Number',
//                   icon: Icons.credit_card,
//                   keyboardType: TextInputType.number,
//                 ),
//                 const SizedBox(height: 16),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: _buildTextField(
//                         controller: TextEditingController(),
//                         label: 'MM/YY',
//                         icon: Icons.calendar_today,
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: _buildTextField(
//                         controller: TextEditingController(),
//                         label: 'CVV',
//                         icon: Icons.lock_outline,
//                         keyboardType: TextInputType.number,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//       ],
//     );
//   }

//   Widget _buildReviewStep(
//     List<CartItem> items,
//     double subtotal,
//     double shipping,
//     double tax,
//     double total,
//     Color primaryColor,
//   ) {
//     return Column(
//       children: [
//         _buildSectionCard(
//           title: 'Order Summary',
//           child: Column(
//             children: items.map((item) {
//               return Padding(
//                 padding: const EdgeInsets.only(bottom: 12),
//                 child: Row(
//                   children: [
//                     ClipRRect(
//                       borderRadius: BorderRadius.circular(8),
//                       child: Container(
//                         width: 60,
//                         height: 60,
//                         color: const Color(0xFFE5E7EB),
//                         child: Image.network(
//                           item.image,
//                           fit: BoxFit.cover,
//                           errorBuilder: (context, error, stackTrace) {
//                             return const Icon(
//                               Icons.image,
//                               color: Color(0xFF9CA3AF),
//                             );
//                           },
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             item.name,
//                             style: const TextStyle(
//                               fontSize: 14,
//                               fontWeight: FontWeight.w600,
//                             ),
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                           Text(
//                             'Qty: ${item.quantity}',
//                             style: const TextStyle(
//                               fontSize: 12,
//                               color: Color(0xFF6B7280),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     Text(
//                       '\$${item.totalPrice.toStringAsFixed(2)}',
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                         color: primaryColor,
//                       ),
//                     ),
//                   ],
//                 ),
//               );
//             }).toList(),
//           ),
//         ),
//         const SizedBox(height: 16),
//         _buildSectionCard(
//           title: 'Shipping Address',
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _buildInfoRow(Icons.person_outline, _nameController.text),
//               _buildInfoRow(Icons.email_outlined, _emailController.text),
//               _buildInfoRow(Icons.phone_outlined, _phoneController.text),
//               _buildInfoRow(
//                 Icons.location_on_outlined,
//                 '${_addressController.text}, ${_cityController.text}, ${_zipController.text}',
//               ),
//               _buildInfoRow(Icons.public_outlined, _selectedCountry),
//             ],
//           ),
//         ),
//         const SizedBox(height: 16),
//         _buildSectionCard(
//           title: 'Payment Summary',
//           child: Column(
//             children: [
//               _buildPriceRow('Subtotal', subtotal, false),
//               _buildPriceRow('Shipping', shipping, false),
//               _buildPriceRow('Tax', tax, false),
//               const Divider(height: 24),
//               _buildPriceRow('Total', total, true),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildSectionCard({required String title, required Widget child}) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       padding: const EdgeInsets.all(20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             title,
//             style: const TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: Color(0xFF111827),
//             ),
//           ),
//           const SizedBox(height: 16),
//           child,
//         ],
//       ),
//     );
//   }

//   Widget _buildTextField({
//     required TextEditingController controller,
//     required String label,
//     required IconData icon,
//     TextInputType? keyboardType,
//     String? Function(String?)? validator,
//   }) {
//     return TextFormField(
//       controller: controller,
//       keyboardType: keyboardType,
//       validator: validator,
//       decoration: InputDecoration(
//         labelText: label,
//         prefixIcon: Icon(icon),
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
//         ),
//       ),
//     );
//   }

//   Widget _buildPaymentOption(
//     String value,
//     String label,
//     IconData icon,
//     Color primaryColor,
//   ) {
//     final isSelected = _selectedPaymentMethod == value;
//     return InkWell(
//       onTap: () {
//         setState(() {
//           _selectedPaymentMethod = value;
//         });
//       },
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           border: Border.all(
//             color: isSelected ? primaryColor : const Color(0xFFD1D5DB),
//             width: isSelected ? 2 : 1,
//           ),
//           borderRadius: BorderRadius.circular(12),
//           color: isSelected
//               ? primaryColor.withOpacity(0.05)
//               : Colors.transparent,
//         ),
//         child: Row(
//           children: [
//             Icon(
//               icon,
//               color: isSelected ? primaryColor : const Color(0xFF6B7280),
//             ),
//             const SizedBox(width: 12),
//             Text(
//               label,
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
//                 color: isSelected ? primaryColor : const Color(0xFF111827),
//               ),
//             ),
//             const Spacer(),
//             if (isSelected) Icon(Icons.check_circle, color: primaryColor),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoRow(IconData icon, String text) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8),
//       child: Row(
//         children: [
//           Icon(icon, size: 18, color: const Color(0xFF6B7280)),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Text(
//               text,
//               style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildPriceRow(String label, double amount, bool isTotal) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             label,
//             style: TextStyle(
//               fontSize: isTotal ? 16 : 14,
//               fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
//               color: isTotal
//                   ? const Color(0xFF111827)
//                   : const Color(0xFF6B7280),
//             ),
//           ),
//           Text(
//             '\$${amount.toStringAsFixed(2)}',
//             style: TextStyle(
//               fontSize: isTotal ? 18 : 14,
//               fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
//               color: const Color(0xFF111827),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildBottomBar(
//     List<CartItem> items,
//     double total,
//     Color primaryColor,
//   ) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 10,
//             offset: const Offset(0, -4),
//           ),
//         ],
//       ),
//       child: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Row(
//             children: [
//               if (_currentStep > 0)
//                 OutlinedButton(
//                   onPressed: () {
//                     setState(() {
//                       _currentStep--;
//                     });
//                   },
//                   style: OutlinedButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 24,
//                       vertical: 16,
//                     ),
//                     side: BorderSide(color: primaryColor),
//                   ),
//                   child: Text(
//                     'Back',
//                     style: TextStyle(
//                       color: primaryColor,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               if (_currentStep > 0) const SizedBox(width: 12),
//               Expanded(
//                 child: ElevatedButton(
//                   onPressed: () {
//                     if (_currentStep == 0) {
//                       if (_formKey.currentState!.validate()) {
//                         setState(() {
//                           _currentStep = 1;
//                         });
//                       }
//                     } else if (_currentStep == 1) {
//                       setState(() {
//                         _currentStep = 2;
//                       });
//                     } else {
//                       // Place order
//                       _placeOrder(items, total, primaryColor);
//                     }
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: primaryColor,
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                   child: Text(
//                     _currentStep == 2
//                         ? 'Place Order - \$${total.toStringAsFixed(2)}'
//                         : 'Continue',
//                     style: const TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   void _placeOrder(List<CartItem> items, double total, Color primaryColor) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (ctx) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: primaryColor.withOpacity(0.1),
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(
//                 Icons.check_circle_outline,
//                 size: 64,
//                 color: primaryColor,
//               ),
//             ),
//             const SizedBox(height: 24),
//             const Text(
//               'Order Placed Successfully!',
//               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 12),
//             Text(
//               'Order Total: \$${total.toStringAsFixed(2)}',
//               style: TextStyle(
//                 fontSize: 16,
//                 color: primaryColor,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//             const SizedBox(height: 8),
//             const Text(
//               'Thank you for your purchase!',
//               style: TextStyle(color: Color(0xFF6B7280)),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 24),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: () {
//                   final userProvider = Provider.of<UserProvider>(
//                     context,
//                     listen: false,
//                   );
//                   if (widget.singleItem == null) {
//                     userProvider.clearCart();
//                   }
//                   Navigator.of(ctx).pop(); // Close dialog
//                   Navigator.of(
//                     context,
//                   ).popUntil((route) => route.isFirst); // Go to home
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: primaryColor,
//                   padding: const EdgeInsets.symmetric(vertical: 12),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//                 child: const Text(
//                   'Continue Shopping',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
