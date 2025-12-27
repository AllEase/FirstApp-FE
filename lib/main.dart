import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Import your screen files here
import 'user_provider.dart';
import 'shopping_home_page.dart';
import 'seller_dashboard.dart';
import 'auth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables for your backend
  await dotenv.load(fileName: ".env");

  runApp(
    ChangeNotifierProvider(
      // The ..init() ensures the app checks SharedPreferences immediately
      create: (context) => UserProvider()..init(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShopHub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const AppEntryPoint(),
    );
  }
}

class AppEntryPoint extends StatelessWidget {
  const AppEntryPoint({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        // 1. Splash / Loading State
        if (!userProvider.isInitialized) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. Auth Check: If not logged in, show Auth Flow
        if (!userProvider.isAuthenticated) {
          return const AuthScreen();
        }

        // 3. Persistent Role Check:
        // Because of the Provider, if isSellerMode is true, 
        // they stay here until they toggle it off in Profile.
        if (userProvider.isSellerMode) {
          return const SellerDashboard();
        } else {
          return ShoppingHomePage();
        }
      },
    );
  }
}