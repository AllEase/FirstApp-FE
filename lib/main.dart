import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// --- Your Imports ---
import 'providers/user_provider.dart';
import 'providers/locale_provider.dart';
import 'screens/user/shopping_home_page.dart';
import 'screens/seller/seller_dashboard.dart';
import 'screens/auth/auth_screen.dart';
import 'localization/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Note: .env not found.");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()..init()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      builder: (context, child) {
        final localeProvider = Provider.of<LocaleProvider>(context);

        return MaterialApp(
          title: 'ShopHub',
          debugShowCheckedModeBanner: false,
          locale: localeProvider.locale,
          supportedLocales: const [Locale('en'), Locale('hi'), Locale('te')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
            fontFamily: 'SegoeUI',
          ),
          home: const AppEntryPoint(),
        );
      },
    );
  }
}

class AppEntryPoint extends StatelessWidget {
  const AppEntryPoint({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        if (!userProvider.isInitialized) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!userProvider.isAuthenticated) {
          return const AuthScreen();
        }
        return userProvider.isSellerMode
            ? const SellerDashboard()
            : const ShoppingHomePage();
      },
    );
  }
}