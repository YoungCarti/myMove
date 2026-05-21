import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  // Track which step we're on (0 = name+email, 1 = password)
  int _step = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _onContinue() {
    if (_step == 0) {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      if (name.isEmpty) return;
      if (email.isEmpty || !email.contains('@')) return;
      setState(() => _step = 1);
    } else {
      final password = _passwordController.text;
      final confirm = _confirmController.text;
      if (password.length < 6) return;
      if (password != confirm) return;

      setState(() => _isLoading = true);
      // TODO: Hook up Firebase Auth createUserWithEmailAndPassword
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) setState(() => _isLoading = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ─── Background image ─────────────────────────────────────────────
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

          // ─── Back button ──────────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: GestureDetector(
              onTap: () {
                if (_step == 1) {
                  setState(() => _step = 0);
                } else {
                  Navigator.of(context).pop();
                }
              },
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

          // ─── Step indicator dots ─────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 18,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(2, (i) {
                final active = i == _step;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active ? Colors.white : Colors.white54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),

          // ─── White content card ───────────────────────────────────────────
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
                  24,
                  32,
                  24,
                  32 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Form(
                  key: _formKey,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    transitionBuilder: (child, animation) => SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.05, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: FadeTransition(opacity: animation, child: child),
                    ),
                    child: _step == 0
                        ? _buildStep0(key: const ValueKey('step0'))
                        : _buildStep1(key: const ValueKey('step1')),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step 0: Name + Email ──────────────────────────────────────────────────
  Widget _buildStep0({Key? key}) {
    return Column(
      key: key,
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

        // Full name
        _label('Full Name'),
        const SizedBox(height: 6),
        _field(
          controller: _nameController,
          hint: 'John Smith',
          keyboardType: TextInputType.name,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),

        const SizedBox(height: 24),

        // Email
        _label('Email'),
        const SizedBox(height: 6),
        _field(
          controller: _emailController,
          hint: 'you@example.com',
          keyboardType: TextInputType.emailAddress,
          onSubmitted: (_) => _onContinue(),
        ),

        const SizedBox(height: 36),

        _continueButton(label: 'Continue'),

        const SizedBox(height: 20),

        Center(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: RichText(
              text: const TextSpan(
                text: 'Already have an account? ',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF8E8E93),
                ),
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
    );
  }

  // ─── Step 1: Password + Confirm ────────────────────────────────────────────
  Widget _buildStep1({Key? key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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

        Text(
          'Creating account for\n${_emailController.text.trim()}',
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF8E8E93),
            height: 1.45,
          ),
        ),

        const SizedBox(height: 36),

        // Password
        _label('Password'),
        const SizedBox(height: 6),
        _passwordField(
          controller: _passwordController,
          hint: 'At least 6 characters',
          obscure: _obscurePassword,
          autofocus: true,
          onToggle: () =>
              setState(() => _obscurePassword = !_obscurePassword),
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
          onSubmitted: (_) => _onContinue(),
        ),

        const SizedBox(height: 12),

        // Password hint
        const Text(
          'Must be at least 6 characters.',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF8E8E93),
          ),
        ),

        const SizedBox(height: 36),

        _continueButton(label: 'Create Account'),
      ],
    );
  }

  // ─── Shared helpers ─────────────────────────────────────────────────────────

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        color: Color(0xFF8E8E93),
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool autofocus = false,
    TextCapitalization textCapitalization = TextCapitalization.none,
    void Function(String)? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      autofocus: autofocus,
      textCapitalization: textCapitalization,
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
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
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

  Widget _continueButton({required String label}) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _onContinue,
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
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}