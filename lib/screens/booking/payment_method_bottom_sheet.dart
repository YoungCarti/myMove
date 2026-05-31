import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../services/payment_service.dart';
import '../profile/add_card_bottom_sheet.dart';

class PaymentMethodBottomSheet extends StatefulWidget {
  final PaymentCard? selectedPaymentCard;

  const PaymentMethodBottomSheet({super.key, this.selectedPaymentCard});

  static Future<PaymentCard?> show(BuildContext context, PaymentCard? currentSelection) {
    return showModalBottomSheet<PaymentCard>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PaymentMethodBottomSheet(selectedPaymentCard: currentSelection),
    );
  }

  @override
  State<PaymentMethodBottomSheet> createState() => _PaymentMethodBottomSheetState();
}

class _PaymentMethodBottomSheetState extends State<PaymentMethodBottomSheet> {
  List<PaymentCard> _cards = [];
  PaymentCard? _selectedCard;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedCard = widget.selectedPaymentCard;
    _loadCards();
  }

  Future<void> _loadCards() async {
    final cards = await PaymentService.getCards();
    setState(() {
      _cards = cards;
      _isLoading = false;
      // If a card was selected before, ensure it exists in the list
      if (_selectedCard != null && !_cards.any((c) => c.id == _selectedCard!.id)) {
        _selectedCard = null;
      }
      // Select the first card by default if none selected
      if (_selectedCard == null && _cards.isNotEmpty) {
        _selectedCard = _cards.first;
      }
    });
  }

  Future<void> _onAddNewCard() async {
    final bool? added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddCardBottomSheet(),
    );

    if (added == true) {
      setState(() {
        _isLoading = true;
      });
      await _loadCards();
      // Select the newly added card (usually the last one added)
      if (_cards.isNotEmpty) {
        setState(() {
          _selectedCard = _cards.last;
        });
      }
    }
  }

  Widget _buildSvgIcon(String assetPath) {
    return SvgPicture.asset(
      assetPath,
      width: 32,
      height: 20,
      fit: BoxFit.contain,
    );
  }

  Widget _buildCardOption(PaymentCard card) {
    final isSelected = _selectedCard?.id == card.id;

    Widget cardIconWidget;
    if (card.brand.toLowerCase().contains('visa')) {
      cardIconWidget = _buildSvgIcon('assets/icons/visa.svg');
    } else if (card.brand.toLowerCase().contains('mastercard')) {
      cardIconWidget = _buildSvgIcon('assets/icons/mastercard.svg');
    } else if (card.brand.toLowerCase().contains('stripe')) {
      cardIconWidget = const Icon(Icons.payments_outlined, color: Colors.white70);
    } else {
      cardIconWidget = const Icon(Icons.credit_card, color: Colors.white70);
    }

    // Since we don't have SVGs for card brands yet, we'll just use text or simple icons
    final brandText = card.brand == 'Stripe' ? 'Stripe' : '${card.brand} •••• ${card.last4}';

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCard = card;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent.withValues(alpha: 0.1) : const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blueAccent : Colors.white.withValues(alpha: 0.05),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            cardIconWidget,
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                brandText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.blueAccent : Colors.white38,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.blueAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Method',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              // List of cards
              ..._cards.map(_buildCardOption),
              
              // Add New Card Button
              GestureDetector(
                onTap: _onAddNewCard,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.5)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_outline, color: Colors.blueAccent, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Add New Card',
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),
            
            // Confirm Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _selectedCard == null
                    ? null
                    : () {
                        Navigator.pop(context, _selectedCard);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  disabledBackgroundColor: Colors.white.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Confirm',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
