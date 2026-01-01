import 'package:flutter/material.dart';

class ShippingAddressUI extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final TextEditingController zipController;
  final TextEditingController stateController;
  final TextEditingController countryController;
  final String? selectedCity;
  final List<String> cities;
  final Function(String?) onCityChanged;
  final Color primaryColor;

  const ShippingAddressUI({
    Key? key,
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.addressController,
    required this.zipController,
    required this.stateController,
    required this.countryController,
    required this.selectedCity,
    required this.cities,
    required this.onCityChanged,
    required this.primaryColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          _buildCard('Shipping Information', [
            _buildField(nameController, 'Full Name', Icons.person_outline, TextInputType.text),
            const SizedBox(height: 16),
            _buildField(emailController, 'Email', Icons.email_outlined, TextInputType.emailAddress),
            const SizedBox(height: 16),
            _buildField(phoneController, 'Phone', Icons.phone_outlined, TextInputType.number),
          ]),
          const SizedBox(height: 16),
          _buildCard('Delivery Address', [
            _buildField(
              addressController,
              'Street Address',
              Icons.location_on_outlined,
              TextInputType.streetAddress
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedCity,
              alignment: AlignmentDirectional.bottomStart,
              decoration: _inputDecoration(
                'Select City',
                Icons.location_city_outlined,
              ),
              items: cities
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: onCityChanged,
              validator: (v) => v == null ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildReadOnly(
                    zipController,
                    'PIN',
                    Icons.pin_drop_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildReadOnly(
                    stateController,
                    'State',
                    Icons.map_outlined,
                  ),
                ),
              ],
            ),
          ]),
        ],
      ),
    );
  }

  // --- UI Helpers ---
  InputDecoration _inputDecoration(String label, IconData icon) =>
      InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
      );

  Widget _buildField(TextEditingController ctrl, String lbl, IconData icon, TextInputType type) =>
      TextFormField(
        controller: ctrl,
        keyboardType: type,
        decoration: _inputDecoration(lbl, icon),
        validator: (v) => v!.isEmpty ? 'Required' : null,
      );

  Widget _buildReadOnly(
    TextEditingController ctrl,
    String lbl,
    IconData icon,
  ) => TextFormField(
    controller: ctrl,
    readOnly: true,
    enabled: false,
    decoration: _inputDecoration(lbl, icon).copyWith(
      filled: true,
      fillColor: Colors.grey[100],
      border: InputBorder.none,
    ),
  );

  Widget _buildCard(String title, List<Widget> children) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    ),
  );
}
