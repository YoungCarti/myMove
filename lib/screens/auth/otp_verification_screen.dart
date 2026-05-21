import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../../providers/auth_provider.dart';
import '../../services/email_service.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String fullName;
  final String email;
  final String password;

  const OtpVerificationScreen({
    super.key,
    required this.fullName,
    required this.email,
    required this.password,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  String? _generatedOtp;
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  
  bool _isLoading = false;
  bool _showSuccess = false;
  String? _errorMessage;
  bool _isSendDisabled = false;

  DateTime? _otpIssuedAt;
  static const Duration _otpExpiry = Duration(minutes: 15);

  // Resend Timer
  int _timerSeconds = 0;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _sendAndStartTimer();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _timerSeconds = 59;
    });
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds == 0) {
        timer.cancel();
      } else {
        setState(() {
          _timerSeconds--;
        });
      }
    });
  }

  void _clearResendTimer() {
    _resendTimer?.cancel();
    _resendTimer = null;
    if (mounted) {
      setState(() {
        _timerSeconds = 0;
      });
    }
  }

  Future<void> _sendAndStartTimer() async {
    final success = await _generateAndSendOtp();
    if (success) {
      _startResendTimer();
    } else {
      _clearResendTimer();
    }
  }

  Future<bool> _generateAndSendOtp() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    // Generate a secure 6-digit random code
    Random random;
    try {
      random = Random.secure();
    } on UnsupportedError catch (e) {
      print('Security Error: Cryptographically secure random number generator is not supported on this device: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Secure registration is not supported on this device due to a missing secure generator.';
          _isSendDisabled = true;
          _isLoading = false;
        });
      }
      return false;
    }

    final localIssuedAt = DateTime.now();
    final otpVal = 100000 + random.nextInt(900000);
    final localOtp = otpVal.toString();

    bool emailSentSuccessfully = false;

    // Call the primary sender first: EmailService.sendOtpViaEmailJS
    try {
      emailSentSuccessfully = await EmailService.sendOtpViaEmailJS(
        email: widget.email,
        fullName: widget.fullName,
        otp: localOtp,
      );
    } catch (e) {
      print('Primary sender (EmailJS) error: $e');
    }

    // If primary fails, call fallback sender: EmailService.sendOtpViaFirestore
    if (!emailSentSuccessfully) {
      try {
        emailSentSuccessfully = await EmailService.sendOtpViaFirestore(
          widget.email,
          widget.fullName,
          localOtp,
        );
      } catch (e) {
        print('Fallback sender (Firestore) error: $e');
      }
    }

    if (!mounted) return false;

    setState(() {
      _isLoading = false;
    });

    if (emailSentSuccessfully) {
      setState(() {
        _generatedOtp = localOtp;
        _otpIssuedAt = localIssuedAt;
        _errorMessage = null;
      });

      // Reset controllers only when successfully sent
      for (var controller in _controllers) {
        controller.clear();
      }
      _focusNodes[0].requestFocus();

      // Show a beautiful in-app notification confirming the email was sent
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.mark_email_read_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text(
                'Verification code sent to your email!',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1C1C1E),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return true;
    } else {
      // Show an error SnackBar and keep previous OTP state intact
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.error_outline_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Failed to send verification code. Please check your internet connection.',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFFF3B30),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return false;
    }
  }

  void _onVerify() async {
    setState(() => _errorMessage = null);

    if (_otpIssuedAt == null || DateTime.now().difference(_otpIssuedAt!) > _otpExpiry) {
      setState(() {
        _errorMessage = 'The verification code has expired. Please request a new one.';
        _isLoading = false;
        _showSuccess = false;
      });
      return;
    }

    // Get the entered OTP
    final enteredOtp = _controllers.map((c) => c.text).join();

    if (enteredOtp.length < 6) {
      setState(() => _errorMessage = 'Please enter the complete 6-digit code.');
      return;
    }

    if (_generatedOtp == null || enteredOtp != _generatedOtp) {
      setState(() => _errorMessage = 'Incorrect verification code. Please try again.');
      return;
    }

    // OTP matches! Register the user with Firebase Authentication
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.register(
        widget.email,
        widget.password,
        widget.fullName,
      );

      if (success && mounted) {
        setState(() {
          _showSuccess = true;
          _isLoading = false;
        });

        // Show success splash for 1.8 seconds
        await Future.delayed(const Duration(milliseconds: 1800));

        if (mounted) {
          // Navigate to homepage
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message ?? 'Registration failed.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
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
    if (_showSuccess) {
      return Scaffold(
        backgroundColor: const Color(0xFF34C759),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 64,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Success!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Created account successfully',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xE6FFFFFF),
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
              // Back Navigation Row
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
              const SizedBox(height: 30),

              // Title
              const Text(
                'VERIFY EMAIL',
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
                'We have sent a 6-digit verification code to\n${widget.email}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF8E8E93),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 42),

              // Digit inputs
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 46,
                    height: 56,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: const Color(0xFFF2F2F7),
                        contentPadding: EdgeInsets.zero,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF2196F3),
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          if (index < 5) {
                            _focusNodes[index + 1].requestFocus();
                          } else {
                            _focusNodes[index].unfocus();
                            _onVerify(); // Auto trigger verify when last digit is filled
                          }
                        } else {
                          if (index > 0) {
                            _focusNodes[index - 1].requestFocus();
                          }
                        }
                      },
                    ),
                  );
                }),
              ),

              // Error display
              _errorText(_errorMessage),

              const SizedBox(height: 40),

              // Verify button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: (_isLoading || _isSendDisabled) ? null : _onVerify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Verify & Create Account',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // Resend Option
              Center(
                child: _isSendDisabled
                    ? const SizedBox.shrink()
                    : _timerSeconds > 0
                        ? Text(
                            'Resend code in ${_timerSeconds}s',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF8E8E93),
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        : GestureDetector(
                            onTap: () {
                              _sendAndStartTimer();
                            },
                            child: const Text(
                              'Resend Verification Code',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF2196F3),
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

  Widget _errorText(String? error) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      child: error != null
          ? Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, size: 16, color: Color(0xFFFF3B30)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      error,
                      style: const TextStyle(
                        color: Color(0xFFFF3B30),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
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
