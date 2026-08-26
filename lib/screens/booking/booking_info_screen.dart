import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'parking_timer_screen.dart';
import '../feedback_screen.dart';
class BookingInfoScreen extends StatefulWidget {
  final String bookingId;
  final String locationName;
  final String spotId;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final double price;
  final String effectiveStatus;
  final String locationAddress;
  final String vehicleMake;
  final String vehiclePlate;

  const BookingInfoScreen({
    super.key,
    required this.bookingId,
    required this.locationName,
    required this.spotId,
    required this.startDateTime,
    required this.endDateTime,
    required this.price,
    required this.effectiveStatus,
    required this.locationAddress,
    required this.vehicleMake,
    required this.vehiclePlate,
  });

  @override
  State<BookingInfoScreen> createState() => _BookingInfoScreenState();
}

class _BookingInfoScreenState extends State<BookingInfoScreen> {
  late DateTime _currentEndDateTime;
  late double _currentPrice;

  @override
  void initState() {
    super.initState();
    _currentEndDateTime = widget.endDateTime;
    _currentPrice = widget.price;
  }

  String _formatDateTime(DateTime dt) {
    return DateFormat('MMM d, yyyy • h:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final bookingId = widget.bookingId;
    final locationName = widget.locationName;
    final spotId = widget.spotId;
    final startDateTime = widget.startDateTime;
    final endDateTime = _currentEndDateTime;
    final price = _currentPrice;
    final effectiveStatus = widget.effectiveStatus;
    final locationAddress = widget.locationAddress;
    final vehicleMake = widget.vehicleMake;
    final vehiclePlate = widget.vehiclePlate;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'More Info about your\n$locationName',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 48),
                
                // Receipt Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: Column(
                    children: [
                      _buildReceiptRow('Booking ID', bookingId.substring(0, 8).toUpperCase()),
                      const Divider(color: Colors.white10, height: 32),
                      _buildReceiptRow('Location', locationName),
                      const SizedBox(height: 16),
                      _buildReceiptRow('Spot Number', spotId),
                      const SizedBox(height: 16),
                      _buildReceiptRow('Start', _formatDateTime(startDateTime)),
                      const SizedBox(height: 16),
                      _buildReceiptRow('End', _formatDateTime(endDateTime)),
                      const Divider(color: Colors.white10, height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Paid',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'RM ${price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 48),
                
                if (effectiveStatus == 'Ongoing') ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        // Reload from Firestore to ensure latest data
                        try {
                          final doc = await FirebaseFirestore.instance.collection('bookings').doc(bookingId).get();
                          if (doc.exists) {
                            final data = doc.data()!;
                            if (data['endDateTime'] != null) {
                              final latestEnd = DateTime.parse(data['endDateTime']).toLocal();
                              if (mounted) {
                                setState(() {
                                  _currentEndDateTime = latestEnd;
                                });
                              }
                            }
                          }
                        } catch (e) {
                          debugPrint('Error reloading booking: $e');
                        }

                        if (!mounted) return;

                        // Go to Parking Timer Screen
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ParkingTimerScreen(
                              bookingId: bookingId,
                              locationName: locationName,
                              locationAddress: locationAddress,
                              vehicleMake: vehicleMake,
                              vehiclePlate: vehiclePlate,
                              spotId: spotId,
                              startDateTime: startDateTime,
                              endDateTime: _currentEndDateTime, // Pass the possibly updated state
                            ),
                          ),
                        );
                        
                        if (result != null && result is DateTime) {
                          if (mounted) {
                            setState(() {
                              _currentEndDateTime = result;
                            });
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        backgroundColor: Colors.blueAccent, // Make this the primary button color now
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Parking Timer',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                if (effectiveStatus == 'Upcoming') ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: null, // Disabled
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        disabledBackgroundColor: Colors.white.withValues(alpha: 0.1),
                        disabledForegroundColor: Colors.white.withValues(alpha: 0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Extend Parking Time',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                if (effectiveStatus == 'Completed') ...[
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('feedback')
                        .where('bookingId', isEqualTo: bookingId)
                        .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                        .limit(1)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                        );
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: SizedBox(
                            height: 56,
                            child: Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
                          ),
                        );
                      }
                      
                      final hasFeedback = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
                      if (hasFeedback) {
                        return const SizedBox.shrink();
                      }

                      return Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FeedbackScreen(
                                      bookingId: bookingId,
                                      locationName: locationName,
                                      bookingDate: startDateTime,
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                backgroundColor: Colors.blueAccent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Leave Feedback',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    },
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 15,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
