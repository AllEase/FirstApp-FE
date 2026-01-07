import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _SignupScreenState extends State<SignupScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  // Animation Controllers
  late AnimationController _mainController;
  late AnimationController _shakeController;

  // Animation Definitions
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<Offset> _shakeAnimation;

  // Timer & State
  Timer? _timer;
  int _start = 30;
  bool _canResend = false;
  bool _otpSent = false;
  bool _loading = false;

  String get _enteredOtp => _otpControllers.map((c) => c.text).join();

  @override
  void initState() {
    super.initState();

    // 1. Entrance Animation (Staggered)
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.elasticOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _mainController,
            curve: const Interval(0.1, 1.0, curve: Curves.easeOutQuart),
          ),
        );

    // 2. Error Shake Animation
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _shakeAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.02, 0),
    ).chain(CurveTween(curve: Curves.elasticIn)).animate(_shakeController);

    _mainController.forward();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _start = 30;
      _canResend = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        setState(() {
          timer.cancel();
          _canResend = true;
        });
      } else {
        setState(() => _start--);
      }
    });
  }

  void _triggerError() {
    _shakeController.forward(from: 0.0);
    HapticFeedback.lightImpact();
  }

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
    setState(() => _loading = false);

    if (success) {
      if (!_otpSent) {
        setState(() => _otpSent = true);
        _startTimer();
      } else {
        widget.onSignup(userProvider.user!.userId.toString());
      }
    } else {
      _triggerError();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userProvider.error),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _shakeController.dispose();
    _timer?.cancel();
    _phoneController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    for (var c in _otpControllers) c.dispose();
    for (var f in _otpFocusNodes) f.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Provider.of<UserProvider>(context).primaryColor;

    return Center(
      child: SlideTransition(
        position: _shakeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.12),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildIconHeader(primaryColor),
                      const SizedBox(height: 24),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        child: !_otpSent
                            ? _buildDetailsView(primaryColor)
                            : _buildOtpView(primaryColor),
                      ),
                      const SizedBox(height: 32),
                      _buildSubmitButton(primaryColor),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconHeader(Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        shape: BoxShape.circle,
      ),
      child: Icon(
        _otpSent ? Icons.verified_user_rounded : Icons.person_add_rounded,
        size: 40,
        color: color,
      ),
    );
  }

  Widget _buildDetailsView(Color color) {
    return Column(
      key: const ValueKey('details'),
      children: [
        Text(
          context.loc("create_account"),
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.loc('signup_started'),
          style: TextStyle(color: Colors.grey.shade500),
        ),
        const SizedBox(height: 24),
        CustomTextField(
          controller: _phoneController,
          label: context.loc('phone_number'),
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _firstNameController,
                label: context.loc('first_name'),
                icon: Icons.person_outline,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextField(
                controller: _lastNameController,
                label: context.loc('last_name'),
                icon: Icons.person_outline,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOtpView(Color color) {
    return Column(
      key: const ValueKey('otp'),
      children: [
        Text(
          context.loc('enter_otp'),
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "${context.loc('sent_to')} +91 ${_phoneController.text}",
          style: TextStyle(color: Colors.grey.shade500),
        ),
        const SizedBox(height: 24),
        _buildOtpFields(color),
        const SizedBox(height: 20),
        _canResend
            ? TextButton(
                onPressed: _handleAction,
                child: Text(
                  context.loc('resend_otp'),
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              )
            : Text(
                "${context.loc('resend_in')} 00:${_start.toString().padLeft(2, '0')}",
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
        TextButton(
          onPressed: () => setState(() => _otpSent = false),
          child: Text(
            context.loc('change_number'),
            style: TextStyle(color: color.withOpacity(0.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpFields(Color color) {
    return Row(
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
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            decoration: InputDecoration(
              counterText: '',
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: color, width: 2.5),
              ),
            ),
            onChanged: (value) {
              if (value.isNotEmpty && index < 5)
                _otpFocusNodes[index + 1].requestFocus();
              if (value.isEmpty && index > 0)
                _otpFocusNodes[index - 1].requestFocus();
            },
          ),
        );
      }),
    );
  }

  Widget _buildSubmitButton(Color color) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: _loading ? null : _handleAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: _loading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    _otpSent ? context.loc('sign_up') : context.loc('send_otp'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              context.loc('already_have_account'),
              style: TextStyle(color: Colors.grey.shade600),
            ),
            TextButton(
              onPressed: widget.onNavigateToLogin,
              child: Text(
                context.loc('login'),
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
