import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import 'package:vora/animated_background.dart';

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
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      body: Stack(
        children: [
          // 🔹 Animated Background (fixed)
          const AnimatedBackground(),

          // 🔹 Foreground Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.05),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: isLoginPage
                      ? LoginScreen(
                          key: const ValueKey('login'),
                          onNavigateToSignup: togglePage,
                          onLogin: (name) =>
                              userProvider.setAuthenticated(true),
                        )
                      : SignupScreen(
                          key: const ValueKey('signup'),
                          onNavigateToLogin: togglePage,
                          onSignup: (name) =>
                              userProvider.setAuthenticated(true),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
