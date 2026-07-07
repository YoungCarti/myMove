import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'booking_success_screen.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

class BookingSummaryScreen extends StatefulWidget {
  final String bookingId;
  final String locationName;
  final String locationAddress;
  final String spotId;
  final String vehicleMake;
  final String vehiclePlate;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final double price;

  const BookingSummaryScreen({
    super.key,
    required this.bookingId,
    required this.locationName,
    required this.locationAddress,
    required this.spotId,
    required this.vehicleMake,
    required this.vehiclePlate,
    required this.startDateTime,
    required this.endDateTime,
    required this.price,
  });

  @override
  State<BookingSummaryScreen> createState() => _BookingSummaryScreenState();
}

class _BookingSummaryScreenState extends State<BookingSummaryScreen> {
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _confirmBooking() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final totalAmount = widget.price * 1.02;

      // 1. Create Payment Intent
      final createIntentCallable = FirebaseFunctions.instance.httpsCallable('createPaymentIntent');
      final intentResponse = await createIntentCallable.call({
        'amount': totalAmount,
        'currency': 'myr',
        'bookingId': widget.bookingId,
      });

      final clientSecret = intentResponse.data['clientSecret'];
      final customerId = intentResponse.data['customer'];
      final ephemeralKey = intentResponse.data['ephemeralKey'];
      
      if (clientSecret == null) {
        throw Exception('Failed to get client secret');
      }

      // 2. Initialize Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          customerId: customerId,
          customerEphemeralKeySecret: ephemeralKey,
          merchantDisplayName: 'myMove',
          style: ThemeMode.dark,
        ),
      );

      // 3. Present Payment Sheet
      await Stripe.instance.presentPaymentSheet();

      // 4. Assign Spot
      final callable = FirebaseFunctions.instance.httpsCallable('assignSpot');
      final response = await callable.call({
        'bookingId': widget.bookingId,
        'spotId': widget.spotId,
      });

      if (mounted) {
        if (response.data['success'] == true) {
          // Use pushAndRemoveUntil to clear the spot selection route
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => BookingSuccessScreen(
                bookingId: widget.bookingId,
                locationName: widget.locationName,
                spotId: widget.spotId,
                startDateTime: widget.startDateTime,
                endDateTime: widget.endDateTime,
                price: totalAmount,
              ),
            ),
            (route) => route.isFirst,
          );
        } else {
          setState(() {
            _isSaving = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.data['error'] ?? 'Booking confirmation failed'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } on StripeException catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        // e.error.localizedMessage gives a nice user-facing error or cancellation message
        final errorMsg = e.error.localizedMessage ?? 'Payment canceled or failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error confirming booking: ${e.toString().replaceAll('Exception: ', '')}'),
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
            width: 100,
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
    // Computations
    final diffMinutes = widget.endDateTime.difference(widget.startDateTime).inMinutes;
    final durationHours = diffMinutes > 0 ? (diffMinutes / 60).ceil() : 0;
    final isMultiDay = widget.startDateTime.day != widget.endDateTime.day;
    
    final dateFormat = DateFormat('d MMMM yyyy');
    final timeFormat = DateFormat('h.mm a');
    
    String dateStr = dateFormat.format(widget.startDateTime);
    if (isMultiDay) {
      dateStr = '$dateStr - ${dateFormat.format(widget.endDateTime)}';
    }

    String timeStr = '${timeFormat.format(widget.startDateTime).toLowerCase()} - ${timeFormat.format(widget.endDateTime).toLowerCase()}';
    String durationStr = durationHours >= 24 ? '${(durationHours / 24).ceil()} days' : '$durationHours hours';
    
    // Pricing
    double amount = widget.price;
    double taxes = amount * 0.02; // 2% tax
    double total = amount + taxes;

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
          'Checkout',
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
              // Details Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow('Parking Area', widget.locationName, isBold: true),
                    _buildSummaryRow('Address', widget.locationAddress, isBold: true),
                    _buildSummaryRow('Vehicle', '${widget.vehicleMake} (${widget.vehiclePlate})', isBold: true),
                    _buildSummaryRow('Parking Spot', widget.spotId, isBold: true),
                    _buildSummaryRow('Date', dateStr, isBold: true),
                    _buildSummaryRow('Duration', durationStr, isBold: true),
                    _buildSummaryRow('Hours', timeStr, isBold: true),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Payment Method Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.deepPurpleAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.security, color: Colors.deepPurpleAccent),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Secure Payment',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Powered by Stripe',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Pricing Card
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
              onPressed: _isSaving ? null : _confirmBooking,
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
                      'Pay & Confirm Booking',
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
