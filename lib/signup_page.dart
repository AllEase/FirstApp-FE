import 'package:flutter/material.dart';
import 'dart:convert';
import 'config/constants.dart';
import 'widgets/common_text_field.dart';
import 'api_client.dart';
import 'cache_storage.dart';

class SignupPage extends StatefulWidget {
  final VoidCallback onNavigateToLogin;
  final Function(String) onSignup;

  const SignupPage({
    Key? key,
    required this.onNavigateToLogin,
    required this.onSignup,
  }) : super(key: key);

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
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
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        if (_otpSent) 'otp': _enteredOtp,
        'signup': true,
      };
      final response = await ApiClient.postWithNoToken(
        _otpSent ? Constants.verifyOtp : Constants.sendOtp,
        body,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!_otpSent) {
          setState(() => _otpSent = true);
        } else {
          final token = data['token'];
          await CacheStorage.save('auth_token', token);
          final userDetails = await ApiClient.post(Constants.getUserDetails, {
            'userId': data['userId'],
          });
          if (userDetails.statusCode == 200 || userDetails.statusCode == 201) {
            final userData = jsonDecode(userDetails.body);
            await CacheStorage.saveObj('user_data', userData['user']);
          }
          widget.onSignup(data['userId'].toString());
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error'] ?? 'Signup failed')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Network error')));
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text('Error: ${e.toString()}'),
      //   ),
      // );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
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
      padding: const EdgeInsets.all(32),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFF4F46E5), // indigo-600
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_add,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            const Text(
              'Create Account',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827), // gray-900
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle
            const Text(
              'Sign up to get started',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280), // gray-600
              ),
            ),
            const SizedBox(height: 32),

            // Phone Number Input
            CommonTextField(
              controller: _phoneController,
              label: 'Phone Number',
              hintText: 'Enter your phone number',
              keyboardType: TextInputType.phone,
              validationMessage: 'Please enter your phone number',
              isRequired: true,
            ),
            const SizedBox(height: 8),
            CommonTextField(
              controller: _firstNameController,
              label: 'First Name',
              hintText: 'Enter your first name',
              keyboardType: TextInputType.name,
              validationMessage: 'Please enter your first name',
              isRequired: true,
            ),
            const SizedBox(height: 8),
            CommonTextField(
              controller: _lastNameController,
              label: 'Last Name',
              hintText: 'Enter your last name',
              keyboardType: TextInputType.name,
            ),
            if (_otpSent) ...[const SizedBox(height: 16), _buildOtpFields()],
            const SizedBox(height: 24),

            // Sign Up Button
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
                        _otpSent ? 'Sign Up' : 'Send OTP',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ),

            const SizedBox(height: 24),

            // Login link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Already have an account? ',
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
                GestureDetector(
                  onTap: widget.onNavigateToLogin,
                  child: const Text(
                    'Login',
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
