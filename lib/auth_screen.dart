import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'user_provider.dart';
import 'login_page.dart';
import 'signup_page.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLoginPage = true;

  void togglePage() {
    setState(() {
      isLoginPage = !isLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    // We use listen: false because we just want to call the login/signup methods
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFEFF6FF), // Light Blue
              Color(0xFFE0E7FF), // Light Indigo
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: isLoginPage
                ? LoginPage(
                    onNavigateToSignup: togglePage,
                    // When the API login succeeds, update the Provider
                    onLogin: (name) => userProvider.setAuthenticated(true, name),
                  )
                : SignupPage(
                    onNavigateToLogin: togglePage,
                    // When the API signup succeeds, update the Provider
                    onSignup: (name) => userProvider.setAuthenticated(true, name),
                  ),
          ),
        ),
      ),
    );
  }
}