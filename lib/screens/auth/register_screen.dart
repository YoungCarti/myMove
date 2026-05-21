import 'package:flutter/material.dart';
import 'set_password_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

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
    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
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
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ─── Background image ─────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenHeight * 0.38,
            child: Image.network(
              'https://images.unsplash.com/photo-1542282088-fe8426682b8f?auto=format&fit=crop&w=800&q=80',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFE8D5F5), Color(0xFFD4E8FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),

          // ─── Back button ─────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // ─── Step dots ────────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 18,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [_dot(active: true), _dot(active: false)],
            ),
          ),

          // ─── White card ───────────────────────────────────────────────
          Positioned(
            top: screenHeight * 0.32,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  24, 32, 24,
                  32 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CREATE ACCOUNT',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                        letterSpacing: -0.5,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Let\'s get you started.\nFill in your details below.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF8E8E93),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Full Name
                    _label('Full Name'),
                    const SizedBox(height: 6),
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

                    // Email
                    _label('Email'),
                    const SizedBox(height: 6),
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

                    const SizedBox(height: 36),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _onContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Continue',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: RichText(
                          text: const TextSpan(
                            text: 'Already have an account? ',
                            style: TextStyle(
                                fontSize: 14, color: Color(0xFF8E8E93)),
                            children: [
                              TextSpan(
                                text: 'Sign In',
                                style: TextStyle(
                                  color: Colors.black,
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
          ),
        ],
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

  Widget _errorText(String? error) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      child: error != null
          ? Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      size: 14, color: Color(0xFFFF3B30)),
                  const SizedBox(width: 5),
                  Text(
                    error,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFFF3B30),
                    ),
                  ),
                ],
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
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: hasError ? const Color(0xFFFF3B30) : const Color(0xFFDDDDE3),
            width: 1.5,
          ),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: hasError ? const Color(0xFFFF3B30) : Colors.black,
            width: 2,
          ),
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
        color: active ? Colors.white : Colors.white54,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}