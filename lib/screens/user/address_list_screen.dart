import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import 'add_address_screen.dart';
import '../../api_client.dart';
import '../../config/api_urls.dart';
import 'dart:convert';

class AddressListScreen extends StatelessWidget {
  const AddressListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final Color primaryColor = userProvider.primaryColor;
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Addresses'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<UserProvider>(
        builder: (context, provider, child) {
          if (provider.addresses.isEmpty) {
            return const Center(child: Text('No addresses saved.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.addresses.length,
            itemBuilder: (context, index) {
              final addr = provider.addresses[index];
              return Card(
                child: ListTile(
                  title: Text(addr['name'] ?? ''),
                  subtitle: Text(
                    "${addr['streetAddress'] ?? ''}, ${addr['city'] ?? ''}, ${addr['state'] ?? ''}, ${addr['country'] ?? ''}",
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: primaryColor),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddAddressScreen(
                              initialData: addr,
                              index: index,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          try {
                            final response =
                                await ApiClient.post(ApiUrls.saveAddresses, {
                                  'address': [],
                                  'type': '3',
                                  'addressId': addr['addressId'],
                                });
                            if (response.statusCode != 201) {
                              throw Exception("API Failed");
                            } else {
                              final p = Provider.of<UserProvider>(
                                context,
                                listen: false,
                              );
                              final body = jsonDecode(response.body);
                              p.removeAddress(index);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    body['message'] ??
                                        'Address deleted successFully',
                                  ),
                                  backgroundColor: Color(0xFF10B981),
                                ),
                              );
                              Navigator.pop(context);
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Failed to delete address."),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddAddressScreen()),
        ),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
