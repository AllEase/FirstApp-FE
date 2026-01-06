import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../widgets/custom_text_field.dart';
import '../../providers/user_provider.dart';
import '../../localization/app_localizations.dart';

class SignupScreen extends StatefulWidget {
  final VoidCallback onNavigateToLogin;
  final Function(String) onSignup;

  const SignupScreen({
    Key? key,
    required this.onNavigateToLogin,
    required this.onSignup,
  }) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  bool _otpSent = false;
  bool _loading = false;

  String get _enteredOtp => _otpControllers.map((c) => c.text).join();

  Future<void> _handleAction() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    bool success = await userProvider.signUp(
      _phoneController.text,
      _firstNameController.text,
      _lastNameController.text,
      _enteredOtp,
      _otpSent,
    );
    if (!mounted) return;
    if (success) {
      if (!_otpSent) {
        setState(() => _otpSent = true);
      } else {
        widget.onSignup(userProvider.user!.userId.toString());
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userProvider.error),
          backgroundColor: Colors.red,
        ),
      );
    }
    setState(() => _loading = false);
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
            Text(
              context.loc("create_account"),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827), // gray-900
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              context.loc('signup_started'),
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280), // gray-600
              ),
            ),
            const SizedBox(height: 32),

            // Phone Number Input
            CustomTextField(
              controller: _phoneController,
              label: context.loc('phone_number'),
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return context.loc('phone_error');
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _firstNameController,
              label: context.loc('first_name'),
              icon: Icons.person_outline,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return context.loc('error_first_name');
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _lastNameController,
              label: context.loc('last_name'),
              icon: Icons.person_outline,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return context.loc('error_last_name');
                }
                return null;
              },
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
                        _otpSent ? context.loc('sign_up') : context.loc('send_otp'),
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ),

            const SizedBox(height: 24),

            // Login link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  context.loc('already_have_account'),
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
                GestureDetector(
                  onTap: widget.onNavigateToLogin,
                  child: Text(
                    context.loc('login'),
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
        Text(
          context.loc('enter_otp'),
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
