import 'dart:convert';
import 'package:flutter/material.dart';
import 'config/api_urls.dart';
import 'widgets/custom_text_field.dart';
import 'cache_storage.dart';
import 'api_client.dart';
import 'user_provider.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback onNavigateToSignup;
  final Function(String) onLogin;

  const LoginPage({
    Key? key,
    required this.onNavigateToSignup,
    required this.onLogin,
  }) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  bool _otpSent = false; // 🔥 state switch
  bool _loading = false;

  String get _enteredOtp => _otpControllers.map((c) => c.text).join();

  Future<void> _handleAction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final body = {
        'number': _phoneController.text,
        if (_otpSent) 'otp': _enteredOtp,
      };
      final response = await ApiClient.postWithNoToken(
        _otpSent ? ApiUrls.verifyOtp : ApiUrls.sendOtp,
        body,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!_otpSent) {
          setState(() => _otpSent = true);
        } else {
          final token = data['token'];
          await CacheStorage.save('auth_token', token);
          final userDetails = await ApiClient.post(ApiUrls.getUserDetails, {
            'userId': data['userId'],
          });
          if (userDetails.statusCode == 200 || userDetails.statusCode == 201) {
            final userData = jsonDecode(userDetails.body);
            await CacheStorage.saveObj('user_data', userData['user']);
            bool isSeller = userData['user']['is_seller'] ?? false;
            await CacheStorage.save('is_seller_mode', isSeller.toString());
            Provider.of<UserProvider>(
              context,
              listen: false,
            ).setAddresses(userData['user']['addresses']);
          }
          widget.onLogin(data['userId'].toString());
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error'] ?? 'Something went wrong')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: ${e.toString()}',
          ), // This shows the exact error message
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 448),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.login, size: 48, color: Color(0xFF4F46E5)),
            const SizedBox(height: 24),

            const Text(
              'Welcome',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Login using your phone number',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 32),
            CustomTextField(
              controller: _phoneController,
              label: 'Phone Number',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your phone number';
                }
                return null;
              },
            ),

            if (_otpSent) ...[const SizedBox(height: 16), _buildOtpFields()],

            const SizedBox(height: 32),

            // 🔘 BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _handleAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _otpSent ? 'Login' : 'Send OTP',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Don't have an account? ",
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
                GestureDetector(
                  onTap: widget.onNavigateToSignup,
                  child: const Text(
                    'Sign up',
                    style: TextStyle(
                      color: Color(0xFF4F46E5),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtpFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enter OTP',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151), // gray-700
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 45,
              child: TextFormField(
                controller: _otpControllers[index],
                focusNode: _otpFocusNodes[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                decoration: InputDecoration(
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFF4F46E5),
                      width: 2,
                    ),
                  ),
                ),
                validator: (_) {
                  if (_enteredOtp.length != 6) {
                    return '';
                  }
                  return null;
                },
                onChanged: (value) {
                  if (value.isNotEmpty && index < 5) {
                    _otpFocusNodes[index + 1].requestFocus();
                  }
                  if (value.isEmpty && index > 0) {
                    _otpFocusNodes[index - 1].requestFocus();
                  }
                },
              ),
            );
          }),
        ),
      ],
    );
  }
}
