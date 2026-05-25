import 'package:flutter/material.dart';
import 'set_password_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  String? _nameError;
  String? _emailError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  bool _validate() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    String? nameErr;
    String? emailErr;

    if (name.isEmpty) {
      nameErr = 'Please enter your full name.';
    }

    if (email.isEmpty) {
      emailErr = 'Please enter your email address.';
    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
      emailErr = 'Please enter a valid email address.';
    }

    setState(() {
      _nameError = nameErr;
      _emailError = emailErr;
    });

    return nameErr == null && emailErr == null;
  }

  void _onContinue() {
    if (!_validate()) return;

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, _) => SetPasswordScreen(
          fullName: _nameController.text.trim(),
          email: _emailController.text.trim(),
        ),
        transitionsBuilder: (context, animation, _, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Sleek pitch black matching login
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
                        Icons.arrow_back,
                        size: 26,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      _dot(active: true),
                      _dot(active: false),
                    ],
                  ),
                  const SizedBox(width: 44), // Balances back button for perfect centering
                ],
              ),
              const SizedBox(height: 30),

              // ─── Content ───
              const Text(
                'CREATE ACCOUNT',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Let\'s get you started.\nFill in your details below.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF757575),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 42),

              // Full Name Label
              _label('Full Name'),
              const SizedBox(height: 8),
              _textField(
                controller: _nameController,
                hint: 'John Smith',
                keyboardType: TextInputType.name,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                hasError: _nameError != null,
                onChanged: (_) {
                  if (_nameError != null) {
                    setState(() => _nameError = null);
                  }
                },
              ),
              _errorText(_nameError),

              const SizedBox(height: 24),

              // Email Label
              _label('Email'),
              const SizedBox(height: 8),
              _textField(
                controller: _emailController,
                hint: 'you@example.com',
                keyboardType: TextInputType.emailAddress,
                hasError: _emailError != null,
                onChanged: (_) {
                  if (_emailError != null) {
                    setState(() => _emailError = null);
                  }
                },
                onSubmitted: (_) => _onContinue(),
              ),
              _errorText(_emailError),

              const SizedBox(height: 48),

              // Continue Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0064E0), // Vibrant Blue
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Center(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: RichText(
                    text: const TextSpan(
                      text: 'Already have an account? ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF757575),
                      ),
                      children: [
                        TextSpan(
                          text: 'Sign In',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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
          color: Color(0xFF757575),
          fontWeight: FontWeight.w500,
        ),
      );

  Widget _errorText(String? error) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      child: error != null
          ? Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(
                error,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFEF4444),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool autofocus = false,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool hasError = false,
    void Function(String)? onChanged,
    void Function(String)? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      autofocus: autofocus,
      textCapitalization: textCapitalization,
      onChanged: onChanged,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0xFF757575),
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: hasError ? const Color(0xFFEF4444) : const Color(0xFF2E3033),
            width: 1.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: hasError ? const Color(0xFFEF4444) : const Color(0xFF2E3033),
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: hasError ? const Color(0xFFEF4444) : const Color(0xFF3B82F6),
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
        color: active ? Colors.white : const Color(0xFF2E3033),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}