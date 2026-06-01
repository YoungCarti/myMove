import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../services/payment_service.dart';
import 'payment_method_bottom_sheet.dart';

class ExtendParkingScreen extends StatefulWidget {
  final String bookingId;
  final DateTime currentEndDateTime;
  final double hourlyRate;

  const ExtendParkingScreen({
    super.key,
    required this.bookingId,
    required this.currentEndDateTime,
    this.hourlyRate = 10.0,
  });

  @override
  State<ExtendParkingScreen> createState() => _ExtendParkingScreenState();
}

class _ExtendParkingScreenState extends State<ExtendParkingScreen> {
  bool _isSaving = false;
  PaymentCard? _selectedCard;
  bool _isLoadingCards = true;
  double _extendHours = 1.0;

  @override
  void initState() {
    super.initState();
    _loadDefaultCard();
  }

  Future<void> _loadDefaultCard() async {
    final cards = await PaymentService.getCards();
    if (mounted) {
      setState(() {
        if (cards.isNotEmpty) {
          _selectedCard = cards.first;
        }
        _isLoadingCards = false;
      });
    }
  }

  Future<void> _confirmPayment() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final newEndDateTime = widget.currentEndDateTime.add(Duration(minutes: (_extendHours * 60).toInt()));
      final amount = _extendHours * widget.hourlyRate;
      final taxes = amount * 0.02;
      final totalPaidIncrease = amount + taxes;
      final extendMinutes = (_extendHours * 60).toInt();

      await FirebaseFunctions.instance.httpsCallable('extendParking').call({
        'bookingId': widget.bookingId,
        'extendMinutes': extendMinutes,
        'amount': amount,
        'totalPaidIncrease': totalPaidIncrease,
      });

      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Parking extended successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.pop(context, newEndDateTime);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        
        String errorMessage = e.toString().replaceAll('Exception: ', '');
        if (e is FirebaseFunctionsException) {
          errorMessage = e.message ?? 'An unknown error occurred.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error extending parking: $errorMessage'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double amount = _extendHours * widget.hourlyRate;
    double taxes = amount * 0.02; // 2% tax
    double total = amount + taxes;

    String formatHours(double hours) {
      if (hours == hours.toInt()) {
        return '${hours.toInt()} hour${hours == 1.0 ? '' : 's'}';
      } else {
        int hrs = hours.toInt();
        int mins = ((hours - hrs) * 60).round();
        if (hrs == 0) {
          return '$mins mins';
        }
        return '$hrs hr $mins mins';
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Extend Parking Time',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Extend Duration',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Column(
                  children: [
                    Text(
                      formatHours(_extendHours),
                      style: const TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: Colors.blueAccent,
                        inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
                        thumbColor: Colors.white,
                        trackHeight: 4.0,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12.0),
                        overlayColor: Colors.blueAccent.withValues(alpha: 0.2),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 24.0),
                      ),
                      child: Slider(
                        value: _extendHours,
                        min: 0.5,
                        max: 24.0,
                        divisions: 47, // 30-min increments
                        onChanged: (value) {
                          setState(() {
                            _extendHours = value;
                          });
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '30 mins',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '24 hours',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              const Text(
                'Choose Payment Method',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: _isLoadingCards
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: CircularProgressIndicator(color: Colors.blueAccent),
                        ),
                      )
                    : Row(
                        children: [
                          _selectedCard != null && _selectedCard!.brand.toLowerCase().contains('visa')
                              ? SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: Center(child: SvgPicture.asset('assets/icons/visa.svg', width: 32, height: 24, fit: BoxFit.contain)),
                                )
                              : _selectedCard != null && _selectedCard!.brand.toLowerCase().contains('mastercard')
                                  ? SizedBox(
                                      width: 40,
                                      height: 40,
                                      child: Center(child: SvgPicture.asset('assets/icons/mastercard.svg', width: 32, height: 24, fit: BoxFit.contain)),
                                    )
                                  : Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.blueAccent.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.credit_card, color: Colors.blueAccent),
                                    ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              _selectedCard != null
                                  ? '${_selectedCard!.brand} •••• ${_selectedCard!.last4}'
                                  : 'Set up your payment method',
                              style: TextStyle(
                                color: _selectedCard != null ? Colors.white : Colors.white70,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              final selectedCard = await PaymentMethodBottomSheet.show(context, _selectedCard);
                              if (selectedCard != null) {
                                setState(() {
                                  _selectedCard = selectedCard;
                                });
                              }
                            },
                            child: Text(
                              _selectedCard != null ? 'Change' : 'Add',
                              style: const TextStyle(
                                color: Colors.blueAccent,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
              
              const SizedBox(height: 24),
              
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow('Amount', 'RM${amount.toStringAsFixed(2)}', isBold: true),
                    _buildSummaryRow('Taxes & Fees', 'RM${taxes.toStringAsFixed(2)}', isBold: true),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Divider(color: Colors.white24, height: 1),
                    ),
                    _buildSummaryRow('Total', 'RM${total.toStringAsFixed(2)}', isBold: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_isSaving || _selectedCard == null || _isLoadingCards) ? null : _confirmPayment,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                backgroundColor: Colors.blueAccent,
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.1),
                disabledForegroundColor: Colors.white.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 4,
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Confirm Payment',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
