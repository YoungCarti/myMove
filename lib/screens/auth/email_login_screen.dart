import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../../providers/auth_provider.dart';
import 'forgot_password_screen.dart';

class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  String? _emailError;
  String? _passwordError;
  String? _generalError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    String? emailErr;
    String? passwordErr;

    if (email.isEmpty) {
      emailErr = 'Please enter your email address.';
    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      emailErr = 'That doesn\'t look like a valid email.';
    }

    if (password.isEmpty) {
      passwordErr = 'Please enter your password.';
    } else if (password.length < 6) {
      passwordErr = 'Password must be at least 6 characters.';
    }

    setState(() {
      _emailError = emailErr;
      _passwordError = passwordErr;
      _generalError = null;
    });

    if (emailErr != null || passwordErr != null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.signIn(email, password);
      if (success && mounted) {
        Navigator.of(context).pop();
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _generalError = e.message ?? 'Authentication failed.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _generalError = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Deep premium black matching reference
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ─── Header Navigation Row ───
                        Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
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
                        ),

                        const Spacer(flex: 3), // Generous space before logo to center it vertically

                        // ─── Logo & Brand Name ───
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF3B82F6), // Vibrant Blue
                                      Color(0xFF10B981), // Emerald Green
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.local_parking_rounded,
                                  size: 44,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'myMove',
                                style: TextStyle(
                                  fontFamily: 'Cattalague',
                                  fontSize: 28,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Spacer(flex: 4), // Space between logo and inputs

                        // ─── Email Field ───
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (_) {
                            if (_emailError != null) {
                              setState(() => _emailError = null);
                            }
                          },
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFF1E1E1E),
                            hintText: 'Username, email or mobile number',
                            hintStyle: const TextStyle(
                              color: Color(0xFF757575),
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF2E3033), width: 1.0),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF2E3033), width: 1.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.0),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                        ),
                        _errorText(_emailError),

                        const SizedBox(height: 12),

                        // ─── Password Field ───
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          onChanged: (_) {
                            if (_passwordError != null || _generalError != null) {
                              setState(() {
                                _passwordError = null;
                                _generalError = null;
                              });
                            }
                          },
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFF1E1E1E),
                            hintText: 'Password',
                            hintStyle: const TextStyle(
                              color: Color(0xFF757575),
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                            ),
                            suffixIcon: GestureDetector(
                              onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                              child: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: const Color(0xFF757575),
                                size: 20,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF2E3033), width: 1.0),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF2E3033), width: 1.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.0),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                          onSubmitted: (_) => _onLogin(),
                        ),
                        _errorText(_passwordError),
                        _errorText(_generalError),

                        const SizedBox(height: 16),

                        // ─── Login Button ───
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _onLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0064E0), // Vibrant Blue
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              disabledBackgroundColor: const Color(0xFF0064E0).withValues(alpha: 0.4),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.0,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Log in',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ─── Forgot Password Link ───
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const ForgotPasswordScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'Forgot password?',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const Spacer(flex: 5), // Dynamic spacer to push register to the very bottom

                        // ─── Register Outline Button ───
                        OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pushNamed('/register');
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0064E0),
                            side: const BorderSide(color: Color(0xFF0064E0), width: 1.2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                          child: const Text(
                            'Create new account',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _errorText(String? error) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      child: error != null
          ? Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      size: 14, color: Color(0xFFEF4444)),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      error,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
