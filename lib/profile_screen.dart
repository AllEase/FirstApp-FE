import 'package:firstapp/cache_storage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'user_provider.dart';
import 'main.dart';
import 'address_list_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  static Future<String> getUserName() async {
    final userData = await CacheStorage.getObj("user_data");
    if (userData != null && userData['firstName'] != null) {
      return userData['firstName'];
    }
    return 'Demo User';
  }

  static Future<String> getUserNumber() async {
    final userData = await CacheStorage.getObj("user_data");
    if (userData != null && userData['number'] != null) {
      return userData['number'];
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              color: const Color(0xFF4F46E5),
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 40,
                      color: Color(0xFF4F46E5),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<String>(
                    future: getUserName(),
                    builder: (context, snapshot) {
                      String nameToShow = '...';
                      if (snapshot.hasData) {
                        nameToShow = snapshot.data!;
                      } else if (snapshot.hasError) {
                        nameToShow = 'Error';
                      }
                      return Text(
                        nameToShow,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  FutureBuilder<String>(
                    future: getUserNumber(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        snapshot.data!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Settings Section
            Container(
              margin: const EdgeInsets.all(16),
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
              child: Column(
                children: [
                  // Seller Mode Switch
                  Consumer<UserProvider>(
                    builder: (context, userProvider, child) {
                      return SwitchListTile(
                        title: const Text(
                          'Seller Mode',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                        ),
                        subtitle: Text(
                          userProvider.isSellerMode
                              ? 'You are in seller mode'
                              : 'Switch to manage your products',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        value: userProvider.isSellerMode,
                        onChanged: (value) async {
                          await userProvider.toggleSellerMode();

                          // Show confirmation message
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  userProvider.isSellerMode
                                      ? 'Seller mode activated'
                                      : 'Seller mode deactivated',
                                ),
                                duration: const Duration(seconds: 2),
                                backgroundColor: const Color(0xFF4F46E5),
                              ),
                            );
                          }
                        },
                        activeColor: const Color(0xFF4F46E5),
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: userProvider.isSellerMode
                                ? const Color(0xFFDCEEFE)
                                : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.store,
                            color: userProvider.isSellerMode
                                ? const Color(0xFF4F46E5)
                                : const Color(0xFF6B7280),
                          ),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),

                  // Other Settings Options
                  _buildSettingsTile(
                    icon: Icons.shopping_bag_outlined,
                    title: 'My Orders',
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  _buildSettingsTile(
                    icon: Icons.favorite_border,
                    title: 'Wishlist',
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  _buildSettingsTile(
                    icon: Icons.location_on_outlined,
                    title: 'Addresses',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddressListScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  _buildSettingsTile(
                    icon: Icons.payment_outlined,
                    title: 'Payment Methods',
                    onTap: () {},
                  ),
                ],
              ),
            ),

            // Account Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
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
              child: Column(
                children: [
                  _buildSettingsTile(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  _buildSettingsTile(
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  _buildSettingsTile(
                    icon: Icons.info_outline,
                    title: 'About',
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  _buildSettingsTile(
                    icon: Icons.logout,
                    title: 'Logout',
                    onTap: () {
                      final userProvider = Provider.of<UserProvider>(
                        context,
                        listen: false,
                      );
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Logout'),
                          content: const Text(
                            'Are you sure you want to log out?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                userProvider.logout();
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (context) => const AppEntryPoint(),
                                  ),
                                  (Route<dynamic> route) => false,
                                );
                              },
                              child: const Text(
                                'Logout',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    textColor: Colors.red,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? const Color(0xFF6B7280)),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          color: textColor ?? const Color(0xFF111827),
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
      onTap: onTap,
    );
  }
}
