import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AddCardBottomSheet extends StatefulWidget {
  const AddCardBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddCardBottomSheet(),
    );
  }

  @override
  State<AddCardBottomSheet> createState() => _AddCardBottomSheetState();
}

class _AddCardBottomSheetState extends State<AddCardBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvcController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvcController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get the keyboard height to adjust padding
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF2C2C2E), // Dark grey elevated background
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: bottomPadding > 0 ? bottomPadding + 20 : 40,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Close button
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(
                  Icons.close,
                  color: Colors.white70,
                  size: 24,
                ),
              ),
              const SizedBox(height: 20),
              
              // Title
              const Text(
                'Add a card',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              
              // Card Information Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Card information',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.camera_alt_outlined,
                        color: Color(0xFF0A84FF),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Scan card',
                        style: TextStyle(
                          color: Color(0xFF0A84FF),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Card Input Form
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white24, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    // Card Number Row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _cardNumberController,
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                _CardNumberInputFormatter(),
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Required';
                                final digits = value.replaceAll(' ', '');
                                if (digits.length < 13 || digits.length > 19) return 'Invalid length';
                                return null;
                              },
                              decoration: const InputDecoration(
                                hintText: 'Card number',
                                hintStyle: TextStyle(color: Colors.white38, fontSize: 16),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                errorStyle: TextStyle(height: 0),
                                filled: false,
                                isDense: true,
                              ),
                            ),
                          ),
                          // Real Card Brand Icons
                          Row(
                            children: [
                              _buildSvgIcon('assets/icons/visa.svg'),
                              const SizedBox(width: 4),
                              _buildSvgIcon('assets/icons/mastercard.svg'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const Divider(color: Colors.white24, height: 1, thickness: 1),
                    
                    // Expiry and CVC Row
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // MM/YY
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: TextFormField(
                                controller: _expiryController,
                                style: const TextStyle(color: Colors.white, fontSize: 16),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  _ExpiryDateInputFormatter(),
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Required';
                                  final text = value.replaceAll('/', '');
                                  if (text.length != 4) return 'Invalid';
                                  final month = int.tryParse(text.substring(0, 2)) ?? 0;
                                  final year = int.tryParse(text.substring(2, 4)) ?? 0;
                                  if (month < 1 || month > 12) return 'Invalid';
                                  final now = DateTime.now();
                                  final currentYear = now.year % 100;
                                  final currentMonth = now.month;
                                  if (year < currentYear || (year == currentYear && month < currentMonth)) {
                                    return 'Expired';
                                  }
                                  return null;
                                },
                                decoration: const InputDecoration(
                                  hintText: 'MM / YY',
                                  hintStyle: TextStyle(color: Colors.white38, fontSize: 16),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  errorStyle: TextStyle(height: 0),
                                  filled: false,
                                  isDense: true,
                                ),
                              ),
                            ),
                          ),
                          const VerticalDivider(color: Colors.white24, width: 1, thickness: 1),
                          // CVC
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _cvcController,
                                      style: const TextStyle(color: Colors.white, fontSize: 16),
                                      keyboardType: TextInputType.number,
                                      obscureText: true,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(4),
                                      ],
                                      validator: (value) {
                                        if (value == null || value.isEmpty) return 'Required';
                                        if (!RegExp(r'^\d{3,4}$').hasMatch(value)) return 'Invalid';
                                        return null;
                                      },
                                      decoration: const InputDecoration(
                                        hintText: 'CVC',
                                        hintStyle: TextStyle(color: Colors.white38, fontSize: 16),
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        errorStyle: TextStyle(height: 0),
                                        filled: false,
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.only(top: 10.0),
                                    child: Icon(
                                      Icons.credit_card,
                                      color: Colors.white38,
                                      size: 24,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Billing Address Header
              const Text(
                'Billing address',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              
              // Country Selector
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white24, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Country or region',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Malaysia',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Disclaimer Text
              const Text(
                'By providing your card information, you allow myMove to charge your card for future payments in accordance with their terms.',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Continue Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : () async {
                    if (_formKey.currentState?.validate() ?? false) {
                      setState(() => _isSubmitting = true);
                      try {
                        // Simulate card addition
                        await Future.delayed(const Duration(seconds: 1));
                        if (!context.mounted) return;
                        Navigator.pop(context, true);
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Failed to add card')),
                        );
                      } finally {
                        if (mounted) {
                          setState(() => _isSubmitting = false);
                        }
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A84FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                    disabledBackgroundColor: const Color(0xFF0A84FF).withValues(alpha: 0.5),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Continue',
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

  Widget _buildSvgIcon(String assetPath) {
    return Container(
      width: 32,
      height: 20,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3), width: 0.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(1.5),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 1.0),
          child: SvgPicture.asset(
            assetPath,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class _CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var newText = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (newText.length > 19) newText = newText.substring(0, 19);
    var buffer = StringBuffer();
    for (int i = 0; i < newText.length; i++) {
      buffer.write(newText[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 4 == 0 && nonZeroIndex != newText.length) {
        buffer.write(' ');
      }
    }
    var string = buffer.toString();
    return TextEditingValue(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

class _ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var newText = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (newText.length > 4) newText = newText.substring(0, 4);
    var buffer = StringBuffer();
    for (int i = 0; i < newText.length; i++) {
      buffer.write(newText[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex == 2 && nonZeroIndex != newText.length) {
        buffer.write('/');
      }
    }
    var string = buffer.toString();
    return TextEditingValue(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}
