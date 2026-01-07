import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/shipping_address.dart';
import '../../api_client.dart';
import '../../config/api_urls.dart';
import 'dart:convert';

class AddAddressScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final int? index;

  const AddAddressScreen({Key? key, this.initialData, this.index})
    : super(key: key);

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController,
      _emailController,
      _phoneController,
      _addressController,
      _zipController,
      _stateController,
      _countryController;

  String _selectedCity = 'Tanuku';
  String addressId = '';
  final Map<String, Map<String, String>> _cityData = {
    'Tanuku': {'pin': '534211', 'state': 'Andhra Pradesh', 'country': 'India'},
    'Velpur': {'pin': '534222', 'state': 'Andhra Pradesh', 'country': 'India'},
    'Relangi': {'pin': '534225', 'state': 'Andhra Pradesh', 'country': 'India'},
  };

  @override
  void initState() {
    super.initState();
    final d = widget.initialData;
    _nameController = TextEditingController(text: d?['name'] ?? '');
    _emailController = TextEditingController(text: d?['email'] ?? '');
    _phoneController = TextEditingController(text: d?['phone'] ?? '');
    _addressController = TextEditingController(text: d?['streetAddress'] ?? '');
    _zipController = TextEditingController(text: d?['pinCode'] ?? '534211');
    _stateController = TextEditingController(
      text: d?['state'] ?? 'Andhra Pradesh',
    );
    _countryController = TextEditingController(text: d?['country'] ?? 'India');
    if (d != null) {
      _selectedCity = d['city'];
      addressId = d['addressId'];
    }
  }

  @override
  void dispose() {
    for (var c in [
      _nameController,
      _emailController,
      _phoneController,
      _addressController,
      _zipController,
      _stateController,
      _countryController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final Color primaryColor = userProvider.primaryColor;
    final type = widget.index == null ? "1" : "2";
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.index == null ? 'Add Address' : 'Edit Address'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
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
              cities: _cityData.keys.toList(),
              primaryColor: primaryColor,
              onCityChanged: (val) {
                setState(() {
                  _selectedCity = val!;
                  _zipController.text = _cityData[val]!['pin']!;
                  _stateController.text = _cityData[val]!['state']!;
                });
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final data = {
                      'name': _nameController.text,
                      'streetAddress': _addressController.text,
                      'city': _selectedCity,
                      'pinCode': _zipController.text,
                      'state': _stateController.text,
                      'phone': _phoneController.text,
                      'email': _emailController.text,
                      'country': _countryController.text,
                    };
                    try {
                      final response = await ApiClient.post(
                        ApiUrls.saveAddresses,
                        {'address': data, 'type': type, 'addressId': addressId},
                      );
                      if (response.statusCode != 201) {
                        throw Exception("API Failed");
                      } else {
                        final p = Provider.of<UserProvider>(
                          context,
                          listen: false,
                        );
                        final body = jsonDecode(response.body);
                        data['addressId'] = body['addressId'];
                        widget.index == null
                            ? p.addAddress(data)
                            : p.updateAddress(widget.index!, data);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              body['message'] ?? 'Address saved successFully',
                            ),
                            backgroundColor: Color(0xFF10B981),
                          ),
                        );
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Failed to add address.")),
                      );
                    }
                  }
                },
                child: const Text(
                  'SAVE ADDRESS',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
