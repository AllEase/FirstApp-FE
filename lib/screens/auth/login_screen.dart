import 'package:flutter/material.dart';
import '../../widgets/custom_text_field.dart';
import '../../providers/user_provider.dart';
import 'package:provider/provider.dart';

import '../../localization/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onNavigateToSignup;
  final Function(String) onLogin;

  const LoginScreen({
    Key? key,
    required this.onNavigateToSignup,
    required this.onLogin,
  }) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
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
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    bool success = await userProvider.login(
      _phoneController.text,
      _enteredOtp,
      _otpSent,
    );
    if (success) {
      if (!_otpSent) {
        setState(() => _otpSent = true);
      } else {
        widget.onLogin(userProvider.user!.userId.toString());
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userProvider.error),
          backgroundColor: Colors.red,
        ),
      );
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

            Text(
              context.loc('welcome'),
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              context.loc('login_instruction'),
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 32),
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
                        _otpSent
                            ? context.loc('login')
                            : context.loc('send_otp'),
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  context.loc('no_account'),
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
                GestureDetector(
                  onTap: widget.onNavigateToSignup,
                  child: Text(
                    context.loc('sign_up'),
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
