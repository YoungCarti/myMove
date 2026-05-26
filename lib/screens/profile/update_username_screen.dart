import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class UpdateUsernameScreen extends StatefulWidget {
  const UpdateUsernameScreen({super.key});

  @override
  State<UpdateUsernameScreen> createState() => _UpdateUsernameScreenState();
}

class _UpdateUsernameScreenState extends State<UpdateUsernameScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = false;
  String? _errorText;
  
  Timer? _debounceTimer;
  bool _isChecking = false;
  bool? _isAvailable;

  @override
  void initState() {
    super.initState();
    // Pre-populate username if it exists
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.username.isNotEmpty) {
        _usernameController.text = authProvider.username;
        setState(() {
          _isAvailable = true;
        });
      }
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _usernameController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool _validateUsername(String username) {
    if (username.isEmpty) {
      setState(() => _errorText = 'Please enter a username.');
      return false;
    }
    if (username.length < 3) {
      setState(() => _errorText = 'Username must be at least 3 characters.');
      return false;
    }
    final validChars = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!validChars.hasMatch(username)) {
      setState(() => _errorText = 'Username can only contain letters, numbers, and underscores.');
      return false;
    }
    setState(() => _errorText = null);
    return true;
  }

  void _onUsernameChanged(String value) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer?.cancel();
    
    final cleaned = value.trim();
    if (cleaned.isEmpty) {
      setState(() {
        _isAvailable = null;
        _isChecking = false;
        _errorText = null;
      });
      return;
    }
    
    if (!_validateUsername(cleaned)) {
      setState(() {
        _isAvailable = null;
        _isChecking = false;
      });
      return;
    }

    setState(() {
      _isChecking = true;
      _isAvailable = null;
      _errorText = null;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      if (cleaned.isEmpty || !mounted) return;
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final available = await authProvider.isUsernameAvailable(cleaned);
        if (mounted) {
          setState(() {
            _isChecking = false;
            _isAvailable = available;
            if (!available) {
              _errorText = 'This username is already taken. Please choose another.';
            } else {
              _errorText = null;
            }
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isChecking = false;
            _isAvailable = null;
          });
        }
      }
    });
  }

  Future<void> _handleSave() async {
    final username = _usernameController.text.trim();
    if (!_validateUsername(username)) return;
    if (_isAvailable == false || _isChecking) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.updateUsername(username);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Username updated successfully.'),
            backgroundColor: Color(0xFF32D74B),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorText = e.toString().replaceAll('Exception:', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final username = _usernameController.text.trim();
    final isValid = username.length >= 3 && 
        RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username) && 
        _isAvailable == true && 
        !_isChecking;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Choose a username',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This is how other users can find and connect with you on myMove.',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Input box
                    TextField(
                      controller: _usernameController,
                      focusNode: _focusNode,
                      onChanged: _onUsernameChanged,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF1E1E1E),
                        prefixText: '@',
                        prefixStyle: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        suffixIcon: _isChecking
                            ? const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white30,
                                  ),
                                ),
                              )
                            : (_isAvailable == true
                                ? const Icon(Icons.check_circle_rounded, color: Color(0xFF32D74B), size: 20)
                                : (_isAvailable == false
                                    ? const Icon(Icons.cancel_rounded, color: Color(0xFFEF4444), size: 20)
                                    : null)),
                        hintText: 'username',
                        hintStyle: const TextStyle(
                          color: Color(0xFF757575),
                          fontSize: 16,
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
                      onSubmitted: (_) => _handleSave(),
                    ),
                    
                    if (_errorText != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.error_outline, size: 16, color: Color(0xFFEF4444)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _errorText!,
                              style: const TextStyle(
                                color: Color(0xFFEF4444),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else if (_isAvailable == true && _usernameController.text.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, size: 16, color: Color(0xFF32D74B)),
                          const SizedBox(width: 6),
                          const Expanded(
                            child: Text(
                              'Username is available!',
                              style: TextStyle(
                                color: Color(0xFF32D74B),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            // Full width premium white/light-grey bottom button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: isValid && !_isLoading ? _handleSave : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: Colors.white.withOpacity(0.3),
                    disabledForegroundColor: Colors.black38,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Text(
                          'Save Username',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.2,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
