import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../../providers/auth_provider.dart';
import 'otp_verification_screen.dart';

class SetPasswordScreen extends StatefulWidget {
  final String fullName;
  final String email;

  const SetPasswordScreen({
    super.key,
    required this.fullName,
    required this.email,
  });

  @override
  State<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends State<SetPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _showSuccess = false;

  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _onCreateAccount() async {
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    setState(() => _errorMessage = null);

    if (password.length < 6) {
      setState(
          () => _errorMessage = 'Password must be at least 6 characters.');
      return;
    }
    if (password != confirm) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }

    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    // Slide transition to OTP verification screen
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => OtpVerificationScreen(
          fullName: widget.fullName,
          email: widget.email,
          password: password,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showSuccess) {
      return Scaffold(
        backgroundColor: const Color(0xFF34C759), // Premium iOS style green
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 80,
                  color: Color(0xFF34C759),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Created Account Successfully!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Preparing your dashboard...',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 20, 24, 32 + bottomInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Header Navigation Row ─────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.centerLeft,
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      _dot(active: false),
                      _dot(active: true),
                    ],
                  ),
                  const SizedBox(width: 44), // Balances back button for perfect centering
                ],
              ),
              const SizedBox(height: 30),

              // ─── Content ───
              const Text(
                'SET PASSWORD',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
              ),

              const SizedBox(height: 10),

              // Show who we're creating the account for
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF8E8E93),
                    height: 1.45,
                  ),
                  children: [
                    const TextSpan(text: 'Creating account for\n'),
                    TextSpan(
                      text: widget.email,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 42),

              // Password
              _label('Password'),
              const SizedBox(height: 6),
              _passwordField(
                controller: _passwordController,
                hint: 'At least 6 characters',
                obscure: _obscurePassword,
                autofocus: true,
                onToggle: () => setState(
                    () => _obscurePassword = !_obscurePassword),
              ),

              const SizedBox(height: 24),

              // Confirm password
              _label('Confirm Password'),
              const SizedBox(height: 6),
              _passwordField(
                controller: _confirmController,
                hint: 'Repeat your password',
                obscure: _obscureConfirm,
                onToggle: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                onSubmitted: (_) => _onCreateAccount(),
              ),

              // Error message
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFFF3B30),
                  ),
                ),
              ],

              const SizedBox(height: 12),

              const Text(
                'Must be at least 6 characters.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF8E8E93),
                ),
              ),

              const SizedBox(height: 48),

              // Create Account button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _onCreateAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    disabledBackgroundColor: Colors.black38,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF8E8E93),
          fontWeight: FontWeight.w500,
        ),
      );

  Widget _passwordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    bool autofocus = false,
    void Function(String)? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      autofocus: autofocus,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0xFFBDBDC7),
          fontWeight: FontWeight.w400,
        ),
        suffixIcon: GestureDetector(
          onTap: onToggle,
          child: Icon(
            obscure
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: Colors.black45,
            size: 20,
          ),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFDDDDE3), width: 1.5),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.black, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
      ),
      onSubmitted: onSubmitted,
    );
  }

  Widget _dot({required bool active}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: active ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? Colors.black : const Color(0xFFDDDDE3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
