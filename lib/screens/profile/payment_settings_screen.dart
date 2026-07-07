import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../../config/routes.dart';

class PaymentSettingsScreen extends StatefulWidget {
  const PaymentSettingsScreen({super.key});

  @override
  State<PaymentSettingsScreen> createState() => _PaymentSettingsScreenState();
}

class _PaymentSettingsScreenState extends State<PaymentSettingsScreen> {
  bool _isLoading = false;
  bool _isLoadingCards = true;
  List<dynamic> _savedCards = [];

  @override
  void initState() {
    super.initState();
    _fetchSavedCards();
  }

  Future<void> _fetchSavedCards() async {
    setState(() {
      _isLoadingCards = true;
    });
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('getSavedPaymentMethods');
      final response = await callable.call();
      if (mounted) {
        setState(() {
          _savedCards = response.data['paymentMethods'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Error fetching saved cards: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCards = false;
        });
      }
    }
  }

  Future<void> _removePaymentMethod(String paymentMethodId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('deletePaymentMethod');
      await callable.call({'paymentMethodId': paymentMethodId});
      if (mounted) {
        Navigator.of(context).pop(); // dismiss loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Card removed successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchSavedCards();
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // dismiss loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing card: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _addPaymentMethod() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final callable = FirebaseFunctions.instance.httpsCallable('createSetupIntent');
      final response = await callable.call();

      final clientSecret = response.data['clientSecret'];
      final customerId = response.data['customer'];
      final ephemeralKey = response.data['ephemeralKey'];

      if (clientSecret == null) {
        throw Exception('Failed to get setup intent secret');
      }

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          setupIntentClientSecret: clientSecret,
          customerId: customerId,
          customerEphemeralKeySecret: ephemeralKey,
          merchantDisplayName: 'myMove',
          style: ThemeMode.dark,
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment method added successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchSavedCards();
      }
    } on StripeException catch (e) {
      if (mounted) {
        final errorMsg = e.error.localizedMessage ?? 'Action canceled or failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding payment method: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Payment',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: false,
        titleSpacing: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPaymentOption(
                icon: Icons.add_card_outlined,
                title: 'Add Payment Method',
                trailing: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : null,
                onTap: _isLoading ? () {} : _addPaymentMethod,
              ),
              const SizedBox(height: 24),
              const Text(
                'Saved Cards',
                style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              if (_isLoadingCards)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                )
              else if (_savedCards.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No saved cards', style: TextStyle(color: Colors.white54)),
                  ),
                )
              else
                ..._savedCards.map((card) => _buildSavedCardItem(card)),
              const SizedBox(height: 24),
              _buildPaymentOption(
                icon: Icons.history_rounded,
                title: 'Payment History',
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white54,
                  size: 20,
                ),
                onTap: () {
                  Navigator.of(context).pushNamed(AppRoutes.paymentHistory);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSavedCardItem(dynamic card) {
    final brand = card['brand']?.toString().toUpperCase() ?? 'CARD';
    final last4 = card['last4'] ?? '****';
    final expMonth = card['expMonth']?.toString().padLeft(2, '0') ?? '00';
    
    // Safely get the last 2 digits of the year
    String expYearStr = card['expYear']?.toString() ?? '00';
    if (expYearStr.length >= 2) {
      expYearStr = expYearStr.substring(expYearStr.length - 2);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.credit_card, color: Colors.white, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$brand ending in $last4',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  'Expires $expMonth/$expYearStr',
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => _removePaymentMethod(card['id']),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required IconData icon,
    required String title,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E), // Dark gray similar to image
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }
}
