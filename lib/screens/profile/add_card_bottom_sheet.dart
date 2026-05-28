import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AddCardBottomSheet extends StatelessWidget {
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
                  Text(
                    'Scan card',
                    style: TextStyle(
                      color: const Color(0xFF0A84FF),
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
                        child: TextField(
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: 'Card number',
                            hintStyle: TextStyle(color: Colors.white38, fontSize: 16),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false, // Ensure no white background
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
                    children: [
                      // MM/YY
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: TextField(
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                            keyboardType: TextInputType.datetime,
                            decoration: const InputDecoration(
                              hintText: 'MM / YY',
                              hintStyle: TextStyle(color: Colors.white38, fontSize: 16),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
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
                            children: [
                              Expanded(
                                child: TextField(
                                  style: const TextStyle(color: Colors.white, fontSize: 16),
                                  keyboardType: TextInputType.number,
                                  obscureText: true,
                                  decoration: const InputDecoration(
                                    hintText: 'CVC',
                                    hintStyle: TextStyle(color: Colors.white38, fontSize: 16),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    filled: false,
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.credit_card,
                                color: Colors.white38,
                                size: 24,
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
                    Text(
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
                const Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white,
                  size: 24,
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
              onPressed: () {
                // TODO: Handle continue
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A84FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
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
    );
  }

  Widget _buildSvgIcon(String assetPath) {
    return Container(
      width: 32,
      height: 20,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: Colors.grey.withOpacity(0.3), width: 0.5),
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
