import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/user_provider.dart';
import 'screens/user/shopping_home_page.dart';
import 'screens/seller/seller_dashboard.dart';

/// Main app entry point with Provider integration
class AppMain extends StatelessWidget {
  const AppMain({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => UserProvider()..init(),
      child: MaterialApp(
        title: 'ShopHub',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primarySwatch: Colors.indigo),
        home: const AppEntryPoint(),
      ),
    );
  }
}

/// Entry point that decides which screen to show based on seller mode
class AppEntryPoint extends StatelessWidget {
  const AppEntryPoint({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        // Show loading indicator while initializing
        if (!userProvider.isInitialized) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
            ),
          );
        }

        // Show appropriate screen based on seller mode
        if (userProvider.isSellerMode) {
          return const SellerDashboard();
        } else {
          return ShoppingHomePage();
        }
      },
    );
  }
}
