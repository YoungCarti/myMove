import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../../providers/auth_provider.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final List<FocusNode> _keyboardFocusNodes = List.generate(6, (_) => FocusNode());
  
  bool _isLoading = false;
  String? _errorText;
  
  Timer? _timer;
  int _secondsRemaining = 30;
  String _phoneNumber = '';
  String _verificationId = '';
  int? _resendToken;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    // Focus the first input field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _phoneNumber = args['phoneNumber'] ?? '';
      _verificationId = args['verificationId'] ?? '';
      _resendToken = args['resendToken'];
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    for (var node in _keyboardFocusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _secondsRemaining = 30;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        timer.cancel();
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  String get _otpCode {
    return _controllers.map((c) => c.text).join();
  }

  void _checkOtpCompletion() {
    final code = _otpCode;
    if (code.length == 6) {
      _handleVerifyOtp();
    } else {
      setState(() {
        _errorText = null;
      });
    }
  }

  Future<void> _handleVerifyOtp() async {
    final code = _otpCode;
    if (code.length != 6) return;

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.linkPhoneNumber(
        verificationId: _verificationId,
        smsCode: code,
        phoneNumber: _phoneNumber,
      );
      
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        // Return true to EnterMobileNumberScreen to signal success
        Navigator.of(context).pop(true);
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Mobile number verified and updated successfully.'),
            backgroundColor: Color(0xFF32D74B),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (e is FirebaseAuthException) {
            _errorText = e.message ?? 'Verification failed. Please try again.';
          } else {
            _errorText = e.toString().replaceAll('Exception:', '');
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleResendCode() async {
    for (var controller in _controllers) {
      controller.clear();
    }
    setState(() {
      _errorText = null;
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.verifyPhoneNumber(
        phoneNumber: _phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) {
          if (mounted) {
            setState(() => _isLoading = false);
            final messenger = ScaffoldMessenger.of(context);
            Navigator.of(context).pop(true);
            messenger.showSnackBar(
              const SnackBar(
                content: Text('Mobile number automatically verified and updated.'),
                backgroundColor: Color(0xFF32D74B),
              ),
            );
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _errorText = e.message ?? 'Verification failed. Please try again.';
            });
          }
        },
        codeSent: (String newVerificationId, int? newResendToken) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _verificationId = newVerificationId;
              _resendToken = newResendToken;
            });
            _startResendTimer();
            _focusNodes[0].requestFocus();
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Verification code resent to $_phoneNumber!'),
                backgroundColor: const Color(0xFF1E1E1E),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          if (mounted) {
            setState(() => _isLoading = false);
          }
        },
        forceResendingToken: _resendToken,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorText = e.toString().replaceAll('Exception:', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = _otpCode;
    final isOtpValid = code.length == 6;

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
                      'Verify your number',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                          height: 1.4,
                        ),
                        children: [
                          const TextSpan(text: "Enter the 6-digit verification code sent to "),
                          TextSpan(
                            text: _phoneNumber.isNotEmpty ? _phoneNumber : 'your number',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const TextSpan(text: "."),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),
                    
                    // 6-digit grid with individual focus controls and backspace listeners
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (index) {
                        return SizedBox(
                          width: 46,
                          height: 58,
                          child: KeyboardListener(
                            focusNode: _keyboardFocusNodes[index],
                            onKeyEvent: (KeyEvent event) {
                              if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
                                if (_controllers[index].text.isEmpty && index > 0) {
                                  _focusNodes[index - 1].requestFocus();
                                  _controllers[index - 1].clear();
                                  setState(() {});
                                }
                              }
                            },
                            child: TextField(
                              controller: _controllers[index],
                              focusNode: _focusNodes[index],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLength: 1,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: InputDecoration(
                                counterText: '',
                                filled: true,
                                fillColor: const Color(0xFF1E1E1E),
                                contentPadding: EdgeInsets.zero,
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
                              ),
                              onChanged: (value) {
                                setState(() {});
                                if (value.isNotEmpty) {
                                  if (index < 5) {
                                    _focusNodes[index + 1].requestFocus();
                                  } else {
                                    _focusNodes[index].unfocus();
                                  }
                                }
                                _checkOtpCompletion();
                              },
                            ),
                          ),
                        );
                      }),
                    ),
                    
                    if (_errorText != null) ...[
                      const SizedBox(height: 16),
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
                    ],
                    
                    const SizedBox(height: 32),
                    
                    // Resend and info section
                    Center(
                      child: Column(
                        children: [
                          if (_secondsRemaining > 0)
                            Text(
                              'Resend code in 0:${_secondsRemaining.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 14,
                              ),
                            )
                          else
                            TextButton(
                              onPressed: _handleResendCode,
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF3B82F6),
                                textStyle: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              child: const Text('Resend Verification Code'),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Full width premium verify button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: isOtpValid && !_isLoading ? _handleVerifyOtp : null,
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
                          'Verify & Save',
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
